## 0.1.0

- `alloy_injected_field_needs_an_injectable` reports `@injected` on a class the
  container never registers, where no mixin is generated and
  `alloy_missing_injection_mixin` would have sent you to a name that does not
  exist. That rule now stays quiet there.
- Initial release.
- An `analysis_server_plugin` (not `custom_lint`, which is pinned to an
  incompatible analyzer) with nine warning rules, all reading annotations
  through `alloy_analyzer` — the same layer the generator uses.
- `alloy_dependency_is_not_registered` and `alloy_dependency_cycle` answer
  whole-package questions the analysis server does not offer a view for, from a
  shared syntactic index of what the package registers and what each
  registration asks for. Both match on bare names, so they stay silent where
  the build still objects; see the README for the cases and why they fall that
  way. The cycle rule additionally drops any name two declarations both claim,
  because fusing two same-named types is how a graph with no loop grows one.
- Rules cover: an injectable that cannot be constructed, `@injected` fields
  that are not `late final`, a missing injection mixin, `@AlloyInit` without an
  `init` method, `@AlloyBootstrap` without a `run` method, a bootstrap step
  taking injected parameters, and `@AlloyEnvironment` on a class nothing
  registers.
- The analysis server resolves plugins from pub.dev rather than from your
  pubspec, so a `dependency_override` in `pubspec.yaml` does not affect which
  version loads. See the README for pointing it at local sources.
- The registration index reads `@AlloyModule` members too, so a graph using
  modules does not produce false reports.
- `alloy_dependency_is_not_registered` skips optional dependencies. It walks
  them as a list rather than a set, because `AlloyTypeRef` compares by
  signature and would otherwise fold `Foo` and `Foo?` into one entry.
