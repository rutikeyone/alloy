## 0.1.0

- A nullable `@AlloyParam` keeps its `?` in the generated record. It used to
  be dropped, narrowing an argument the constructor was willing to take as
  null.
- A module member may take named parameters. They were refused because the
  emitter passed everything positionally; it no longer does. An optional
  parameter is still refused, for the reason it always was.
- A class with `@AlloyParam` parameters is generated as a parameterized
  factory, with a named record type emitted beside the container. Marked
  parameters are not dependencies: they are skipped by the completeness check
  and are no edge in the ordering.
- Constructors with named parameters are called the way they were declared.
  Every argument used to go in positionally, producing a file that did not
  compile.
- The `_$ClassName` injection mixin is written for every class the container
  registers, `@AlloyInit` included. Such a class used to be registered and left
  with its `@injected` fields unassigned.
- `@AlloyInit(dependsOn:)` naming a registration that is not itself `@AlloyInit`
  fails the build, listing every such edge at once.
- Two libraries in one package declaring classes of the same name no longer emit
  two factories of the same name. Every claimant of a contested base name gets a
  suffix from its own library; uncontested names are untouched, so the fix
  renames nothing in an existing file.
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
