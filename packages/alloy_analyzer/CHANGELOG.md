## 0.1.0

- Requires Dart `^3.10.0` — Flutter 3.38 — instead of `^3.13.0`, and moves
  `analyzer` to `>=10.0.1 <13.0.0`. A Flutter 3.38 application cannot resolve
  past 10.0.1, because Flutter pins `meta 1.17.0` there; everything else takes
  12.1.0. This package reads only the element model, which does not change
  across that range.

- Initial release.
- One parsing layer over `analyzer`, shared by `alloy_generator` and
  `alloy_lint` so the IDE and the build agree on what a declaration means.
- Typed IR — `AlloyInjectableClass`, `AlloyBootstrapStepClass`,
  `AlloyScopeRootClass`, `AlloyTypeRef` — with JSON round-tripping, which is
  what makes the generator's two-phase pipeline possible.
- `AlloyTypeRef.signature` is the single definition of registration identity:
  type arguments are part of it, nullability is not.
- Annotations are matched by class name and owning package rather than by exact
  library path, so moving a declaration inside `alloy_annotations` does not
  break consumers, and test stubs still resolve.
- `AlloyScopeRootClass.provides` carries the registrations a package makes by
  hand, as `AlloyProvidedRef` pairs of type and optional name. IR written before
  the field existed still reads.
- `AlloyModuleParser` reads an `@AlloyModule` class into one registration per
  member — the only parser that is one-to-many. A member returning `Future<T>`
  registers `T`.
