## 0.1.0

- Initial release.
- An `analysis_server_plugin` (not `custom_lint`, which is pinned to an
  incompatible analyzer) with seven warning rules, all reading annotations
  through `alloy_analyzer` — the same layer the generator uses.
- Rules cover: an injectable that cannot be constructed, `@injected` fields
  that are not `late final`, a missing injection mixin, `@AlloyInit` without an
  `init` method, `@AlloyBootstrap` without a `run` method, a bootstrap step
  taking injected parameters, and `@AlloyEnvironment` on a class nothing
  registers.
- The analysis server resolves plugins from pub.dev rather than from your
  pubspec, so a `dependency_override` in `pubspec.yaml` does not affect which
  version loads. See the README for pointing it at local sources.
