[English](README.md) · [Русский](README.ru.md) · [中文](README.zh-CN.md)

# Alloy

Dependency injection framework for Dart and Flutter. Dual-mode: declarative code generation
and a pure-Dart manual API over the same runtime.

Status: **Phase 1 complete.** Runtime, Flutter bindings, annotations, analysis layer, both
generators and the lint plugin are implemented and tested.

New here with an existing `get_it` or `injectable` setup? Start with
[MIGRATION.md](MIGRATION.md) — it covers what maps onto what, and, more usefully,
what does not.

## Packages

| Package | Depends on | Ships to apps |
|---|---|---|
| `alloy_annotations` | `meta` | yes |
| `alloy` | `alloy_annotations` | yes, runtime core, no Flutter |
| `alloy_flutter` | `alloy`, `flutter` | yes |
| `alloy_go_router` | `alloy_flutter`, `go_router` | yes, optional |
| `alloy_bloc` | `alloy`, `bloc` | yes, optional |
| `alloy_talker` | `alloy`, `talker` | yes, optional |
| `alloy_logging` | `alloy`, `logging` | yes, optional |
| `alloy_logger` | `alloy`, `logger` | yes, optional |
| `alloy_analyzer` | `alloy_annotations`, `analyzer` | no |
| `alloy_generator` | `alloy_analyzer`, `build`, `source_gen`, `code_builder` | dev_dependency only |
| `alloy_lint` | `alloy_analyzer`, `analysis_server_plugin` | dev_dependency only |
| `alloy_test` | `alloy`, `test_api`, `matcher` | dev_dependency only |
| `alloy_test_flutter` | `alloy_flutter`, `flutter_test` | dev_dependency only |
| `alloy_inspector` | `alloy_flutter`, `flutter` | dev_dependency only |
| `alloy_talker_flutter` | `alloy_inspector`, `alloy_talker`, `talker_flutter` | dev_dependency only |

`alloy_analyzer` exists so the generator and the lint plugin parse Alloy declarations through one
implementation instead of two that drift apart. It owns the IR and the topological sort, and depends
on neither `build` nor the plugin API.

**Project invariant:** generated code may only use the public API of `alloy`. The moment generation
needs something Manual Mode cannot express, these are two frameworks sharing a name.

## Toolchain

Built and tested on **Flutter 3.47.1 / Dart 3.13.1**, with analyzer 13.3.0.

Every package requires Dart `^3.13.0`, and no Flutter below **3.47** ships it — so
that is the floor, uniformly, and there is no version spread between packages to
watch out for. CI runs `stable` and `beta` rather than a matrix of past releases:
the useful failure to catch is the one that has not shipped yet.

Do not use a Homebrew `dart` on PATH — put the Flutter SDK first. An older `dart` does not fail
loudly: `dart analyze .` reports dozens of phantom issues against the wrong analyzer, and `dart
pub get` refuses the SDK constraint outright. Check with `dart --version` before trusting a run.

Pin `dart_style` deliberately: 3.1.7 requires `analyzer <12.0.0` and silently holds the whole
workspace back three majors. Golden output also shifts between formatter releases.

## Verify

```
dart analyze --fatal-infos .
dart format --output=none --set-exit-if-changed .
(cd packages/alloy && dart test)
(cd packages/alloy_flutter && flutter test)
(cd examples/manual_mode && dart test)
(cd examples/codegen_basics && dart run build_runner build && flutter test)
(cd examples/notes_app && dart run build_runner build && flutter test)
(cd packages/alloy_lint && dart test)
(cd packages/alloy_test && dart test)
(cd packages/alloy_inspector && flutter test)
(cd packages/alloy_talker_flutter && flutter test)
(cd examples/gallery && flutter test)
(cd compat/external_consumer && dart pub get && dart run build_runner build && dart test)
./tool/coverage.sh
```

`tool/coverage.sh` measures line coverage of the eleven publishable packages that have tests, prints
them worst-first, and fails under a floor on the **total** — 85%. The current figure is what the script prints, and
is not repeated here: a number that moves with every commit goes stale in prose and nothing checks
it, which it has already done twice. The floor is
on the total rather than per package deliberately: coverage is measured per package while the code
is shared, so `alloy_analyzer`'s parsers are driven far more from `alloy_generator`'s tests and from
`compat/external_consumer` than from their own suite. A per-package floor would demand tests written
where they do not belong. Override it with `COVERAGE_FLOOR=90 ./tool/coverage.sh`.

CI (`.github/workflows/ci.yml`) runs all of the above plus a `git diff --exit-code` after
regenerating both examples **and `compat/external_consumer`**, so stale generated code fails the
build. The generator formats its own
output with the same `dart_style` version the format check uses, so the two never disagree.

## Testing an app built on Alloy

`testWidgets` runs its body inside a fake-async zone, so a `Future.delayed` in an initializer never
completes there. Build the root scope in `setUp`, not inside `testWidgets`, and keep whole-graph
assertions in a plain `test`. `examples/notes_app/test/screens_test.dart` uses both.

To override a dependency, push a child scope and register it again — a duplicate registration in
one scope is an error, but shadowing from a child is the supported way, in tests as in production.

`alloy_test` packages the mechanics: `alloyTestScope` builds a graph and disposes it with the test,
`pushForTest` does the same for an override scope, and `ownerOf<T>()` answers the question that
trips everyone once — a factory runs on the scope that owns *its* registration, so an override
below the consumer is invisible to it.

It also carries `expectGraphResolves`, the only way to check a hand-written graph. The generator
rejects an incomplete graph at build time, but it only sees what it generated; a factory never
declares what it will ask for, so a manual graph can only be checked by running it. That check is
terminal — resolving *is* the check, so afterwards every lazy singleton is built.

## Known publish warning

`alloy_lint` reports "the name of lib/main.dart should match the name of the package". That entry
point is fixed by the analysis server plugin API — the server generates code that imports
`package:alloy_lint/main.dart` and reads its `plugin` variable. `riverpod_lint` carries the same
warning.

## Layout

One public type per file. The sealed `AlloyRegistration` hierarchy is the deliberate exception: a
sealed hierarchy must live in one library, so its subclasses are `part` files of
`src/registration/alloy_registration.dart` rather than separate libraries.

`compat/external_consumer` is the one directory outside this rule of thumb: it is a package that is
deliberately **not** a workspace member and carries no `resolution: workspace`, so pub resolves it
standalone the way a third-party project would. It exists to keep the code-generation pipeline
honest from outside the repository — see its own README.

## Generators

`alloy_generator` ships three builders:

| Builder | Input → output | Purpose |
|---|---|---|
| `alloy_property_injection` | `.dart` → `.alloy.g.part` | mixins that inject `late final` fields |
| `alloy_scan` | `.dart` → `.alloy.json` (cache) | per-library IR |
| `alloy_container` | `$lib$` → `lib/alloy.g.dart` | `$AlloyRootScope`, `$alloyBootstrap`, `$startAlloy()` |

`alloy_scan` runs before `alloy_container`; the container builder reads every `.alloy.json` through
`findAssets` because a single build step cannot see the whole program. It emits private const
factory classes and a `$AlloyRootScope`, with registrations ordered by a compile-time topological
sort. Property-injected fields count as dependency edges, so a bloc is always registered after what
it injects. A dependency cycle fails the build naming the cycle, rather than emitting broken code.

Generic types work as dependencies and as `exposeAs` targets: `Repository<User>` and
`Repository<Order>` are two separate registrations, because at runtime `AlloyKey` is built from
`Type` and those are different types. The **injectable class itself** may not be generic —
`@AlloyInject class Cache<T>` is rejected, because nothing tells the generator which instantiations
to register. Annotate a concrete subtype, or expose one with `exposeAs`.

Nullability is not part of a registration *key* — a `Foo?` dependency still reads the `Foo`
registration — but it does mark the dependency **optional**. A nullable constructor parameter or
`@injected` field resolves through `getOrNull`, so a graph that registers nothing for it injects
null instead of failing the build. Required dependencies are unchanged, and an optional one is
still an ordering edge when something does register it.

Optional is the type's job, not an annotation's: without `?` the field could not hold null anyway.
The runtime spelling is `scope.getOrNull<Foo>()`, which returns null only when nothing is
registered — an async singleton asked for before `init()` still throws, because "not ready" and
"not there" are different facts.

`@AlloyBootstrap` classes are collected into `$alloyBootstrap`, ordered by their `order` and then by
name so the output is stable. They run strictly sequentially, before the container exists, so the
parser rejects any bootstrap step whose constructor takes required parameters.

`$alloyBootstrap` is emitted as a **getter**, not a stored list: a top-level `final` would build the
steps once per process, quietly sharing them between a retried startup and between tests, and
keeping them alive after the scope that adopted them is gone. Once the steps have run, the root
scope adopts them, so a step that opened something has that closed at teardown — last, after
everything built on top of it. If a step fails, the ones that already ran are released in reverse
before the error is rethrown, since there is no scope yet to hand them to.

`@AlloyInit` classes become async singletons: the generated factory constructs the object, awaits
its `init()`, and registers it with `dependsOn` translated into `AlloyKey`s. Note the set literal is
built at runtime rather than `const` — `AlloyKey` overrides `==`, and const set elements must have
primitive equality.

### Environments — optional

Nothing so far needs this. A project that never writes `@AlloyEnvironment` has exactly one graph,
every registration belongs to it, and `$startAlloy()` takes no environment at all. Reach for the
rest of this section only when one build needs a different implementation than another.

`@AlloyEnvironment` restricts a registration to one or more environments:

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

`dev`, `stage`, `prod` and `test` are constants, not a closed set — `@AlloyEnvironment('canary')`
declares one of your own and behaves identically. The annotation repeats rather than taking a list,
so a registration belongs to a *set* of environments while startup picks exactly *one*:

```dart
final scope = await $startAlloy(environment: AlloyEnvironment.prod);
```

The generated container takes the choice as a field and guards only the restricted registrations:

```dart
final class $AlloyRootScope implements AlloyScopeBuilder {
  const $AlloyRootScope({
    this.environment = AlloyEnvironment.defaultEnvironment,
  });

  final AlloyEnvironment environment;

  @override
  void build(AlloyScope scope) {
    scope.registerLazySingleton<EventLog>(const _EventLogFactory());
    if (environment.matches(const <String>{'dev', 'test'})) {
      scope.registerLazySingleton<ApiClient>(const _FakeApiClientFactory());
    }
    if (environment.matches(const <String>{'prod', 'stage'})) {
      scope.registerLazySingleton<ApiClient>(const _LiveApiClientFactory());
    }
  }
}
```

Three things follow from that shape:

- **It stays opt-in to the end.** The `environment` parameter appears only once some declaration
  names an environment, and even then it defaults to `AlloyEnvironment.defaultEnvironment` — the
  single environment an unsplit graph lives in. That default matches unrestricted registrations and
  nothing else, so starting a split graph without choosing leaves the split types unregistered, and
  the first resolution of one fails saying so instead of quietly handing back the wrong class.
- **Nothing is registered twice.** The generator rejects two registrations of the same type whose
  environments overlap — including the case where one names no environment at all, since an
  unrestricted registration is present everywhere. What would otherwise be a silent last-one-wins
  is a build failure naming both classes and the environment they collide in.
- **Manual Mode can do the same thing.** `matches` is ordinary public API, so a hand-written
  builder writes the same `if` the generator emits. Subclass `AlloyEnvironment` and override
  `matches` to activate several at once, or to match on something other than the name.

`@AlloyBootstrap` steps take environments too. When any of them does, `$alloyBootstrap` becomes a
function of the chosen environment instead of a getter, and skipped steps never run and never get
adopted:

```dart
List<AlloyBootstrapStep> $alloyBootstrap(AlloyEnvironment environment) => [
  BindPlatform(),
  if (environment.matches(const <String>{'prod', 'stage'})) ReportCrashes(),
];
```

An environment nobody claims is legal and leaves those types unregistered — resolving one then
fails with the ordinary "not registered" error rather than silently handing back the wrong class.

`@AlloyScopeRoot` names the root scope and collapses startup to one call:

```dart
final scope = await $startAlloy();
```

The generator emits `$alloyRootScopeName` plus a `$startAlloy()` that wires the container, the
bootstrap list and the name together. Without the annotation the name defaults to `root`; two
annotated classes in one package is a generation error.

### Registering types you did not write

`@AlloyInject` goes on a class, so it only reaches classes you own. A module is the way in for
everything else — a client from another package, a value the SDK hands you:

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

The annotation carries nothing: every member configures its own registration with the same
annotations a class uses, and its parameters are resolved like constructor parameters. The class
needs a public `const` constructor taking no arguments, so the emitted factory holds
`const NetworkModule()` and carries no state.

`Future<T>` is the only async signal — a member returning it becomes an async singleton, and the
ordering between async members is worked out by the generator rather than written by hand. A member
cannot be abstract: building a class from its own constructor is what `@AlloyInject` already means.

`dispose` is how a foreign type gets closed. The scope owns what it builds, but a type from another
package implements neither `Disposable` nor `AsyncDisposable`, so it cannot say how to close
itself. It is available on any retained registration, in Manual Mode too:

```dart
scope.registerLazySingleton<http.Client>(
  const ClientFactory(),
  dispose: (client) => client.close(),
);
```

### The graph has to be complete before it builds

A dependency nothing registers fails the build, naming every gap at once:

```
Diagnostics requires DeviceInfo, which nothing registers. Annotate the class that
provides it with @AlloyInject, or name it in @AlloyScopeRoot(provides: [...]) when
something outside the generated container registers it.
```

A parameter marked `@AlloyParam` is exempt: the call site supplies it, so nothing registers it and
nothing orders around it. Marking one turns the class into a parameterized registration, and the
generator writes its argument type beside the container as a named record:

```dart
@alloyInject
class NoteEditor {
  NoteEditor(this._notes, {@alloyParam required this.id, @alloyParam this.draft = false});
  ...
}

// typedef $NoteEditorArgs = ({int id, bool draft});
context.alloyWithParam<NoteEditor, $NoteEditorArgs>((id: 7, draft: true));
```

Constructor parameters, `@injected` fields and `@AlloyInit(dependsOn:)` all count, and a
`@Named` qualifier is part of the key — asking for `@Named('audit') Logger` where only an unnamed
`Logger` exists is a gap. Each environment is checked separately, so a `dev`-only registration
cannot satisfy a dependent that also runs in `prod`.

The container only sees its own package's annotations. Anything registered by hand — a scope
builder wrapping `$AlloyRootScope`, or a provider from another package — has to be promised:

```dart
@AlloyScopeRoot(name: 'app', provides: [SessionManager])
class AppScope {
  const AppScope();
}
```

A promise registers nothing; it only tells the check that something else will.
`AlloyProvided(Logger, name: 'audit')` promises a named one.

This is a Code-Gen Mode guarantee. A hand-written factory resolves inside `create`, so nothing
static can see what it will ask for — Manual Mode graphs still fail at runtime with
`AlloyNotRegisteredError`.

## Who owns the root scope

`AlloyAppScope` owns it: builds the graph, publishes it, disposes it on unmount, and turns a
startup failure into a screen with a retry instead of an app that dies before its first frame.

It takes the graph the same way `AlloyApplication.start` does, and lives in `MaterialApp.builder`,
so `loading` and `errorBuilder` are ordinary screens with the app's theme rather than a second
`MaterialApp`:

```dart
void main() => runApp(
  MaterialApp(
    builder: AlloyAppScope.builder(
      root: $AlloyRootScope(environment: environment),
      bootstrap: () => $alloyBootstrap(environment),
      rootName: $alloyRootScopeName,
      loading: const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
    home: const HomeScreen(),
  ),
);
```

`bootstrap` is a function rather than a list on purpose: steps hold resources, and a restart has to
get new ones. `AlloyAppScope.start(start: ...)` remains for a graph this shape cannot express.

`AlloyAppScope.of(context).restart()` rebuilds the graph — the same call retries a failed start.
Disposing on app termination is opt-in (`disposeOnExitRequest`) and desktop-only in practice; see
the `alloy_flutter` README for why Flutter cannot promise it on mobile.

## Watching the graph

`AlloyObserver` reports what the graph does — scopes appearing, instances being built, startup
finishing, teardown failing. Pass observers where the graph is created:

```dart
final scope = await AlloyApplication.start(
  root: const AppScope(),
  observers: [AlloyLogObserver(const AlloyDeveloperLogSink())],
);
```

Observers are inherited by every scope pushed below, so one registration covers the tree.

Two things shape the design. Callbacks receive `AlloyScopeRef` and `AlloyKey` — descriptions, not
live objects — because an observer that could resolve from a scope halfway through teardown, or
dispose it a second time, is not watching any more. And an exception thrown from a callback is
swallowed: watching must not be able to break what it watches.

Resolution is not reported. A cache hit is the hot path and an event per `get` would be noise; what
is worth seeing is an instance being *built*, which `onInstanceCreated` covers. With no observers
registered the cost of every event is one empty-list check.

`AlloyLogObserver` turns events into `AlloyLogRecord`s and hands them to an `AlloyLogSink`.
`AlloyDeveloperLogSink` (`dart:developer`, no dependencies) ships in `alloy`; the adapter packages
connect the rest:

| Package | Shape | Why |
|---|---|---|
| `alloy_talker` | `AlloyObserver` | each event kind becomes its own coloured `TalkerLog`, filterable in `TalkerScreen` |
| `alloy_logging` | `AlloyLogSink` | dart.dev `logging` has no notion of a record kind |
| `alloy_logger` | `AlloyLogSink` | same, plus its own console printing |

### Any other logger, without a package

A sink is one callback, so nothing is locked out for want of an adapter:

```dart
AlloyLogObserver(AlloyLogSink.from((record) => myLogger.debug(record.message)))
```

| Logger | The whole integration |
|---|---|
| `loggy` | `AlloyLogSink.from((r) => logDebug(r.message))` |
| `fimber` | `AlloyLogSink.from((r) => Fimber.d(r.message, ex: r.error))` |
| `simple_logger` | `AlloyLogSink.from((r) => logger.info(r.message))` |
| Graylog, or any JSON intake | `AlloyLogSink.from((r) => gelf.send(r.toStructured()))` |

The record is not just a string. `level`, `scope`, `key`, `error` and `stackTrace` are all there,
and `kind` names the event as a value — `AlloyEventKind.scopeInitFailed` rather than the sentence
`scope "app" failed to initialize`, which is free to be reworded. `toStructured()` hands the lot
over as a map, which is the whole of a GELF or JSON sink.

### Crash reporting is a different shape

A log sink is handed every line and has to be cheap. A crash reporter is handed discrete incidents
that cost a network call and a quota, and what makes one actionable is not the exception — it is
what the graph was doing beforehand. `AlloyErrorObserver` reports failures with that trail
attached:

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

| Reporter | The whole integration |
|---|---|
| Sentry | `AlloyErrorSink.from((r) => Sentry.captureException(r.error, stackTrace: r.stackTrace))` |
| Crashlytics | `AlloyErrorSink.from((r) => FirebaseCrashlytics.instance.recordError(r.error, r.stackTrace))` |

Two defaults worth knowing. The trail is kept at every level, including the per-instance records a
log sink drops — they cost nothing until something fails, and "what was built last" is usually the
useful line; it is a ring of 20, so a long-running app cannot grow it without bound. And the
reporting threshold is `error`, not `warning`: a teardown failure arrives as a warning and does mean
a resource leaked, but paging a paid service on every hiccup is how reports stop being read. Lower
it with `reportAt` when you want them.

It reports only what Alloy itself knows went wrong — an initializer that threw, a bootstrap step
that failed, a teardown that could not finish. There is no method for reporting an arbitrary error,
because this is not a general error channel; the reporter you already have is that.

`AlloyMultiSink` fans one record out to several destinations, and a sink that throws does not
silence the rest — console plus crash reporting is the normal production pair:

```dart
AlloyLogObserver(
  const AlloyMultiSink([AlloyDeveloperLogSink(), _CrashReporterSink()]),
)
```

Two sinks ship in `alloy` itself with no dependencies: `AlloyDeveloperLogSink` (`dart:developer`,
the right default in a Flutter app) and `AlloyPrintLogSink` (stdout, for a CLI or a first look).

This is also the channel that fixed a real gap: when startup fails and Alloy rolls back, a bootstrap
step that *also* fails to release cannot be reported through `AlloyBootstrapError` without masking
the failure that caused it. It used to be dropped by a bare `catch`. It is now
`onBootstrapStepReleaseFailed`.

## Flow scopes

`alloy_go_router` makes a scope's lifetime a navigation flow — created when the flow opens,
disposed when it closes:

```dart
AlloyShellRoute(
  name: 'checkout',
  identity: (state) => state.pathParameters['orderId'],
  scope: (state) => CheckoutScope(state.pathParameters['orderId']!),
  routes: [...],
)
```

It is an ordinary `ShellRoute` subclass — so it drops into a route table anywhere a `RouteBase`
goes, and a flow can be given a name of its own by subclassing it. The scope is owned by a widget
inside it. That is enough because go_router keys a shell's page by the identity of the route
object, so the subtree
survives every navigation *within* the flow and is destroyed the frame the flow leaves the match
list. Nothing watches the router and mirrors it — mirroring is where hand-rolled versions break on
the back button, on deep links and on tab switches.

Tabs get the same treatment: `AlloyStatefulShellRoute` scopes a whole `StatefulShellRoute` and
`AlloyStatefulShellBranch` scopes one tab, composing into three levels. A branch, though, is kept
*alive* rather than kept *visible* — go_router preserves branch navigators off-screen, so a tab's
scope lives until the shell closes, not until you switch away.

The one thing the router cannot decide is whether `/orders/1` and `/orders/2` are the same flow;
that is what `identity` answers. A flow whose routes are not one subtree cannot be expressed this
way, and that limitation is deliberate — see the package README.

## Examples

One app runs them all:

```bash
cd examples/gallery && flutter run
```

The gallery is organised by **capability**, not by project — a reader arrives wanting to know how
scopes end, not wanting to see `notes_app`. Fourteen entries in six sections:

| Section | Entries |
|---|---|
| Startup | Two-phase startup · Environments |
| Injection | Property injection · Named and multi-injection |
| Scopes & lifetime | Widget-owned scope · Session scope · Scope tree · Navigation flows · Teardown |
| Code generation | Generated container · Manual mode |
| Observability | Graph events · In-app inspector |
| Testing | Testing patterns |

Each entry that has a UI opens with a graph **of its own**, built when you open it and disposed
when you leave. Open two and their scope trees are unrelated — which is the thing the gallery is
really there to show. The three entries with no UI (`Teardown`, `Manual mode`, `Testing patterns`)
show their console output instead of a button, because a gallery that offered to "open" a CLI would
be lying.

The gallery is written in English, Russian and Chinese, switchable from the hub — and so is every
screen it mounts. Each example package carries its own `l10n/*.arb` and generates its own delegate,
which the gallery collects beside its own and the inspector's; that is what a multi-package Flutter
app looks like. Two places had prose below the widgets, where there is no `BuildContext` to ask
about the language, and both now report facts the screen names instead.

The framework's own log records are still English, as are the identifiers on screen — step names,
scope names, registration keys, lifetimes. See the
[`alloy_inspector` README](packages/alloy_inspector/README.md) for what stays in Alloy's own words
and why, and the [gallery's](examples/gallery/README.md) for how the examples are wired.

Behind it, the examples stay ordinary packages under `examples/` — `notes_app`, `flow_scopes`,
`graph_events`, `codegen_basics` are libraries the gallery mounts, and `manual_mode`, `teardown`,
`testing_patterns` are pure Dart or test-only. They stay separate for a reason that is not
tidiness: `alloy_container` aggregates a whole package into one `$AlloyRootScope`, so two generated
examples in one package would have their graphs merged.

## Lint plugin

`alloy_lint` is an `analysis_server_plugin`, not a `custom_lint` plugin (see Toolchain). It ships
twelve warning rules, all built on the same `alloy_analyzer` parsing layer the generator uses, so a
mistake surfaces in the IDE instead of only when `build_runner` runs:

| Rule | Catches |
|---|---|
| `alloy_missing_injection_mixin` | `@injected` fields without `with _$ClassName`, on a class the container registers |
| `alloy_injected_field_needs_an_injectable` | `@injected` fields on a class the container never registers |
| `alloy_param_needs_an_injectable` | `@AlloyParam` on a class the container never registers |
| `alloy_injected_field_must_be_late_final` | `@injected` on a mutable, non-late, or static field |
| `alloy_injectable_must_be_constructible` | `@AlloyInject` on an abstract class or one with no public generative constructor |
| `alloy_init_requires_init_method` | `@AlloyInit` on a class with no `init()` |
| `alloy_bootstrap_requires_run_method` | `@AlloyBootstrap` on a class with no `run()` |
| `alloy_bootstrap_step_cannot_inject` | a bootstrap step whose constructor takes required parameters |
| `alloy_environment_needs_a_registration` | `@AlloyEnvironment` on a class nothing registers, where it silently does nothing |
| `alloy_dependency_is_not_registered` | an injected dependency nothing in the package registers |
| `alloy_dependency_cycle` | an injectable class that depends, eventually, on itself |
| `alloy_registration_is_never_released` | a registered class with a `dispose()` or `close()` the scope cannot see |

Two things about wiring it up cost real time and are easy to get wrong:

1. The `plugins:` section **only works at the root of a package or workspace**. Put it in a nested
   `analysis_options.yaml` and it is silently ignored — no error, no diagnostics. For the same
   reason `dart analyze <nested/dir>` does not apply it; analyze the workspace root instead.
2. The analysis server resolves plugins in an isolated pub context, so unpublished workspace
   siblings are invisible to it. Every unpublished transitive dependency needs an entry under
   `plugins: dependency_overrides:` — see this repo's root `analysis_options.yaml`.

Rule behaviour is covered by `analyzer_testing` tests in `packages/alloy_lint/test`, which exercise
the rules directly and need none of the plugin bootstrap.

## Linting

`custom_lint` is not used. Its latest release (0.8.1) is pinned to `analyzer ^8.0.0` and cannot
coexist with a modern analyzer; `riverpod_lint` migrated off it to the first-party
`analysis_server_plugin`, and `alloy_lint` follows.
