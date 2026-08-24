# alloy_external_consumer

A compatibility stand, not an example. It exists to answer one question the five
packages in `examples/` cannot: **does Alloy work for a project that is not a
member of this pub workspace?**

Every example declares `resolution: workspace` and is listed in the root
`pubspec.yaml`. This package is deliberately neither, so pub resolves it on its
own, with its own `pubspec.lock` and its own `.dart_tool/package_config.json` —
the same conditions a third-party project gets.

## What it covers

One case per surface that could plausibly break from outside, not a small
application:

| Surface | Where |
|---|---|
| `@AlloyScopeRoot` | `lib/src/app_scope.dart` |
| `@AlloyBootstrap` + release on dispose | `lib/src/bind_platform.dart` |
| `@AlloyInject(exposeAs:)` | `lib/src/system_clock.dart` |
| `@AlloyInit` and `@AlloyInit(dependsOn:)` | `lib/src/database.dart`, `lib/src/search_index.dart` |
| property injection (`alloy_property_injection` + `source_gen\|combining_builder`) | `lib/src/report.dart` |
| generic dependencies | `lib/src/repository.dart` |

`lib/alloy.g.dart` is committed and verified by `git diff --exit-code` in CI,
the same way `examples/codegen_basics` is.

## What it does not prove

The source of the packages is substituted by `dependency_overrides`, because
nothing is published yet. So this stand proves that the builders apply and the
generated container works **outside the workspace** — it does not prove
resolution from pub.dev. Only a real publish does that.

## Two findings from building it

**1. The builders need nothing special.** All three are `auto_apply: dependents`,
and `AlloyContainerBuilder` collects IR with a package-scoped
`findAssets(Glob('lib/**.alloy.json'))`. Declaring `alloy_generator` in
`dev_dependencies` is the whole setup. This worked on the first run.

**2. The lint plugin does not read this package's pubspec.** The analysis server
builds a synthetic `plugin_entrypoint` package and runs `pub upgrade` on it
against pub.dev; `dependency_overrides` in `pubspec.yaml` are invisible to it.
Against unpublished packages that fails outright:

```
Because plugin_entrypoint depends on alloy_lint any which doesn't exist
(could not find package alloy_lint at https://pub.dev), version solving failed.
```

Hence the `dependency_overrides` block inside `analysis_options.yaml` — the same
scaffolding the repository root uses. A consumer of a *published* `alloy_lint`
writes only the `plugins:` entry and needs none of it.

## Running it

```bash
dart pub get
dart run build_runner build
dart test
dart analyze .
```
