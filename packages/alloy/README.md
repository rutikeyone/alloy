# alloy

Runtime core of [Alloy](https://github.com/rutikeyone/alloy), a dependency injection framework for
Dart and Flutter. Pure Dart — it has no Flutter dependency, so the same graph runs in tests, CLIs
and servers. For widgets, add `alloy_flutter`.

Alloy works with or without code generation. The generator writes exactly what you would write by
hand, using only the public API of this package.

```dart
final scope = AlloyScope.root(name: 'app')
  ..registerLazySingleton<Logger>(const LoggerFactory())
  ..registerAsyncSingleton<Database>(const DatabaseFactory())
  ..registerAsyncSingleton<SearchIndex>(
    const SearchIndexFactory(),
    dependsOn: {const AlloyKey(Database)},
  );

await scope.init();
final index = scope.get<SearchIndex>();
await scope.dispose();
```

`SearchIndex` states `dependsOn` because both it and `Database` are built during `init()` and one
has to finish first. `Logger` needs no such line: a factory that wants it simply resolves it.

## What it guarantees

- **Hierarchical scopes.** `scope.push('session')` creates a child that sees its parent and can
  shadow it. Parents never resolve downwards.
- **Deterministic teardown.** A scope disposes its children first, then its own instances in
  reverse *creation* order — not registration order, so an object is always torn down before what
  it depends on. Teardown is best-effort under a deadline covering the whole
  tree (30s by default): a step that throws or runs past the deadline is recorded and the remaining
  steps still run, so one broken object cannot strand everything after it. The scope always reaches
  `disposed`; `AlloyDisposeError` is then thrown listing every failure, with `hasTimeout` telling
  overruns from thrown errors.

  A failed `init()` is the one thing that does not count as a teardown failure: the error already
  went to whoever called `init()`, so `dispose()` records it as context — visible through
  `initFailures`, and only reported when teardown itself also broke. An init that *hangs* is
  different, since finishing that wait is teardown's own work, and it is reported like any other
  overrun.
- **Async init as a graph.** `dependsOn` is topologically sorted into levels; each level runs
  through `Future.wait`, so independent branches start together. It waits only for another async
  registration — naming a plain one fails `init()` rather than being dropped, because a
  registration with no async build has nothing to finish. An async registration in an *ancestor*
  is the exception and is ignored: a parent's phase 1 is its own, and a child pushed onto a live
  parent finds it already built.
- **Cycles fail loudly.** Both the init graph and runtime resolution raise `AlloyCycleError`
  naming the path, rather than deadlocking or overflowing the stack.
- **No closures in registrations.** Factories are objects (`AlloyFactory`, `AlloyAsyncFactory`,
  `AlloyParamFactory`), so generated code can be `const`.
- **The graph can report itself.** `AlloyObserver` sees scopes appear, instances get built,
  startup finish and teardown fail. Callbacks receive descriptions (`AlloyScopeRef`, `AlloyKey`)
  rather than live objects, and an exception thrown from one is swallowed — watching must not break
  what it watches. `AlloyLogObserver` plus `AlloyDeveloperLogSink` is the zero-dependency default;
  `alloy_talker`, `alloy_logging` and `alloy_logger` connect real loggers.

  ```dart
  final scope = await AlloyApplication.start(
    root: const AppScope(),
    observers: [AlloyLogObserver(const AlloyDeveloperLogSink())],
  );
  ```

  Any logger works without an adapter, because a sink is one callback:

  ```dart
  AlloyLogObserver(AlloyLogSink.from((record) => myLogger.debug(record.message)))
  ```

  `AlloyMultiSink` fans a record out to several destinations, and a sink that throws does not
  silence the others. With no observers registered, each event costs one empty-list check.
- **Environments are optional, and a plain guard when used.** A graph has one environment until you
  split it. `AlloyEnvironment.matches` then decides whether a registration restricted to some names
  belongs to this build, so selecting an implementation per environment is one `if` around a
  `register*` call and reads the same whether you wrote it or the generator did:

  ```dart
  if (environment.matches(const {'dev', 'test'})) {
    scope.registerLazySingleton<ApiClient>(const FakeApiClientFactory());
  }
  ```

  `dev`, `stage`, `prod` and `test` are constants rather than a closed set, and subclassing
  `AlloyEnvironment` to override `matches` activates several at once.
- **Nothing outlives the scope by accident.** Bootstrap steps run before any container exists, so
  they cannot be registered — but the root scope adopts them, and a step holding a resource is
  released with the scope. Adopted first, they are disposed last, after everything built on the
  platform they set up. `scope.adopt(x)` does the same for any object that belongs to a scope's
  lifetime without being a dependency.

Ownership is explicit: a parent holds its children strongly, and whoever creates a scope closes it.
A scope that is dropped without `dispose()` leaks by design — that is the price of a deterministic
teardown order, and it is what makes `dispose()` reliable.

## Closing what the scope cannot recognise

A scope tears down what it built, in reverse creation order, by looking for
`Disposable` or `AsyncDisposable`. A type from another package implements
neither, so it says nothing about how to close — pass `dispose` and the scope
calls it at teardown, in the same order as everything else:

```dart
scope.registerLazySingleton<http.Client>(
  const ClientFactory(),
  dispose: (client) => client.close(),
);

scope.adopt(controller, dispose: (it) => it.close());
```

It is available on every registration the scope retains — `registerSingleton`,
`registerLazySingleton`, `registerAsyncSingleton` and `adopt`. It is deliberately
**not** on `registerFactory` or `registerParamFactory`: a transient is not
retained, so a callback there could never run, and a signature that accepts one
would be lying.

For a class you own, implement `Disposable` instead. Keeping the knowledge on
the object rather than at each registration means it cannot be forgotten at one
of them.

## Optional dependencies

`scope.getOrNull<T>()` returns null when nothing is registered for `T`, instead of throwing. It is
what a nullable dependency reads: in Code-Gen Mode a `Foo?` parameter or `@injected` field is
emitted as `getOrNull`, so a graph that supplies nothing injects null.

Null means one thing only — nothing is registered under that key. An async singleton asked for
before `init()` still throws `AlloyNotReadyError`, and a parameterized factory still throws.
Folding those into null would turn a startup-ordering bug into a value that reads as "absent".

## Inspecting a scope

Four read-only members, for diagnostics and tests:

| Member | Answers |
|---|---|
| `keys` | what this scope registers, in registration order |
| `visibleKeys` | every key resolvable from here, mapped to the scope that owns it |
| `root` | the outermost scope above this one |
| `debugDescribeTree()` | the subtree as text, one line per scope |

`visibleKeys` is a map rather than a set because the owner is the interesting part: a factory runs
on the scope that owns *its* registration, not the scope you asked from, so a key alone cannot tell
you what an override will reach.

None of them throws on a scope that is being torn down, so a diagnostics screen keeps working
during teardown.

What they deliberately do not tell you:

- **Declared, not built.** A lazy singleton nobody resolved looks exactly like one that is built.
- **Not what teardown will release.** Objects handed to `adopt` have no key at all.
- **Not a count of instances.** One key can stand for any number of live transients, or none.
- **Nothing after `dispose`.** The registrations are cleared, not kept as a tombstone.
- **Not a dependency graph.** A factory never declares what it will ask for.

## Deferring expensive async construction

There is no per-registration lazy async build. `registerAsyncSingleton` participates in phase 1, so
when `AlloyApplication.start` returns the whole async graph is up — that is the guarantee the
two-phase start exists to give.

What defers work is **lifetime**, not laziness. Put the expensive thing in a child scope and push
that scope when the feature is entered:

```dart
final session = root.push('session')
  ..registerAsyncSingleton<Telemetry>(const TelemetryFactory());
await session.init();
```

Startup never sees it, `init()` builds it when it is actually wanted, and closing the feature
disposes it. In Flutter `AlloyScopeWidget` does all of that declaratively and shows `loading` while
`init()` runs, so the wait already has a place to live. `examples/graph_events` does it by hand,
`examples/flow_scopes` through the widget.

What this does not cover: something expensive that must live as long as the app and is wanted by
only a few screens. Expressing that today means a long-lived child scope, which blurs who owns it.
That is the case a lazy async registration would be for, and it has not come up.

## One graph per isolate

Alloy is single-threaded by construction. There are no locks anywhere in the
runtime, and `AlloyResolutionTracker` — the cycle detector — is one object
shared by a whole scope tree. Nothing here is safe to touch from two isolates
at once.

In practice that is not a restriction, because a scope cannot cross an isolate
boundary anyway: it holds live objects, and only sendable values cross. So the
rule is simply that each isolate builds its own graph.

If you offload work with `Isolate.run` or `compute`, pass the *data* the work
needs, not the scope or anything resolved from it.

## Watching one subtree

Observers are fixed when a scope is built, and inherited by its children. `push` takes its own, so
a screen or a session can be watched without installing anything at startup:

```dart
final session = root.push('session', observers: [AlloyLogObserver(sink)]);
```

They are added to the inherited ones rather than replacing them, they see this scope and everything
below it and nothing beside it, and the first event they get is the push that installed them.

## When an async registration has to be made

`init()` collects the async registrations it finds when it starts, and runs once — its future is
memoized, so calling it again does not pick up anything added since. An async registration made at
or after that moment could therefore never be built, and asking for it would throw for the rest of
the scope's life. So it is refused at the point it is made:

```
Scope "app" is AlloyScopeState.active, so Database would never be built: init() takes the async
registrations it finds when it starts, and runs once. Register it before init(), or push a child
scope and initialize that.
```

The way out the message names is the ordinary one: a child scope has its own phase 1, so
`parent.push('session')`, register, `await child.init()`. Sync registrations are unaffected at any
point — they are built on demand and have no phase to miss.

## What a failed resolve tells you

A resolution that fails inside a factory names the trail that led to it, not only the key that was
missing:

```
Config is not registered in scope "app" or its ancestors. Resolving: Api -> Repository -> Config.
```

`Api` is where you start looking; `Config` alone would leave you grepping. Both
`AlloyNotRegisteredError` and `AlloyNotReadyError` carry it, as prose and as `resolving` — a list of
keys, so a report can be built from it rather than parsed out of the message.

The trail is the synchronous chain of factories on the stack. Asking from the top adds nothing,
because nothing asked. And it stops at an `await`: `Future.wait` enters every registration of an
init level before any of them suspends, so during phase 1 several branches are under construction
at once and none of them called the others. Reading that as a chain would name a caller that never
called, so an awaited build contributes nothing to the trail. The cost is a shorter trail, never a
wrong one.

## Reporting failures

`AlloyObserver` reports everything; `AlloyErrorObserver` reports only what went wrong, and brings
the events that led up to it:

```dart
final scope = await AlloyApplication.start(
  root: const AppScope(),
  observers: [AlloyErrorObserver(AlloyErrorSink.from(myReporter.capture))],
);
```

An `AlloyErrorReport` is the failing record plus its breadcrumbs, oldest first. The exception alone
says a teardown threw; the breadcrumbs say which scope had just been pushed and what it had built
by then, which is usually the part that makes the report actionable. `toStructured()` hands the
whole thing over as a map for a destination that takes structured input.

The trail is a bounded ring — 20 by default — kept at every level, including the per-instance
records `AlloyLogObserver` drops. They cost nothing until something fails.

Reports fire at `error` and above. A teardown failure arrives as a warning: it does mean a resource
leaked, but paging a paid service on every hiccup is how reports stop being read, so lowering that
is a deliberate `reportAt: AlloyLogLevel.warning`.

Only Alloy's own failures are reported — an initializer that threw, a bootstrap step that failed, a
teardown that could not finish. There is no method for reporting an arbitrary error: this is not a
general error channel.
