# alloy_generator

Code generator for [Alloy](https://github.com/rutikeyone/alloy). Add it as a `dev_dependency` — it
never ships in an application.

```yaml
dev_dependencies:
  alloy_generator: ^0.1.0
  build_runner: ^2.16.0
```

```
dart run build_runner build
```

## Builders

| Builder | Input → output | Purpose |
|---|---|---|
| `alloy_property_injection` | `.dart` → `.alloy.g.part` | mixins that fill `late final` fields |
| `alloy_scan` | `.dart` → `.alloy.json` | per-library IR, cached |
| `alloy_container` | `$lib$` → `lib/alloy.g.dart` | the container, bootstrap list and `$startAlloy()` |

A build step can only see one library at a time, so `alloy_scan` writes a per-library IR and
`alloy_container` aggregates every `.alloy.json` into a single container.

Generated registrations are ordered by a compile-time topological sort, and property-injected
fields count as dependency edges. A dependency cycle fails the build naming the cycle instead of
emitting code that would deadlock at runtime.

## Registering types you did not write

`@AlloyInject` goes on a class, so it only reaches classes you own. A module is
the way in for everything else — a client from another package, a value the SDK
hands you, an object built by a factory function:

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

The annotation carries nothing. Every member configures its own registration
with the same annotations a class uses, so lifetimes, `@Named`, `exposeAs` and
`@AlloyEnvironment` all work unchanged, and each member's parameters are
resolved from the scope like constructor parameters.

The class needs a public `const` constructor taking no arguments — the emitted
factory holds `const NetworkModule()`, so it allocates nothing and carries no
state. Members must be public instance members taking only positional
parameters.

**`Future<T>` is the only async signal.** A member returning it registers `T`
as an async singleton built during startup; there is no `@AlloyInit` on a
member, because the return type already says it. Ordering between async members
is **worked out, not written**: the generator sees the whole package, so it
emits the `dependsOn` a hand-written registration would have stated.

**A member cannot be abstract.** "Build it from its own constructor" is what
`@AlloyInject` on the class already means, and publishing it under an interface
is what `exposeAs` means.

**`dispose` is how a foreign type gets closed.** The scope owns what it builds,
but a type from another package implements neither `Disposable` nor
`AsyncDisposable`, so it cannot say how to close itself. Point `dispose` at a
top-level or static function taking the registered type and the scope calls it
at teardown, in the same reverse-creation order as everything else. Pairing it
with a transient is a build error: the scope does not retain a transient, so it
could never call it.

## A missing registration is a build failure

Every dependency the container resolves — constructor parameters, `@injected` fields and
`@AlloyInit(dependsOn:)` — has to be registered by something, or the build fails:

```
Diagnostics requires DeviceInfo, which nothing registers. Annotate the class that
provides it with @AlloyInject, add an @AlloyModule member returning it when the
type is not yours, or name it in @AlloyScopeRoot(provides: [...]) when something
outside the generated container registers it.
```

All gaps are reported together, so a graph is fixed in one pass rather than one rebuild per
missing type. A `@Named('audit')` dependency with only an unnamed registration counts as a gap:
the qualifier is part of the key.

**Registrations made by hand have to be declared.** A module covers types you do not own; this is
for registrations the generator cannot see at all — a scope builder that wraps `$AlloyRootScope`
and adds to it, or a provider from another package. Name those in the root:

```dart
@AlloyScopeRoot(name: 'app', provides: [SessionManager])
class AppScope {
  const AppScope();
}
```

Nothing is emitted for a promise; it only stops the build from failing. Use
`AlloyProvided(Logger, name: 'audit')` in the same list when the hand-written registration is
named.

**Environments are checked one at a time.** A registration restricted to `prod` is absent from
`dev`, so a dependent that is not equally restricted fails naming where the gap is (`in dev`).
Only the environments the package declares are considered — `default` joins them only when there
are none, because starting a split graph without choosing one is deliberately a runtime failure
(see the environments section of the root README). A custom `AlloyEnvironment.matches` override is
not modelled.

**Manual Mode is not covered.** A hand-written `AlloyFactory` resolves inside `create`, and nothing
static can see what it will ask for. Registrations written by hand still fail at runtime with
`AlloyNotRegisteredError`, exactly as before.

## Generic types

`Repository<User>` and `Repository<Order>` are two separate registrations — as dependencies and as
`exposeAs` targets alike. The identity of a registration includes its type arguments, matching the
runtime, where `AlloyKey` is built from `Type`.

The injectable class itself may not be generic. `@AlloyInject class Cache<T>` is rejected at build
time, because nothing says which instantiations to register. Annotate a concrete subtype, or expose
one with `@AlloyInject(exposeAs: Cache<Note>)`.

Nullability is not part of that identity: a `Foo?` dependency reads the `Foo` registration. What it
does change is whether the dependency is required. A nullable parameter or `@injected` field is
emitted as `resolver.getOrNull<Foo>()` and is skipped by the completeness check, so nothing
registering `Foo` injects null rather than failing the build. It stays an ordering edge when `Foo`
*is* registered, and `@AlloyInit(dependsOn:)` is never optional — it declares order, not injection.

A module member may not return a nullable type. A nullable type marks a dependency optional; it
cannot describe a registration, because `AlloyKey` has no way to represent `Foo?`.

## Two classes with the same name

A generated factory is named after what declares the registration — `_ClockFactory` for `Clock`,
`_NetworkModuleDioFactory` for a module member — which handles two modules both providing a `Dio`.

Two libraries in one package declaring their own `Clock` is different: the build accepts both,
because a registration key is `import#name` and those are two distinct keys. Emitting
`_ClockFactory` twice would produce a file that does not compile, and the error would name the
generated symbol rather than either class you wrote.

So a base name more than one declaration claims gets a suffix on **every** claimant, derived from
the library it came from: `_ClockFactory$329` and `_ClockFactory$700`. Two properties follow, and
both are on purpose — a name nobody contests is left exactly as it was, so adding a second `Clock`
never renames anything else in the file; and the suffix is a function of the library alone, so it
does not depend on visit order and does not move between builds.
