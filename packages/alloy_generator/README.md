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

## A missing registration is a build failure

Every dependency the container resolves — constructor parameters, `@injected` fields and
`@AlloyInit(dependsOn:)` — has to be registered by something, or the build fails:

```
Diagnostics requires DeviceInfo, which nothing registers. Annotate the class that
provides it with @AlloyInject, or name it in @AlloyScopeRoot(provides: [...]) when
something outside the generated container registers it.
```

All gaps are reported together, so a graph is fixed in one pass rather than one rebuild per
missing type. A `@Named('audit')` dependency with only an unnamed registration counts as a gap:
the qualifier is part of the key.

**Registrations made by hand have to be declared.** The container only sees this package's
annotations, so a scope builder that wraps `$AlloyRootScope` and adds to it — or a provider from
another package — is invisible to the check. Name those in the root:

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

Nullability is not part of that identity: a `Foo?` dependency reads the `Foo` registration. There
is no optional-dependency support yet — a missing registration is an error, not a `null`.
