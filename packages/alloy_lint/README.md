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
| `alloy_dependency_is_not_registered` | an injected dependency nothing in the package registers |

All rules are warnings, so they are on by default. Every rule reads annotations through
`alloy_analyzer`, the same layer the generator uses.

## Why the graph rule reports less than the build does

Seven of the eight rules answer a question about one declaration. The eighth,
`alloy_dependency_is_not_registered`, answers one about the whole package, and the analysis
server does not offer that view: it hands a rule one library at a time, and the only synchronous
window onto the others is their **parsed**, unresolved source.

So the rule keeps its own index of every type name the package registers — `@AlloyInject` classes,
their `exposeAs` targets, `@AlloyModule` members (indexed by return type, with one `Future` layer
removed) and `@AlloyScopeRoot(provides: [...])` entries — read from syntax. It holds bare names: no
library, no type arguments, no `@Named` qualifier. Each of those omissions makes the index match
**more**, so the rule stays quiet where the build still objects:

| Case | Build | Rule |
|---|---|---|
| nothing registers `HttpClient` | error | reported |
| `@Named('audit') Logger` where only an unnamed `Logger` is registered | error | silent |
| `Repository<Order>` where only `Repository<User>` is registered | error | silent |
| two same-named classes from different libraries, one registered | error | silent |

That asymmetry is deliberate. A false report from an editor that cannot see the whole graph costs
more than a missed one, because the build is still there and is still exact. Treat the rule as the
fast path, never as the authority.

The index is rebuilt when a file in `lib` changes, and checked by modification stamp otherwise —
listing costs a stat per file, building costs a parse per file. If any file will not parse, the
rule reports nothing at all rather than mistake a skipped file for a missing registration.

Manual Mode is out of reach for the same reason it is out of reach for the generator: a
hand-written factory resolves inside `create`, and nothing static can see what it will ask for.
