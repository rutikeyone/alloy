## 0.1.0

- Initial release.
- Three builders: `alloy_property_injection` (per-file mixins via
  `SharedPartBuilder`), `alloy_scan` (per-library IR to `.alloy.json`, cached)
  and `alloy_container` (aggregates every IR into `lib/alloy.g.dart`).
  All are `auto_apply: dependents` — declaring the dev dependency is the setup.
- Emits named const factory classes, never closures, and orders registrations
  by a compile-time topological sort in which property-injected fields count as
  dependency edges.
- Import aliases come from a hash of the URL, so adding one import does not
  renumber the rest and produce a whole-file diff.
- Rejects a graph with a dependency nothing registers, listing every gap in one
  message and checking each environment separately. Registrations made by hand
  are declared through `@AlloyScopeRoot(provides: [...])`.
- Rejects at build time what would otherwise be silent: a dependency cycle, two
  registrations of one key whose environments overlap, and `@AlloyInject` on a
  class with type parameters.
- Generic types work as dependencies and as `exposeAs` targets:
  `Repository<User>` and `Repository<Order>` are separate registrations.
- Emits factories for `@AlloyModule` members, calling the member on a const
  module instance. Async ordering between module members is derived from the
  graph rather than declared.
- A nullable dependency is optional: it is emitted as `getOrNull` and skipped
  by the completeness check, while still ordering registration when the type
  is present. `@AlloyInit(dependsOn:)` is never optional, and a module member
  may not return a nullable type.
