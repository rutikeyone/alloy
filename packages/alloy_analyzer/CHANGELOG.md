## 0.1.0

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
