import 'dart:async';

import 'package:alloy/src/errors/alloy_dispose_error.dart';
import 'package:alloy/src/errors/alloy_dispose_failure.dart';
import 'package:alloy/src/errors/alloy_dispose_stage.dart';
import 'package:alloy/src/errors/alloy_duplicate_registration_error.dart';
import 'package:alloy/src/errors/alloy_error.dart';
import 'package:alloy/src/errors/alloy_not_ready_error.dart';
import 'package:alloy/src/errors/alloy_param_type_error.dart';
import 'package:alloy/src/errors/alloy_not_registered_error.dart';
import 'package:alloy/src/errors/alloy_scope_state_error.dart';
import 'package:alloy/src/factory/alloy_async_factory.dart';
import 'package:alloy/src/factory/alloy_factory.dart';
import 'package:alloy/src/factory/alloy_param_factory.dart';
import 'package:alloy/src/graph/topological_sort.dart';
import 'package:alloy/src/key/alloy_key.dart';
import 'package:alloy/src/lifecycle/alloy_injectable.dart';
import 'package:alloy/src/lifecycle/alloy_resolver.dart';
import 'package:alloy/src/lifecycle/async_disposable.dart';
import 'package:alloy/src/lifecycle/disposable.dart';
import 'package:alloy/src/observer/alloy_observer.dart';
import 'package:alloy/src/observer/alloy_scope_ref.dart';
import 'package:alloy/src/registration/alloy_registration.dart';
import 'package:alloy/src/scope/alloy_registration_kind.dart';
import 'package:alloy/src/scope/alloy_scope_state.dart';
import 'package:alloy/src/scope/resolution_tracker.dart';

/// A container of registrations with a lifetime of its own.
///
/// Scopes form a tree. A child sees everything its ancestors registered and
/// can shadow any of it; resolution never walks downwards. Disposing a scope
/// disposes its children first, then its own instances in reverse creation
/// order, so nothing is torn down before what depends on it.
///
/// A parent holds its children strongly, which is what makes that ordering
/// guaranteed. The flip side is an explicit ownership contract: whoever
/// creates a scope closes it. A scope dropped without [dispose] leaks, by
/// design — the alternative is a teardown that may silently never run.
///
/// ```dart
/// final app = AlloyScope.root(name: 'app')
///   ..registerLazySingleton<Logger>(const LoggerFactory());
/// await app.init();
///
/// final session = app.push('session');
/// // ... use it ...
/// await session.dispose();
/// ```
final class AlloyScope implements AlloyResolver {
  AlloyScope._(this.name, this.parent, this._tracker, this._observers)
    : depth = parent == null ? 0 : parent.depth + 1;

  /// Creates a detached root scope.
  ///
  /// [name] appears in error messages and when inspecting the tree. The
  /// caller owns the result and must [dispose] it.
  ///
  /// [observers] watch this scope and every scope pushed from it.
  factory AlloyScope.root({
    String name = 'root',
    List<AlloyObserver> observers = const [],
  }) => AlloyScope._(
    name,
    null,
    AlloyResolutionTracker(),
    List.unmodifiable(observers),
  );

  /// This scope's name, used in diagnostics.
  final String name;

  /// The scope this one was pushed from, or `null` for a root.
  final AlloyScope? parent;

  /// How far below the root this scope sits. `0` for a root.
  final int depth;

  final _children = <AlloyScope>[];
  final _registrations = <AlloyKey, AlloyRegistration>{};
  final _owned = <_OwnedInstance>[];
  final AlloyResolutionTracker _tracker;
  final List<AlloyObserver> _observers;

  Future<void>? _initFuture;
  AlloyScopeState _state = AlloyScopeState.open;
  int _order = 0;

  /// Where this scope is in its lifecycle.
  AlloyScopeState get state => _state;

  /// The child scopes currently alive, in the order they were pushed.
  List<AlloyScope> get children => List.unmodifiable(_children);

  /// The outermost scope above this one, or this scope when it is the root.
  AlloyScope get root {
    var current = this;
    for (var parent = current.parent; parent != null; parent = current.parent) {
      current = parent;
    }
    return current;
  }

  /// What this scope registers, in registration order.
  ///
  /// This is what was *declared*, not what exists. A lazy singleton nobody
  /// resolved is indistinguishable here from one that is built, and an async
  /// singleton appears whether or not `init()` has reached it.
  ///
  /// Three more things it deliberately is not. Objects handed to [adopt] have
  /// no key at all, so this is not what teardown will release. One key can
  /// stand for any number of live transients, or none. And nothing records
  /// what a factory will ask for, so this is a list, never a graph.
  ///
  /// Empty after [dispose], which clears the registrations rather than keeping
  /// a tombstone.
  Set<AlloyKey> get keys => Set.unmodifiable(_registrations.keys);

  /// Every key resolvable from here, mapped to the scope that owns it.
  ///
  /// Nearest wins: a key this scope registers shadows the same key in an
  /// ancestor, exactly as [get] resolves it.
  ///
  /// The owner is the point of the map. A factory is called with the scope
  /// that owns *its* registration, not the scope you asked from, so a key
  /// alone cannot tell you what an override will actually affect.
  Map<AlloyKey, AlloyScope> get visibleKeys {
    final result = <AlloyKey, AlloyScope>{};
    for (AlloyScope? scope = this; scope != null; scope = scope.parent) {
      for (final key in scope._registrations.keys) {
        result.putIfAbsent(key, () => scope!);
      }
    }
    return Map.unmodifiable(result);
  }

  /// What kind of registration [key] has, or null when nothing registers it.
  ///
  /// Resolves through ancestors like [get] does, so it answers for the scope
  /// the key would actually come from.
  ///
  /// For tools. It exists because the alternative — telling a parameterized
  /// registration apart from a broken one by reading an exception message — is
  /// parsing prose.
  AlloyRegistrationKind? debugKindOf(AlloyKey key) =>
      switch (_lookup(key)?.registration) {
        SingletonRegistration() => AlloyRegistrationKind.singleton,
        LazySingletonRegistration() => AlloyRegistrationKind.lazySingleton,
        TransientRegistration() => AlloyRegistrationKind.transient,
        AsyncSingletonRegistration() => AlloyRegistrationKind.asyncSingleton,
        ParamRegistration() => AlloyRegistrationKind.parameterized,
        null => null,
      };

  /// Resolves [key] without naming its type, or null when nothing registers it.
  ///
  /// The typed [get] cannot be called from a loop over [keys]: Dart has no way
  /// to turn a `Type` back into a type argument. This is the same resolution,
  /// reached by value instead — which is what lets a tool walk a whole graph.
  ///
  /// Everything [get] throws, this throws: an async singleton before `init()`
  /// raises `AlloyNotReadyError`, a parameterized registration raises
  /// `AlloyError`, a cycle raises `AlloyCycleError`. Check [debugKindOf] first
  /// rather than reading those apart afterwards.
  Object? debugResolve(AlloyKey key) {
    _assertUsable();
    final found = _lookup(key);
    if (found == null) return null;
    return found.scope._materialize(found.registration);
  }

  /// Resolves a parameterized [key] with [param], without naming its types.
  ///
  /// The key-based twin of [getWithParam], for the same reason [debugResolve]
  /// is the twin of [get]: a walk over [keys] has no type arguments to give.
  ///
  /// Returns null when nothing registers [key]. Throws `AlloyError` when the
  /// registration is not parameterized, and `AlloyParamTypeError` when [param]
  /// is not what its factory takes.
  Object? debugResolveWithParam(AlloyKey key, Object param) {
    _assertUsable();
    final found = _lookup(key);
    if (found == null) return null;
    final registration = found.registration;
    if (registration is! ParamRegistration) {
      throw AlloyError('$key is not registered as a parameterized factory.');
    }
    if (!registration.accepts(param)) {
      throw AlloyParamTypeError(key, registration.paramType, param.runtimeType);
    }
    return found.scope._tracker.guard(key, () {
      final instance = registration.factory.create(found.scope, param);
      found.scope._afterCreate(
        instance,
        key,
        kind: AlloyRegistrationKind.parameterized,
        retain: false,
      );
      return instance;
    });
  }

  /// Renders this scope and everything under it, one line per scope.
  ///
  /// For diagnostics and test failures. The shape is not a contract.
  String debugDescribeTree() => _describe(0).join('\n');

  List<String> _describe(int indent) => [
    '${'  ' * indent}$name  [${_state.name}]  ${_registrations.length} '
        'registration(s)',
    for (final child in _children) ...child._describe(indent + 1),
  ];

  /// Whether the scope still accepts registrations and resolutions.
  ///
  /// False once teardown has begun, which is what turns later use into an
  /// `AlloyScopeStateError` instead of work against half-cleared state.
  bool get isUsable =>
      _state == AlloyScopeState.open ||
      _state == AlloyScopeState.initializing ||
      _state == AlloyScopeState.active;

  /// Creates a child scope that resolves through this one.
  ///
  /// The child is retained until it is disposed, either directly or as part of
  /// disposing this scope. Use it for anything with a shorter life than the
  /// parent — a session, a screen, a request — and to override a dependency
  /// without touching the parent.
  AlloyScope push(String childName) {
    _assertUsable();
    final child = AlloyScope._(childName, this, _tracker, _observers);
    _children.add(child);
    child._notify((observer) => observer.onScopePushed(child.ref));
    return child;
  }

  /// Registers [T] so every resolution builds a new instance.
  ///
  /// The scope does not retain what it builds, so transient instances are the
  /// caller's to dispose.
  void registerFactory<T extends Object>(
    AlloyFactory<T> factory, {
    String? name,
  }) {
    _put(
      TransientRegistration(
        key: AlloyKey(T, name: name),
        order: _order++,
        factory: factory,
      ),
    );
  }

  /// Registers an already-built [value] as the single instance of [T].
  ///
  /// The scope takes ownership immediately: if [value] is disposable it is
  /// torn down with the scope, in registration order relative to everything
  /// else it owns.
  ///
  /// [dispose] closes a [value] whose type implements neither [Disposable] nor
  /// [AsyncDisposable] — a client from another package, say. Without it such a
  /// value is registered but never closed, because the scope has no way to
  /// know how.
  void registerSingleton<T extends Object>(
    T value, {
    String? name,
    FutureOr<void> Function(T instance)? dispose,
  }) {
    _put(
      SingletonRegistration(
        key: AlloyKey(T, name: name),
        order: _order++,
        value: value,
      ),
    );
    _own(value, teardown: _teardownOf(dispose));
  }

  /// Registers [T] so the first resolution builds it and later ones reuse it.
  ///
  /// The instance is retained and disposed with the scope. Because it is built
  /// on demand, its position in the teardown order follows when it was
  /// *created*, not when it was registered.
  /// [dispose] closes an instance whose type implements neither [Disposable]
  /// nor [AsyncDisposable].
  void registerLazySingleton<T extends Object>(
    AlloyFactory<T> factory, {
    String? name,
    FutureOr<void> Function(T instance)? dispose,
  }) {
    _put(
      LazySingletonRegistration(
        key: AlloyKey(T, name: name),
        order: _order++,
        factory: factory,
        teardown: _teardownOf(dispose),
      ),
    );
  }

  /// Registers [T] as a single instance built during [init].
  ///
  /// [dependsOn] declares which other async registrations must finish first.
  /// The graph is sorted into levels: everything in a level runs through
  /// `Future.wait`, and the next level waits for it. A cycle throws
  /// `AlloyCycleError`.
  ///
  /// Resolving [T] before [init] completes throws `AlloyNotReadyError`.
  /// [dispose] closes an instance whose type implements neither [Disposable]
  /// nor [AsyncDisposable].
  void registerAsyncSingleton<T extends Object>(
    AlloyAsyncFactory<T> factory, {
    String? name,
    Set<AlloyKey> dependsOn = const {},
    FutureOr<void> Function(T instance)? dispose,
  }) {
    _put(
      AsyncSingletonRegistration(
        key: AlloyKey(T, name: name),
        order: _order++,
        factory: factory,
        dependsOn: dependsOn,
        teardown: _teardownOf(dispose),
      ),
    );
  }

  /// Registers [T] as a factory taking a runtime argument of type [P].
  ///
  /// Resolve it with [getWithParam]; a plain [get] throws, because the
  /// container has no value to pass.
  void registerParamFactory<T extends Object, P extends Object>(
    AlloyParamFactory<T, P> factory, {
    String? name,
  }) {
    _put(
      ParamRegistration(
        key: AlloyKey(T, name: name),
        order: _order++,
        factory: factory,
        paramType: P,
        accepts: (value) => value is P,
      ),
    );
  }

  @override
  bool isRegistered<T extends Object>({String? name}) =>
      _lookup(AlloyKey(T, name: name)) != null;

  @override
  T? getOrNull<T extends Object>({String? name}) {
    _assertUsable();
    final found = _lookup(AlloyKey(T, name: name));
    if (found == null) return null;
    return found.scope._materialize(found.registration) as T;
  }

  @override
  T get<T extends Object>({String? name}) {
    _assertUsable();
    final key = AlloyKey(T, name: name);
    final found = _lookup(key);
    if (found == null) {
      throw AlloyNotRegisteredError(key, this.name, resolving: _tracker.chain);
    }
    return found.scope._materialize(found.registration) as T;
  }

  @override
  T getWithParam<T extends Object, P extends Object>(P param, {String? name}) {
    _assertUsable();
    final key = AlloyKey(T, name: name);
    final found = _lookup(key);
    if (found == null) {
      throw AlloyNotRegisteredError(key, this.name, resolving: _tracker.chain);
    }
    final registration = found.registration;
    if (registration is! ParamRegistration) {
      throw AlloyError('$key is not registered as a parameterized factory.');
    }
    if (!registration.accepts(param)) {
      throw AlloyParamTypeError(key, registration.paramType, param.runtimeType);
    }
    return found.scope._tracker.guard(key, () {
      final instance = registration.factory.create(found.scope, param);
      found.scope._afterCreate(
        instance,
        key,
        kind: AlloyRegistrationKind.parameterized,
        retain: false,
      );
      return instance as T;
    });
  }

  @override
  List<T> getAll<T extends Object>() {
    _assertUsable();
    final seen = <AlloyKey>{};
    final result = <T>[];
    for (AlloyScope? scope = this; scope != null; scope = scope.parent) {
      final matching =
          scope._registrations.values.where((r) => r.key.type == T).toList()
            ..sort((a, b) => a.order.compareTo(b.order));
      for (final registration in matching) {
        if (!seen.add(registration.key)) continue;
        result.add(scope._materialize(registration) as T);
      }
    }
    return result;
  }

  /// Builds every async singleton registered in this scope.
  ///
  /// Safe to call more than once and from several places at once: the work
  /// runs exactly once and every caller awaits the same future. Returns
  /// immediately for a scope that is already active.
  ///
  /// If it throws, the scope stays usable enough to be disposed, and whatever
  /// was built before the failure is still torn down.
  Future<void> init() {
    final pending = _initFuture;
    if (pending != null) return pending;
    if (_state == AlloyScopeState.active) return Future<void>.value();
    _assertUsable();
    return _initFuture = _run();
  }

  Future<void> _run() async {
    _state = AlloyScopeState.initializing;

    final pending =
        _registrations.values.whereType<AsyncSingletonRegistration>().toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    if (pending.isNotEmpty) {
      final byKey = {for (final r in pending) r.key: r};
      final levels = layeredTopologicalSort<AsyncSingletonRegistration>(
        pending,
        (r) => [for (final dep in r.dependsOn) ?byKey[dep]],
        labelOf: (r) => r.key.toString(),
      );

      final building = Stopwatch()..start();
      _notify((observer) => observer.onScopeInitStarted(ref, levels.length));
      try {
        for (final level in levels) {
          await Future.wait([for (final r in level) _createAsync(r)]);
        }
      } catch (error, stackTrace) {
        _notify(
          (observer) => observer.onScopeInitFailed(ref, error, stackTrace),
        );
        rethrow;
      }
      _notify(
        (observer) => observer.onScopeInitCompleted(ref, building.elapsed),
      );
    }

    if (_state == AlloyScopeState.initializing) {
      _state = AlloyScopeState.active;
    }
  }

  /// Ties [instance]'s lifetime to this scope without registering it.
  ///
  /// The scope disposes it along with everything else it owns, in the same
  /// reverse-creation order, but nothing can resolve it — use this for objects
  /// that belong to the scope's lifetime yet are not dependencies. Bootstrap
  /// steps are the built-in case: they run before any container exists, so
  /// they cannot be registered, but whatever they opened still has to be
  /// closed.
  ///
  /// Objects that implement neither [Disposable] nor [AsyncDisposable] are
  /// returned unchanged and not retained, since there would be nothing to do
  /// with them at teardown — unless [dispose] says what to do, in which case
  /// they are retained and it is called.
  ///
  /// Returns [instance], so it can be adopted inline.
  T adopt<T extends Object>(
    T instance, {
    FutureOr<void> Function(T instance)? dispose,
  }) {
    _assertUsable();
    _own(instance, teardown: _teardownOf(dispose));
    return instance;
  }

  /// The budget [dispose] uses when the caller does not pass one.
  static const defaultDisposeTimeout = Duration(seconds: 30);

  /// Tears the scope down and detaches it from its parent.
  ///
  /// Children go first, in reverse push order, then this scope's own
  /// instances in reverse creation order. `AsyncDisposable.dispose` is
  /// awaited before moving on, so ordering holds even when teardown does I/O.
  ///
  /// Idempotent, and safe to call while [init] is still running — it waits for
  /// it, so nothing that init built escapes teardown. After this the scope is
  /// permanently unusable.
  ///
  /// Teardown is best-effort. A step that throws, or that runs past the
  /// deadline, is recorded and the remaining steps still run, so one broken
  /// object cannot strand everything registered after it. [timeout] is a
  /// deadline for the whole teardown rather than per step, so this returns
  /// within roughly that long however many objects are involved.
  ///
  /// The scope always reaches [AlloyScopeState.disposed]. If anything went
  /// wrong, [AlloyDisposeError] is thrown afterwards listing every failure.
  /// Timed-out steps were abandoned, not cancelled — Dart cannot cancel a
  /// future — which is why they are reported rather than ignored.
  ///
  /// An `init()` still running when this is called is waited for. If it
  /// *threw*, that is not a teardown failure and does not make this throw on
  /// its own — the error belongs to whoever called `init()` and was already
  /// delivered there. It is still recorded, tagged
  /// [AlloyDisposeStage.awaitingInit], so that when teardown does fail the
  /// report says the scope was only half-built. If instead the wait ran past
  /// the deadline, that is teardown failing to finish, and it is reported like
  /// any other overrun.
  Future<void> dispose({Duration timeout = defaultDisposeTimeout}) async {
    if (_state == AlloyScopeState.disposed ||
        _state == AlloyScopeState.disposing) {
      return;
    }

    final elapsed = Stopwatch()..start();
    final failures = <AlloyDisposeFailure>[];

    Duration remaining() => timeout - elapsed.elapsed;

    Future<void> within(
      String label,
      Future<void> Function() step, {
      AlloyDisposeStage stage = AlloyDisposeStage.releasing,
    }) async {
      final left = remaining();
      if (left <= Duration.zero) {
        failures.add(
          AlloyDisposeFailure(
            label,
            TimeoutException('the teardown deadline had already passed'),
            StackTrace.current,
            stage: stage,
          ),
        );
        return;
      }
      try {
        await step().timeout(left);
      } catch (error, stackTrace) {
        failures.add(
          AlloyDisposeFailure(label, error, stackTrace, stage: stage),
        );
      }
    }

    final pendingInit = _initFuture;
    if (pendingInit != null) {
      // Awaiting this future makes Alloy its error listener, which would
      // suppress the unhandled-error report Dart makes for an init() nobody
      // awaited. The failure is recorded instead of dropped, tagged so a
      // caller that already handled it can tell it apart from teardown.
      await within(
        'init',
        () => pendingInit,
        stage: AlloyDisposeStage.awaitingInit,
      );
      if (_state == AlloyScopeState.disposed ||
          _state == AlloyScopeState.disposing) {
        return;
      }
    }

    _state = AlloyScopeState.disposing;
    _notify((observer) => observer.onScopeDisposeStarted(ref));

    for (final child in _children.reversed.toList(growable: false)) {
      try {
        await child.dispose(timeout: remaining());
      } on AlloyDisposeError catch (error) {
        failures.addAll([
          for (final failure in error.failures)
            AlloyDisposeFailure(
              '${child.name}/${failure.label}',
              failure.error,
              failure.stackTrace,
            ),
        ]);
      } catch (error, stackTrace) {
        failures.add(
          AlloyDisposeFailure('${child.name}/dispose', error, stackTrace),
        );
      }
    }
    _children.clear();

    for (final owned in _owned.reversed.toList(growable: false)) {
      final instance = owned.instance;
      final label = '${instance.runtimeType}.dispose';

      final teardown = owned.teardown;
      if (teardown != null) {
        final before = failures.length;
        await within(label, () async => teardown(instance));
        if (failures.length == before) {
          _notify(
            (observer) =>
                observer.onInstanceDisposed(ref, '${instance.runtimeType}'),
          );
        }
        continue;
      }

      switch (instance) {
        case AsyncDisposable():
          final before = failures.length;
          await within(label, instance.dispose);
          if (failures.length == before) {
            _notify(
              (observer) =>
                  observer.onInstanceDisposed(ref, '${instance.runtimeType}'),
            );
          }
        case Disposable():
          try {
            instance.dispose();
            _notify(
              (observer) =>
                  observer.onInstanceDisposed(ref, '${instance.runtimeType}'),
            );
          } catch (error, stackTrace) {
            failures.add(AlloyDisposeFailure(label, error, stackTrace));
          }
      }
    }

    _owned.clear();
    _registrations.clear();
    _initFuture = null;
    parent?._children.remove(this);
    _state = AlloyScopeState.disposed;

    // An init that threw belongs to whoever called init(); an init that ran
    // past the deadline is teardown failing to finish its own wait.
    _notify(
      (observer) => observer.onScopeDisposed(
        ref,
        elapsed.elapsed,
        List.unmodifiable(failures),
      ),
    );

    final couldNotRelease = failures.any(
      (failure) => !failure.isInitFailure || failure.isTimeout,
    );
    if (couldNotRelease) {
      throw AlloyDisposeError(name, failures);
    }
  }

  void _put(AlloyRegistration registration) {
    _assertUsable();
    if (_registrations.containsKey(registration.key)) {
      throw AlloyDuplicateRegistrationError(registration.key, name);
    }
    _registrations[registration.key] = registration;
  }

  ({AlloyScope scope, AlloyRegistration registration})? _lookup(AlloyKey key) {
    for (AlloyScope? scope = this; scope != null; scope = scope.parent) {
      final registration = scope._registrations[key];
      if (registration != null) {
        return (scope: scope, registration: registration);
      }
    }
    return null;
  }

  Object _materialize(AlloyRegistration registration) {
    switch (registration) {
      case SingletonRegistration():
        return registration.value;

      case TransientRegistration():
        return _tracker.guard(registration.key, () {
          final instance = registration.factory.create(this);
          _afterCreate(
            instance,
            registration.key,
            kind: AlloyRegistrationKind.transient,
            retain: false,
          );
          return instance;
        });

      case LazySingletonRegistration():
        final existing = registration.instance;
        if (existing != null) return existing;
        return _tracker.guard(registration.key, () {
          final instance = registration.factory.create(this);
          registration.instance = instance;
          _afterCreate(
            instance,
            registration.key,
            kind: AlloyRegistrationKind.lazySingleton,
            retain: true,
            teardown: registration.teardown,
          );
          return instance;
        });

      case AsyncSingletonRegistration():
        final existing = registration.instance;
        if (existing == null || !registration.isReady) {
          throw AlloyNotReadyError(registration.key, resolving: _tracker.chain);
        }
        return existing;

      case ParamRegistration():
        throw AlloyError(
          '${registration.key} requires a parameter; use getWithParam.',
        );
    }
  }

  Future<void> _createAsync(AsyncSingletonRegistration registration) =>
      _tracker.guardAsync(registration.key, () async {
        final instance = await registration.factory.create(this);
        registration.instance = instance;
        registration.isReady = true;
        _afterCreate(
          instance,
          registration.key,
          kind: AlloyRegistrationKind.asyncSingleton,
          retain: true,
          teardown: registration.teardown,
        );
      });

  void _afterCreate(
    Object instance,
    AlloyKey key, {
    required AlloyRegistrationKind kind,
    required bool retain,
    AlloyTeardown? teardown,
  }) {
    if (instance is AlloyInjectable) instance.onInject(this);
    if (retain) _own(instance, teardown: teardown);
    _notify(
      (observer) =>
          observer.onInstanceCreated(ref, key, kind: kind, retained: retain),
    );
  }

  /// Erases the caller's typed callback down to what a registration can hold.
  ///
  /// The cast is safe: the callback only ever reaches the instance registered
  /// under its own `T`.
  static AlloyTeardown? _teardownOf<T extends Object>(
    FutureOr<void> Function(T instance)? dispose,
  ) => dispose == null ? null : (instance) => dispose(instance as T);

  void _own(Object instance, {AlloyTeardown? teardown}) {
    if (teardown != null ||
        instance is Disposable ||
        instance is AsyncDisposable) {
      _owned.add(_OwnedInstance(instance, teardown));
    }
  }

  /// How this scope is described to an [AlloyObserver].
  AlloyScopeRef get ref =>
      AlloyScopeRef(name: name, depth: depth, parentName: parent?.name);

  /// Runs [event] on every observer, swallowing anything it throws.
  ///
  /// Watching must not be able to break the graph being watched, and there is
  /// nowhere to report an observer's own failure to — reporting is the thing
  /// that just failed.
  void _notify(void Function(AlloyObserver observer) event) {
    if (_observers.isEmpty) return;
    for (final observer in _observers) {
      try {
        event(observer);
      } catch (_) {
        // Deliberately ignored; see above.
      }
    }
  }

  void _assertUsable() {
    if (!isUsable) {
      throw AlloyScopeStateError(
        'Scope "$name" is $_state and cannot be used.',
      );
    }
  }

  @override
  String toString() => 'AlloyScope($name, $_state)';
}

/// An instance the scope owns, with whatever closes it.
///
/// [teardown] is null for the common case, where the instance says how to
/// close itself by implementing [Disposable] or [AsyncDisposable].
class _OwnedInstance {
  _OwnedInstance(this.instance, this.teardown);

  final Object instance;
  final AlloyTeardown? teardown;
}
