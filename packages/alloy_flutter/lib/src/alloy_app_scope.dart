import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:alloy/alloy.dart';
import 'package:alloy_flutter/src/alloy_app_scope_controller.dart';
import 'package:alloy_flutter/src/alloy_scope_provider.dart';
import 'package:flutter/widgets.dart';

/// Owns the root scope for as long as the app is mounted.
///
/// Declares the graph the same way [AlloyApplication.start] takes it, builds
/// it, publishes it, and disposes it on unmount. The counterpart to
/// [AlloyScopeWidget], which owns a *child* scope; this one has no ancestor to
/// push from, so it starts the graph itself.
///
/// The usual place for it is [MaterialApp.builder], through
/// [AlloyAppScope.builder] — there [loading] and [errorBuilder] are rendered
/// with the app's theme and directionality, so they can be an ordinary screen
/// rather than a second app:
///
/// ```dart
/// void main() => runApp(
///   MaterialApp(
///     theme: ThemeData(colorSchemeSeed: Colors.indigo),
///     builder: AlloyAppScope.builder(
///       root: const AppScope(),
///       loading: const Scaffold(body: Center(child: CircularProgressIndicator())),
///     ),
///     home: const HomeScreen(),
///   ),
/// );
/// ```
///
/// Awaiting the graph inside `runApp` rather than before it buys two things:
/// a startup failure becomes a screen with a retry instead of an app that dies
/// without a frame, and `WidgetsFlutterBinding` is already initialized when
/// `@AlloyBootstrap` steps run.
///
/// `AlloyAppScope.of(context).restart()` tears the graph down and builds a new
/// one — the same call that retries a failed start.
class AlloyAppScope extends StatefulWidget {
  /// Creates the owner of an app's root scope from the graph's parts.
  ///
  /// In Code-Gen Mode these are the generated `$AlloyRootScope`,
  /// `$alloyBootstrap` and `$alloyRootScopeName`.
  const AlloyAppScope({
    required AlloyScopeBuilder this.root,
    required this.child,
    this.bootstrap,
    this.rootName = 'root',
    this.observers = const [],
    this.loading,
    this.errorBuilder,
    this.disposeOnExitRequest = false,
    super.key,
  }) : start = null;

  /// Creates the owner from a function that returns a started scope.
  ///
  /// The escape hatch for a graph the declarative form cannot express — one
  /// assembled conditionally, or handed over by something else entirely. Use
  /// the default constructor when it fits, because it is the one that keeps
  /// [bootstrap] honest across restarts.
  const AlloyAppScope.start({
    required Future<AlloyScope> Function() this.start,
    required this.child,
    this.loading,
    this.errorBuilder,
    this.disposeOnExitRequest = false,
    super.key,
  }) : root = null,
       bootstrap = null,
       rootName = 'root',
       observers = const [];

  /// Declares what the root scope contains. Null only for [AlloyAppScope.start].
  final AlloyScopeBuilder? root;

  /// Produces the phase-0 steps, called once per start.
  ///
  /// A function and not a list, deliberately. Bootstrap steps are instances
  /// that hold resources — a stored list would hand a restart the same objects
  /// it just released. An [AlloyScopeBuilder] carries no such risk, which is
  /// why [root] *is* a value: it only registers, and the generated one is
  /// `const`.
  ///
  /// In Code-Gen Mode this is `() => $alloyBootstrap` — or
  /// `() => $alloyBootstrap(environment)` once environments are in play.
  final List<AlloyBootstrapStep> Function()? bootstrap;

  /// Names the root scope in diagnostics. `$alloyRootScopeName` when generated.
  final String rootName;

  /// Observers for the whole tree; child scopes inherit them.
  final List<AlloyObserver> observers;

  /// Builds the root scope. Null unless built with [AlloyAppScope.start].
  final Future<AlloyScope> Function()? start;

  /// Shown once the graph is ready, below an [AlloyScopeProvider].
  final Widget child;

  /// Shown while the graph starts, and again while a restart is in flight.
  final Widget? loading;

  /// Shown when the start throws. `retry` runs it again.
  ///
  /// Without it the error is rethrown during build, surfacing through the
  /// usual Flutter error handling — the same rule [AlloyScopeWidget] follows.
  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
  errorBuilder;

  /// Whether to dispose the graph when the OS asks the app to quit.
  ///
  /// Off by default, and deliberately. The hook behind it,
  /// `AppLifecycleListener.onExitRequested`, fires only where an exit is
  /// cancelable — currently macOS and Linux — and Flutter's own documentation
  /// is blunt about the rest: "Do not rely on this function as a place to save
  /// critical data, because you will be disappointed." On iOS and Android the
  /// process can be killed with no notification at all.
  ///
  /// So this is a desktop nicety, not a guarantee, and turning it on delays
  /// quitting by however long teardown takes — up to
  /// [AlloyScope.defaultDisposeTimeout].
  ///
  /// One sharp edge: Flutter asks *every* observer before quitting and does
  /// not stop at the first refusal. If another observer cancels the exit after
  /// this one has already disposed, the app keeps running with no graph and
  /// shows [loading] until something calls
  /// [AlloyAppScopeController.restart].
  final bool disposeOnExitRequest;

  /// An [AlloyAppScope] shaped for [MaterialApp.builder] and its siblings.
  ///
  /// Putting the scope there instead of above the app is what lets [loading]
  /// and [errorBuilder] be ordinary screens: everything `builder` returns sits
  /// below `Theme`, `Directionality`, `MediaQuery` and `Localizations`, and
  /// the `child` it receives is the navigator, so routes still resolve from
  /// the scope.
  ///
  /// ```dart
  /// MaterialApp(
  ///   builder: AlloyAppScope.builder(root: const AppScope()),
  ///   home: const HomeScreen(),
  /// )
  /// ```
  ///
  /// An app that already uses `builder` composes the two by hand rather than
  /// reaching for this — merging two builders is the app's decision, not the
  /// framework's:
  ///
  /// ```dart
  /// builder: (context, child) => AlloyAppScope(
  ///   root: const AppScope(),
  ///   child: MyOwnWrapper(child: child!),
  /// ),
  /// ```
  static TransitionBuilder builder({
    required AlloyScopeBuilder root,
    List<AlloyBootstrapStep> Function()? bootstrap,
    String rootName = 'root',
    List<AlloyObserver> observers = const [],
    Widget? loading,
    Widget Function(BuildContext context, Object error, VoidCallback retry)?
    errorBuilder,
    bool disposeOnExitRequest = false,
  }) => (BuildContext context, Widget? child) {
    assert(
      child != null,
      'AlloyAppScope.builder needs the app to have routing: it publishes the '
      'scope above the navigator that builder receives. Give the app a home, '
      'routes or a routerConfig, or place AlloyAppScope yourself.',
    );
    return AlloyAppScope(
      root: root,
      bootstrap: bootstrap,
      rootName: rootName,
      observers: observers,
      loading: loading,
      errorBuilder: errorBuilder,
      disposeOnExitRequest: disposeOnExitRequest,
      child: child!,
    );
  };

  /// The controller of the nearest [AlloyAppScope] above [context].
  static AlloyAppScopeController of(BuildContext context) {
    final controller = context
        .dependOnInheritedWidgetOfExactType<_AlloyAppScopeMarker>()
        ?.controller;
    if (controller == null) {
      throw AlloyError(
        'No AlloyAppScope found above this widget. '
        'Wrap your app in AlloyAppScope to restart its root scope.',
      );
    }
    return controller;
  }

  /// Starts the graph, however this instance was told to describe it.
  Future<AlloyScope> _build() {
    final start = this.start;
    if (start != null) return start();
    return AlloyApplication.start(
      root: root!,
      bootstrap: bootstrap?.call() ?? const [],
      rootName: rootName,
      observers: observers,
    );
  }

  @override
  State<AlloyAppScope> createState() => _AlloyAppScopeState();
}

class _AlloyAppScopeState extends State<AlloyAppScope>
    implements AlloyAppScopeController {
  AlloyScope? _scope;
  Object? _error;
  AppLifecycleListener? _lifecycle;

  /// Bumped by every start and by teardown, so a slow attempt that lost its
  /// race can tell and release what it built instead of publishing it.
  var _attempt = 0;

  @override
  void initState() {
    super.initState();
    if (widget.disposeOnExitRequest) {
      _lifecycle = AppLifecycleListener(onExitRequested: _onExitRequested);
    }
    unawaited(_start());
  }

  Future<void> _start() async {
    final attempt = ++_attempt;
    try {
      final scope = await widget._build();
      if (!mounted || attempt != _attempt) {
        await _release(scope, 'a root scope whose AlloyAppScope moved on');
        return;
      }
      setState(() {
        _scope = scope;
        _error = null;
      });
    } catch (error, stackTrace) {
      if (!mounted || attempt != _attempt) {
        _report(
          error,
          stackTrace,
          'starting a root scope, after it was no '
          'longer wanted',
        );
        return;
      }
      setState(() => _error = error);
    }
  }

  @override
  Future<void> restart() async {
    if (!mounted) return;
    final scope = _scope;
    setState(() {
      _scope = null;
      _error = null;
    });
    _attempt++;
    if (scope != null) {
      await _release(scope, 'the root scope owned by AlloyAppScope');
    }
    await _start();
  }

  Future<AppExitResponse> _onExitRequested() async {
    final scope = _scope;
    if (scope == null) return AppExitResponse.exit;
    _attempt++;
    if (mounted) {
      setState(() => _scope = null);
    } else {
      _scope = null;
    }
    await _release(scope, 'the root scope owned by AlloyAppScope, on exit');
    return AppExitResponse.exit;
  }

  @override
  void dispose() {
    _attempt++;
    _lifecycle?.dispose();
    _lifecycle = null;
    final scope = _scope;
    _scope = null;
    if (scope != null) {
      unawaited(_release(scope, 'the root scope owned by AlloyAppScope'));
    }
    super.dispose();
  }

  Future<void> _release(AlloyScope scope, String what) async {
    try {
      await scope.dispose();
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'disposing $what');
    }
  }

  void _report(Object error, StackTrace stackTrace, String what) =>
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'alloy_flutter',
          context: ErrorDescription(what),
        ),
      );

  @override
  Widget build(BuildContext context) =>
      _AlloyAppScopeMarker(controller: this, child: _content(context));

  Widget _content(BuildContext context) {
    final error = _error;
    if (error != null) {
      final errorBuilder = widget.errorBuilder;
      if (errorBuilder != null) {
        return errorBuilder(context, error, () => unawaited(restart()));
      }
      throw error;
    }

    final scope = _scope;
    if (scope == null) return widget.loading ?? const SizedBox.shrink();

    // Keyed by the scope: a child scope cannot be reparented, so a restart has
    // to rebuild the subtree rather than hand it a new root underneath.
    return AlloyScopeProvider(
      key: ValueKey(scope),
      scope: scope,
      child: widget.child,
    );
  }
}

class _AlloyAppScopeMarker extends InheritedWidget {
  const _AlloyAppScopeMarker({required this.controller, required super.child});

  final AlloyAppScopeController controller;

  @override
  bool updateShouldNotify(_AlloyAppScopeMarker oldWidget) => false;
}
