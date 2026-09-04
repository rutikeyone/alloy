## 0.1.0

- An optional `@CobaltParam` parameter is refused: the record the call site
  passes carries no defaults, so the default could never be used.
- `@CobaltParam` marks a constructor parameter the call site supplies rather
  than the graph.
- Initial release.
- Annotations shared by the generator and the lint plugin, with no runtime and
  no analyzer dependency: `@CobaltInject` (plus the `@cobaltInject` /
  `@cobaltSingleton` / `@cobaltTransient` shorthands), `@Injected`, `@Named`,
  `@CobaltBootstrap`, `@CobaltInit`, `@CobaltScopeRoot` and `@CobaltEnvironment`.
- `CobaltEnvironment.matches` lives here rather than in the runtime: it is pure
  logic over strings, and both generated and hand-written code need it.
- `@CobaltScopeRoot(provides: [...])` and `CobaltProvided` declare registrations
  the generator cannot see, so its completeness check does not report them
  missing.
- `@CobaltModule` marks a class whose members register types the package does
  not own, and `@CobaltInject` gained `dispose` for closing them.
