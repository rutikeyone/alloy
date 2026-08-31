[English](GUIDE.md) · [Русский](GUIDE.ru.md) · [中文](GUIDE.zh-CN.md)

# Alloy in practice

Everything here is a working shape, taken from the packages under `examples/` rather than written
for the page. [README.md](README.md) says what Alloy is and why it is built this way; this document
is how you use it, in the order you meet each piece.

Coming from `get_it` or `injectable`? Read [MIGRATION.md](MIGRATION.md) first — it maps the API you
already know onto this one, and, more usefully, says what does not map.

---

## Contents

1. [Install](#1-install)
2. [A graph you write by hand](#2-a-graph-you-write-by-hand)
3. [The same graph, generated](#3-the-same-graph-generated)
4. [Starting a Flutter app](#4-starting-a-flutter-app)
5. [Reading from the graph in a widget](#5-reading-from-the-graph-in-a-widget)
6. [Scopes that end before the app does](#6-scopes-that-end-before-the-app-does)
7. [Closing what you registered](#7-closing-what-you-registered)
8. [Work that has to finish before the app starts](#8-work-that-has-to-finish-before-the-app-starts)
9. [Values that come from the call site](#9-values-that-come-from-the-call-site)
10. [Types you did not write](#10-types-you-did-not-write)
11. [One graph, several builds](#11-one-graph-several-builds)
12. [Watching the graph](#12-watching-the-graph)
13. [Tests](#13-tests)
14. [The lint plugin](#14-the-lint-plugin)
15. [Mistakes worth knowing about in advance](#15-mistakes-worth-knowing-about-in-advance)

---

## 1. Install

Add only what you use. The runtime is pure Dart; nothing below it pulls in Flutter.

| You want | Add |
|---|---|
| the container, by hand, in any Dart program | `alloy` |
| widgets, `context.alloy<T>()`, an app-owned root | `alloy_flutter` |
| annotations and a generated container | `alloy_generator` (dev), `build_runner` (dev) |
| rules in the editor | `alloy_lint` (dev) |
| test helpers | `alloy_test` (dev), `alloy_test_flutter` (dev, widget tests) |
| a scope per navigation flow | `alloy_go_router` |
| blocs the scope can close | `alloy_bloc` |
| the graph on screen while the app runs | `alloy_inspector` (dev) |

A Flutter app with code generation:

```yaml
environment:
  sdk: ^3.13.0
  flutter: ">=3.47.0"

dependencies:
  alloy: ^0.1.0
  alloy_flutter: ^0.1.0

dev_dependencies:
  alloy_generator: ^0.1.0
  build_runner: ^2.15.0
  alloy_lint: ^0.1.0
  alloy_test: ^0.1.0
  alloy_test_flutter: ^0.1.0
```

A pure-Dart program — a CLI, a server, a package with no widgets — needs one line:

```yaml
dependencies:
  alloy: ^0.1.0
```

`alloy_flutter` re-exports the whole runtime, so an app never imports both.

---

## 2. A graph you write by hand

Start here even if you intend to generate. The generator writes exactly this, using nothing that is
not public API, so knowing what the output looks like is knowing the framework.

A registration is an object, not a closure. That is what lets a factory be `const`, hold no captured
state, and be shared between every start of the graph.

```dart
import 'package:alloy/alloy.dart';

class Clock {
  DateTime now() => DateTime.now();
}

class EventLog implements Disposable {
  final entries = <String>[];

  void add(String entry) => entries.add(entry);

  @override
  void dispose() => entries.clear();
}

class ClockFactory implements AlloyFactory<Clock> {
  const ClockFactory();

  @override
  Clock create(AlloyResolver resolver) => Clock();
}

class EventLogFactory implements AlloyFactory<EventLog> {
  const EventLogFactory();

  @override
  EventLog create(AlloyResolver resolver) => EventLog();
}
```

A **scope builder** says what a scope holds. It only registers; it never resolves.

```dart
class AppScope implements AlloyScopeBuilder {
  const AppScope();

  @override
  void build(AlloyScope scope) {
    scope
      ..registerLazySingleton<Clock>(const ClockFactory())
      ..registerLazySingleton<EventLog>(const EventLogFactory());
  }
}

Future<void> main() async {
  final app = await AlloyApplication.start(root: const AppScope(), rootName: 'app');

  app.get<EventLog>().add('started at ${app.get<Clock>().now()}');

  await app.dispose();
}
```

### The five ways to register

| Call | Built | Held by the scope |
|---|---|---|
| `registerSingleton<T>(value)` | already, by you | yes |
| `registerLazySingleton<T>(factory)` | on first resolve | yes |
| `registerAsyncSingleton<T>(factory)` | during `init()`, in dependency order | yes |
| `registerFactory<T>(factory)` | on every resolve | no |
| `registerParamFactory<T, P>(factory)` | on every resolve, from an argument | no |

"Held" is the whole distinction: a scope releases what it holds when it is disposed, and a transient
is nobody's to release — see [§7](#7-closing-what-you-registered).

### The five ways to read

```dart
scope.get<Repository>();                       // throws when nothing is registered
scope.getOrNull<Telemetry>();                  // null instead — see §9 for when this is right
scope.get<Logger>(name: 'audit');              // a @Named registration
scope.getAll<NoteFormatter>();                 // every registration of the type, nearest scope first
scope.getWithParam<Counter, String>('alice');  // a parameterized one
```

`isRegistered<T>()` answers without building anything, which is what a screen needs when a
registration is environment-specific and may legitimately be absent.

---

## 3. The same graph, generated

Annotate the classes and let the generator write the builder.

```dart
import 'package:alloy/alloy.dart';

@alloyInject
class Config {
  Config();

  final String environment = 'test';
}

@alloyInject
class Repository {
  Repository(this.config);

  final Config config;
}

@alloyInject
class Telemetry implements Disposable {
  final events = <String>[];

  void record(String event) => events.add(event);

  @override
  void dispose() => events.clear();
}
```

`@alloyInject` is a lazy singleton. `@alloySingleton` and `@alloyTransient` pick the other lifetimes,
and the long form takes the rest:

```dart
@AlloyInject(exposeAs: ApiClient, name: 'live', dispose: closeClient)
class LiveApiClient implements ApiClient { ... }
```

Name the root once, anywhere in the package:

```dart
@AlloyScopeRoot(name: 'app')
class AppScope {
  const AppScope();
}
```

Then generate:

```bash
dart run build_runner build
```

Out comes `lib/alloy.g.dart` with private const factories, a `$AlloyRootScope` whose registrations
are ordered by a compile-time topological sort, and a `$startAlloy()` that ties it to the bootstrap
list and the root name:

```dart
final scope = await $startAlloy();
```

Commit the generated file. CI regenerates and fails on a diff, which is how stale output is caught.

### Property injection, for constructors that got long

A class with five collaborators does not need five constructor parameters. Declare the fields and
mix in what the generator writes beside them:

```dart
part 'counter_bloc.g.dart';

@alloyTransient
class CounterBloc with _$CounterBloc {
  CounterBloc();

  @injected
  late final Repository _repository;

  @injected
  late final Telemetry _telemetry;

  void increment() => _telemetry.record('${_repository.hashCode}');
}
```

The fields are `late final`, so they are write-once — assigning twice throws `LateError` — and they
may be private, because the generated mixin is a `part` of the same library. Injected fields are
dependency edges like any other, so the bloc is always registered after what it injects.

### Composing on top of the generated root

The generator only sees its own package's annotations. Anything else — a value from
`--dart-define`, an object that needs the scope itself — goes in a builder that wraps the generated
one, so it lands *inside* phase 1 rather than being bolted on after startup:

```dart
class NotesScope implements AlloyScopeBuilder {
  const NotesScope(this.environment);

  final AlloyEnvironment environment;

  @override
  void build(AlloyScope scope) {
    $AlloyRootScope(environment: environment).build(scope);
    scope
      ..registerSingleton<AlloyEnvironment>(environment)
      ..registerSingleton<SessionManager>(SessionManager(scope));
  }
}
```

Tell the completeness check about them, or it will report them as missing:

```dart
@AlloyScopeRoot(name: 'app', provides: [SessionManager, AlloyEnvironment])
class AppScope {
  const AppScope();
}
```

A promise registers nothing; it only says something else will. `AlloyProvided(Logger, name: 'audit')`
promises a named one.

---

## 4. Starting a Flutter app

`AlloyAppScope` owns the root: it builds the graph, publishes it to the tree, disposes it on
unmount, and turns a failed start into a screen with a retry rather than an app that dies before its
first frame.

Put it in `MaterialApp.builder`, not above `MaterialApp`. There it sits below `Theme`,
`Directionality` and `Localizations`, so `loading` and `errorBuilder` are ordinary screens instead
of a second `MaterialApp`:

```dart
void main() => runApp(
  MaterialApp(
    theme: appTheme,
    builder: AlloyAppScope.builder(
      root: const NotesScope(notesEnvironment),
      bootstrap: () => $alloyBootstrap(notesEnvironment),
      rootName: $alloyRootScopeName,
      loading: const Scaffold(body: Center(child: CircularProgressIndicator())),
      errorBuilder: (context, error, retry) => StartupFailed(error: error, retry: retry),
    ),
    home: const HomeScreen(),
  ),
);
```

`bootstrap` is a function rather than a list on purpose: steps hold resources, and a restart has to
get new ones. A stored list would quietly hand the same objects to the second start.

`AlloyAppScope.of(context).restart()` rebuilds the graph — the same call retries a failed start.

If your app already has a `builder`, compose them yourself rather than expecting the framework to
merge two:

```dart
builder: (context, child) => AlloyAppScope(
  root: const NotesScope(notesEnvironment),
  child: myWrapper(child!),
),
```

---

## 5. Reading from the graph in a widget

```dart
final repository = context.alloy<Repository>();
final formatters = context.alloyAll<NoteFormatter>();
final editor = context.alloyWithParam<NoteEditor, $NoteEditorArgs>((id: 7, draft: true));
final scope = context.alloyScope;
```

Each resolves from the **nearest** scope above the widget and walks up from there, so a registration
in a flow or session scope shadows the root one for everything inside it.

One thing to know before it bites: `Navigator.push` builds the new route from the navigator's
context, not from the widget that pushed it. A screen that resolves fine when mounted in place will
throw `AlloyNoScopeError` when the same widget is pushed, if the provider it was reading lives
*inside* the pushing screen. Pass the scope explicitly in that case, or push below the provider.

---

## 6. Scopes that end before the app does

This is what the framework is for. A scope is a node in a tree, it owns what it builds, and
disposing it takes everything below it with it.

### A session

```dart
class SessionManager {
  SessionManager(this._root);

  final AlloyScope _root;
  AlloyScope? _session;

  Future<void> signIn(User user) async {
    _session = _root.push('session:${user.id}')
      ..registerLazySingleton<Draft>(const DraftFactory());
    await _session!.init();
  }

  Future<void> signOut() async {
    await _session?.dispose();
    _session = null;
  }
}
```

Logout is `await scope.dispose()`. No repository subscribes to a session stream, and no domain
interface grows a `reset()` method it did not want.

### A screen

```dart
AlloyScopeWidget(
  name: 'counter-screen',
  builder: const ScreenScope(),
  child: const Counter(),
)
```

Created when the widget mounts, disposed when it unmounts. Note that the scope is published only
after `init()` completes, so even a fully synchronous graph renders one `loading` frame.

### A navigation flow

`alloy_go_router` makes the lifetime a flow rather than a widget you remembered to place:

```dart
class OrderFlowRoute extends AlloyShellRoute {
  OrderFlowRoute()
    : super(
        name: 'order',
        identity: _orderId,
        scope: (state) => OrderFlowScope(_orderId(state)),
        shell: (_, _, child) => OrderFlowChrome(child: child),
        routes: [
          GoRoute(
            path: '/orders/:orderId/summary',
            builder: (_, state) => OrderSummaryScreen(orderId: _orderId(state)),
          ),
          GoRoute(
            path: '/orders/:orderId/payment',
            builder: (_, state) => OrderPaymentScreen(orderId: _orderId(state)),
          ),
        ],
      );

  static String _orderId(GoRouterState state) => state.pathParameters['orderId']!;
}
```

Navigating between `summary` and `payment` keeps one scope. Leaving the flow disposes it. `identity`
answers the one question the router cannot: whether `/orders/1` and `/orders/2` are the same flow —
change the identity and the scope is rebuilt.

Build the route table **once**, alongside the router. A new `AlloyShellRoute` instance is a different
flow as far as go_router is concerned, so rebuilding the list every frame would rebuild the scope
every frame.

Tabs work the same way with `AlloyStatefulShellRoute` and `AlloyStatefulShellBranch`, with one
behaviour worth stating plainly: a branch is kept **alive**, not kept **visible**. go_router
preserves branch navigators off-screen, so a tab's scope lives until the shell closes, not until you
switch away.

---

## 7. Closing what you registered

A scope releases what it holds, in reverse **creation** order — not declaration order, which is the
bug hand-written containers have. Three routes in, and Dart has no structural typing, so a matching
`dispose()` method is not enough on its own:

```dart
class Cache implements Disposable {
  @override
  void dispose() { ... }
}

class Database implements AsyncDisposable {
  @override
  Future<void> dispose() async { ... }
}
```

For a type you cannot change — from the SDK, from another package, behind a base class — name the
teardown at the registration:

```dart
Future<void> closeEvents(StreamController<String> events) => events.close();

@alloyModule
class PlatformModule {
  const PlatformModule();

  @AlloyInject(dispose: closeEvents)
  StreamController<String> events() => StreamController<String>.broadcast();
}
```

By hand it is the same argument:

```dart
scope.registerLazySingleton<http.Client>(
  const ClientFactory(),
  dispose: (client) => client.close(),
);
```

`dispose:` exists only on registrations the scope holds. `registerFactory` and `registerParamFactory`
do not take it, because a transient is not the scope's to close — the case is unrepresentable rather
than checked at runtime.

### Flutter types that look closable and are not

`ChangeNotifier.dispose` matches `Disposable.dispose` exactly, and is still invisible to the scope.
Say so:

```dart
class Filters extends ChangeNotifier implements Disposable {}
```

For blocs, `alloy_bloc` is the one line:

```dart
@alloyInject
class CounterCubit extends Cubit<int> with AlloyBloc {
  CounterCubit() : super(0);
}
```

or, where a mixin will not reach, `@AlloyInject(dispose: closeBloc)`.

Then hand it to the widget tree with `BlocProvider.value`, never `BlocProvider(create:)` — the
latter closes what it was given when it unmounts, while the scope still holds it and will hand out
the dead object on the next resolve.

### When teardown goes wrong

It is best-effort by design. A step that throws is recorded and the rest still run; the whole tree
has one deadline; and the scope always reaches `disposed`. What did not finish is listed in
`AlloyDisposeError` — `failures`, `timeouts`, `hasTimeout` — instead of the first failure hiding the
other nine.

`adopt` ties an object to a scope's life without it being a dependency:

```dart
scope.adopt(subscription, dispose: (it) => it.cancel());
```

---

## 8. Work that has to finish before the app starts

Two phases, and they answer different questions.

**Phase 0 — `@AlloyBootstrap`.** Before the container exists: platform bindings, remote config,
anything the graph itself needs. Steps run strictly in order and can inject nothing, because there
is nothing to inject from yet.

```dart
@AlloyBootstrap(order: 0)
class BindPlatform implements AlloyBootstrapStep {
  const BindPlatform();

  @override
  String get name => 'bind-platform';

  @override
  Future<void> run() async => WidgetsFlutterBinding.ensureInitialized();
}
```

Once they have run, the root scope adopts them, so a step that opened something has it closed at
teardown — last, after everything built on top of it. If a step fails, the ones that already ran are
released in reverse before the error is rethrown.

**Phase 1 — `@AlloyInit`.** Inside the container: async singletons, built in dependency order.

```dart
@AlloyInit(dependsOn: [Database])
class SearchIndex {
  final _terms = <String>[];

  Future<void> init() async => _terms.addAll(await loadTerms());
}
```

`dependsOn` is an ordering edge, not an injection. Independent initializers on the same level run
together through `Future.wait`; only what actually depends waits. Naming something that is not an
async registration is a build error rather than the silent no-op it looks like.

`AlloyApplication.start` returns when both phases are done, so there is no `allReady()` to call and
no "registered but not ready" state to reason about.

---

## 9. Values that come from the call site

Half of an object comes from the graph and half from whoever is building it. Mark the half the
container cannot know:

```dart
@alloyInject
class Greeting {
  Greeting(this._config, {@alloyParam required this.name, @alloyParam required this.loud});

  final Config _config;
  final String name;
  final bool loud;
}
```

The generator writes the argument type beside the container as a named record and registers a
parameterized factory:

```dart
// typedef $GreetingArgs = ({String name, bool loud});
final greeting = context.alloyWithParam<Greeting, $GreetingArgs>((name: 'Alloy', loud: false));
```

A named record rather than positional even for a single argument: adding a second changes the
contents of the type, not its name or the shape of the call.

Marked parameters are exempt from the completeness check and from ordering — nothing registers a
`String`. They must be required or nullable: a record has no defaults, so `@alloyParam this.draft =
false` would leave the caller obliged to pass `draft` while the default it was given is dead. That
is a build error.

By hand the same thing is `registerParamFactory<T, P>` with one parameter — bundle several into a
record or a small class of your own.

### Optional dependencies

A `?` on the type is the whole spelling:

```dart
@alloyInject
class Reporter {
  Reporter(this.clock, this.telemetry);

  final Clock clock;
  final Telemetry? telemetry;   // resolved through getOrNull
}
```

A graph that registers no `Telemetry` injects null instead of failing the build. Nullability is not
part of the registration key — `Foo?` still reads the `Foo` registration — and an optional dependency
is still an ordering edge when something does register it.

`getOrNull` returns null only for "nothing is registered". An async singleton asked for before
`init()` still throws, because "not ready" and "not there" are different facts and collapsing them
turns a startup-order bug into a value.

---

## 10. Types you did not write

`@AlloyInject` goes on a class, so it only reaches classes you own. A module is the way in for
everything else:

```dart
@alloyModule
class NetworkModule {
  const NetworkModule();

  @alloyInject
  Dio dio(AppConfig config) => Dio(BaseOptions(baseUrl: config.apiBase));

  @AlloyInject(dispose: closeClient)
  http.Client client() => http.Client();

  @alloySingleton
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}
```

The annotation on the class carries nothing: every member configures its own registration with the
same annotations a class uses, and its parameters are resolved like constructor parameters. The
class needs a public `const` constructor taking no arguments, so the emitted factory holds
`const NetworkModule()` and carries no state.

Returning `Future<T>` is the only async signal — that member becomes an async singleton, and the
order between async members is worked out by the generator rather than written by hand. Members
cannot be abstract: building a class from its own constructor is what `@AlloyInject` already means.

---

## 11. One graph, several builds

Skip this section until one build genuinely needs a different implementation than another. A project
that never writes `@AlloyEnvironment` has one graph, and `$startAlloy()` takes no argument at all.

```dart
@AlloyInject(exposeAs: ApiClient)
@AlloyEnvironment.prod
@AlloyEnvironment.stage
class LiveApiClient implements ApiClient { ... }

@AlloyInject(exposeAs: ApiClient)
@AlloyEnvironment.dev
@AlloyEnvironment.test
class FakeApiClient implements ApiClient { ... }
```

```dart
final scope = await $startAlloy(environment: AlloyEnvironment.prod);
```

The annotation repeats rather than taking a list: a registration belongs to a *set* of environments
while startup picks exactly *one*. `dev`, `stage`, `prod` and `test` are constants, not a closed set
— `@AlloyEnvironment('canary')` behaves identically.

Two registrations of the same type whose environments overlap are a build failure naming both, which
includes the case where one names no environment at all. Each environment is checked for
completeness separately, so a `dev`-only registration cannot satisfy a dependent that also runs in
`prod`.

Starting without choosing is legal and leaves the split types unregistered: the first resolve fails
with the ordinary "not registered" error rather than quietly handing back the wrong class.

---

## 12. Watching the graph

Observers see scopes appearing, instances being built, startup finishing, teardown failing. Pass
them where the graph is created; every scope pushed below inherits them.

```dart
final scope = await AlloyApplication.start(
  root: const AppScope(),
  observers: [AlloyLogObserver(const AlloyDeveloperLogSink())],
);
```

`push(name, observers: [...])` adds more for one subtree.

Callbacks get `AlloyScopeRef` and `AlloyKey` — descriptions, not live objects — and an exception
thrown from one is swallowed: watching must not be able to break what it watches. Resolution is not
reported; a cache hit is the hot path, and what is worth seeing is an instance being *built*.

### Sending it somewhere

| Package | Shape |
|---|---|
| `alloy_talker` | an observer, one coloured log type per event family |
| `alloy_logging` | a sink over dart.dev `logging` |
| `alloy_logger` | a sink over `logger` |

Anything else is one callback, so no logger is locked out for want of a package:

```dart
AlloyLogObserver(AlloyLogSink.from((r) => myLogger.debug(r.message)))
AlloyLogObserver(AlloyLogSink.from((r) => gelf.send(r.toStructured())))
```

The record is not just a string: `level`, `scope`, `key`, `error`, `stackTrace` and `kind` are all
there, and `kind` is a value — `AlloyEventKind.scopeInitFailed` rather than a sentence you would
have to parse.

### Crash reports are a different shape

What makes a report actionable is not the exception; it is what the graph was doing beforehand.

```dart
observers: [
  AlloyErrorObserver(
    AlloyErrorSink.from((report) => Sentry.captureException(
      report.error,
      stackTrace: report.stackTrace,
      withScope: (scope) => scope.setContexts('alloy', report.toStructured()),
    )),
  ),
],
```

The trail is a ring of 20 records kept at every level, including the per-instance ones a log sink
drops. The threshold is `error`, not `warning` — a teardown failure does mean a leak, but paging a
paid service on every hiccup is how reports stop being read. Lower it with `reportAt`.

### On screen, while the app runs

```dart
final log = AlloyInspectorLog();

// observers: [log]

AlloyInspectorScreen(log: log, scope: context.alloyScope)
```

Three tabs: the live scope tree with each registration's lifetime and who owns it, what has actually
been built, and everything reported, searchable and pausable. Opening the tree builds nothing —
materialising a lazy singleton to display it would change what you came to look at.

---

## 13. Tests

The first thing to know is a trap, not an API. `testWidgets` runs its body inside a fake-async zone,
where a `Future.delayed` in an initializer never completes. **Build the graph in `setUp`**, and keep
whole-graph assertions in a plain `test`.

```dart
late AlloyScope scope;

setUp(() async {
  scope = await alloyTestScope(root: const AppScope());
});
```

`alloyTestScope` and `alloyTestRoot` dispose with the test, which is the part that is easy to leave
out — and leaving it out leaks into the next test rather than failing.

### Overriding

Push a child scope and register again. Shadowing is how production overrides work too, so a test
uses the same mechanism the app does:

```dart
final overrides = scope.pushForTest()
  ..registerSingleton<Clock>(FixedClock(DateTime(2026)));
```

One rule decides whether this works, and everyone meets it once: **a factory runs on the scope that
owns its own registration.** Override below the consumer and it is invisible to it. `ownerOf<T>()`
answers before the test does:

```dart
expect(scope.ownerOf<Greeter>(), same(scope.root));   // registered in the root, so override there
```

### Checking a hand-written graph

The generator rejects an incomplete graph at build time, but only for what it generated — a
hand-written factory resolves inside `create`, so nothing static can see what it will ask for.
Running it is the only check:

```dart
await expectGraphResolves(scope);
```

It is terminal: resolving *is* the check, so afterwards every lazy singleton is built and the
teardown order is different. Put it in a test of its own.

A parameterized registration cannot be resolved without a value, so it is reported by name as
`unchecked` rather than skipped in silence — hand it a sample to actually cover it:

```dart
await expectGraphResolves(scope, params: {AlloyKey(Counter): 'alice'});
```

### Fixtures

```dart
final scope = alloyTestRoot()
  ..registerLazySingleton<Clock>(FnFactory((_) => FixedClock(DateTime(2026))))
  ..registerSingleton<Config>(const Config())
  ..registerAsyncSingleton<Db>(AsyncFnFactory((_) async => Db()))
  ..registerParamFactory<Counter, String>(FnParamFactory((_, id) => Counter(id)));

await scope.init();
```

Async registrations have to exist **before** `init()`. It takes the async registrations it finds when
it starts and runs once, so registering one into a scope that is already active is an error rather
than something that quietly never gets built — which is what makes an already-started scope the wrong
place to add fixtures to.

`DisposeRecorder` is the fixture for teardown assertions, with a log per instance rather than a
shared one, so a scope disposed after the test that made it cannot report into the next:

```dart
final recorder = DisposeRecorder();
scope.registerLazySingleton<Disposable>(recorder.factory('cache'));
scope.get<Disposable>();

await scope.dispose();
expect(recorder.entries, ['cache']);
```

`CapturingObserver` collects events for assertions about what the graph did.

### Widget tests

`alloy_test_flutter` carries the two helpers whose obvious spelling is wrong:

```dart
await settle(tester);                    // not pumpAndSettle: it spins forever on a loading indicator
final scope = mountedRootScope(tester);  // the app's graph, from below the MaterialApp builder
```

---

## 14. The lint plugin

Twelve rules, built on the same parsing layer the generator uses, so a mistake shows up in the
editor rather than only when `build_runner` runs.

```yaml
# analysis_options.yaml
plugins:
  alloy_lint: ^0.1.0
```

Two things about wiring it cost real time:

1. The `plugins:` section **only works at the root of a package or workspace**. In a nested
   `analysis_options.yaml` it is silently ignored — no error, no diagnostics. For the same reason
   `dart analyze <nested/dir>` does not apply it; analyze the workspace root.
2. The analysis server caches its build of the plugin per context. "The rule does not fire" usually
   means a stale build, not a wrong rule — touch the plugin's file, or restart the server.

---

## 15. Mistakes worth knowing about in advance

Each of these was found the hard way, in this repository or in the applications it was written for.

- **Building the graph inside `testWidgets`.** Fake-async, no completion, a timeout with nothing to
  point at. `setUp`.
- **Overriding below the consumer.** The factory runs on the owning scope. `ownerOf<T>()` tells you
  before the assertion does.
- **`bootstrap` as a stored list.** Steps hold resources; a restart must get new ones. Pass a
  function.
- **`BlocProvider(create:)` for a bloc the scope owns.** Two owners, and the widget wins first.
  `BlocProvider.value`.
- **A `ChangeNotifier` or `Cubit` registered without saying it is closable.** Built, used, never
  closed, silently. `implements Disposable`, `with AlloyBloc`, or `dispose:`.
- **`@AlloyInject` on a generic class.** Rejected: nothing tells the generator which instantiations
  to register. Annotate a concrete subtype, or expose one with `exposeAs`. Generics work fine as
  dependencies and as `exposeAs` targets.
- **An old `dart` first on PATH.** It fails quietly and in the wrong place — `dart analyze` reports
  phantom issues against the wrong analyzer, and `dart format` rewrites untouched files. Check
  `dart --version` before believing a run.

---

## Where to go next

- [README.md](README.md) — what Alloy is, and why each decision went the way it did.
- [MIGRATION.md](MIGRATION.md) — from `get_it` and `injectable`, including what does not translate.
- `examples/gallery` — one Flutter app, fourteen entries, one per capability:
  `cd examples/gallery && flutter run`.
- Package READMEs for the details: [`alloy`](packages/alloy/README.md),
  [`alloy_flutter`](packages/alloy_flutter/README.md),
  [`alloy_generator`](packages/alloy_generator/README.md),
  [`alloy_lint`](packages/alloy_lint/README.md),
  [`alloy_test`](packages/alloy_test/README.md).
