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

## Generic types

`Repository<User>` and `Repository<Order>` are two separate registrations — as dependencies and as
`exposeAs` targets alike. The identity of a registration includes its type arguments, matching the
runtime, where `AlloyKey` is built from `Type`.

The injectable class itself may not be generic. `@AlloyInject class Cache<T>` is rejected at build
time, because nothing says which instantiations to register. Annotate a concrete subtype, or expose
one with `@AlloyInject(exposeAs: Cache<Note>)`.

Nullability is not part of that identity: a `Foo?` dependency reads the `Foo` registration. There
is no optional-dependency support yet — a missing registration is an error, not a `null`.
