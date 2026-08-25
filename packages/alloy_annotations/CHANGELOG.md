## 0.1.0

- Initial release.
- Annotations shared by the generator and the lint plugin, with no runtime and
  no analyzer dependency: `@AlloyInject` (plus the `@alloyInject` /
  `@alloySingleton` / `@alloyTransient` shorthands), `@Injected`, `@Named`,
  `@AlloyBootstrap`, `@AlloyInit`, `@AlloyScopeRoot` and `@AlloyEnvironment`.
- `AlloyEnvironment.matches` lives here rather than in the runtime: it is pure
  logic over strings, and both generated and hand-written code need it.
- `@AlloyScopeRoot(provides: [...])` and `AlloyProvided` declare registrations
  the generator cannot see, so its completeness check does not report them
  missing.
