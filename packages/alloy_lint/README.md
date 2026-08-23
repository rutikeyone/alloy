# alloy_lint

Analyzer plugin with lint rules for [Alloy](https://github.com/rutikeyone/alloy). It surfaces
invalid annotations in the IDE instead of only when `build_runner` runs.

```yaml
plugins:
  alloy_lint: ^0.1.0
```

The `plugins` section only works at the root of a package or workspace — a nested
`analysis_options.yaml` is silently ignored, and `dart analyze <nested/dir>` will not apply it.

The plugin is resolved **from pub.dev, not from your pubspec**. The analysis server builds its own
`plugin_entrypoint` package and runs `pub upgrade` on it, so a `dependency_override` in your
`pubspec.yaml` has no effect on which `alloy_lint` gets loaded. To point the server at local
sources — the only option against unpublished packages — name them inside the `plugins` section
itself:

```yaml
plugins:
  alloy_lint:
    path: ../packages/alloy_lint
  dependency_overrides:
    alloy_lint:
      path: ../packages/alloy_lint
    alloy_analyzer:
      path: ../packages/alloy_analyzer
```

## Rules

| Rule | Catches |
|---|---|
| `alloy_missing_injection_mixin` | `@injected` fields without `with _$ClassName` |
| `alloy_injected_field_must_be_late_final` | `@injected` on a mutable, non-late or static field |
| `alloy_injectable_must_be_constructible` | `@AlloyInject` on an abstract class or one with no public generative constructor |
| `alloy_init_requires_init_method` | `@AlloyInit` on a class with no `init()` |
| `alloy_bootstrap_requires_run_method` | `@AlloyBootstrap` on a class with no `run()` |
| `alloy_bootstrap_step_cannot_inject` | a bootstrap step whose constructor takes required parameters |
| `alloy_environment_needs_a_registration` | `@AlloyEnvironment` on a class nothing registers, where it silently does nothing |

All rules are warnings, so they are on by default. Every rule reads annotations through
`alloy_analyzer`, the same layer the generator uses.
