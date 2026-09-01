# Releasing

Fifteen packages depend on each other, so the order is not a preference — a package
cannot be published until everything it depends on is already on pub.dev, or
version solving fails.

## Order

```
1. alloy_annotations          (depends on nothing of ours)
2. alloy                      (alloy_annotations)
3. alloy_analyzer             (alloy, alloy_annotations)
   alloy_flutter              (alloy)
   alloy_logger               (alloy)
   alloy_logging              (alloy)
   alloy_talker               (alloy)
   alloy_test                 (alloy)
   alloy_bloc                 (alloy)
4. alloy_generator            (alloy_analyzer, alloy_annotations)
   alloy_lint                 (alloy_analyzer)
   alloy_go_router            (alloy_flutter)
   alloy_inspector            (alloy_flutter)
   alloy_test_flutter         (alloy_flutter)
5. alloy_talker_flutter       (alloy_inspector, alloy_talker)
```

Steps within a numbered group are independent of each other. Between groups,
wait for the previous group to appear on pub.dev — the index is not instant.

## Before the first publish

- [ ] Working copy is under git and clean. Without it `pub publish` ignores
      `.gitignore` and puts `build/` — tens of megabytes — into the archive.
- [ ] `dart pub publish --dry-run` in every package. Expect **0 warnings**
      everywhere except `alloy_lint`, which reports one for `lib/main.dart`;
      that name is required by the plugin API and `riverpod_lint` carries the
      same warning.
- [ ] Archives are kilobytes, not megabytes. Anything larger means the previous
      two boxes are not really ticked.
- [ ] `repository:` and `issue_tracker:` point at a repository that actually
      exists and has the code pushed. They are currently
      `github.com/rutikeyone/alloy`.
- [ ] CI is green on that repository.
- [ ] Translations updated. `README.ru.md`, `README.zh-CN.md`, the four
      translated guides, `MIGRATION.ru.md` and `MIGRATION.zh-CN.md` track the
      English originals; a test checks that all four sets exist and link to each
      other, and CI checks they are not empty, but nothing checks that they still
      say the same thing — so this box is the only thing that does. English is
      authoritative: if a translation is stale, fix it or say so in it.
- [ ] Code in both guides still compiles against the API it describes. It is the
      document a new reader copies from, and the two defects this repository has
      already shipped in prose — `AlloyInspectorScreen` without its required
      `scope:`, `AlloyLoggerSink` called positionally — were both in example
      snippets, which no compiler reads. Check the API of anything you changed
      this release.
- [ ] After publishing, put the plugin back where it belongs. `alloy_lint` is
      enabled from `analysis_options.plugin.yaml` rather than from
      `analysis_options.yaml`, in the repository root and in
      `compat/external_consumer`, because the analysis server resolves a
      synthetic plugin package against pub.dev and that fails while ours are
      unpublished. Once they are not, delete both `*.plugin.yaml`, put a plain
      `plugins: alloy_lint: ^x.y.z` in each `analysis_options.yaml`, and drop
      the `dependency_overrides`. Only then does the stand prove the ordinary
      installation, which today cannot be checked at all.
- [ ] **Shipped strings** translated too, which is a different job from the
      documents above: `packages/alloy_inspector/l10n/*.arb` and the examples'
      — `gallery`, `notes_app`, `flow_scopes`, `graph_events` and
      `codegen_basics` each carry their own. A test in each package fails when a key is
      missing from a translation, so a *gap* cannot slip through — but a key
      whose English changed while the translations kept the old wording passes
      every check there is. Re-read the diff of `*_en.arb`, then
      `flutter gen-l10n` and commit the output; CI regenerates and fails on any
      difference.

## Versioning

Lockstep: every package carries the same version. A DI framework whose runtime
and generator drift apart produces generation errors nobody can decipher, so the
constraint between them (`^0.1.0`) is deliberately tight.

Lockstep is the whole policy, including the awkward cases:

- **A breaking change anywhere majors everything.** `alloy_talker` gets a new
  major even if not one line of it changed. The cost is a meaningless version
  bump; the alternative cost is a user resolving `alloy 2.x` against
  `alloy_talker 1.x` and reading a generator error that names neither.
- **A fix in one package still ships as a patch for all fifteen.** Publishing a
  subset is what lets the set drift.
- **The dependency constraint between our own packages stays exact-major**
  (`^X.Y.0`), never `>=X <Z`. Widening it is the same trap in slower motion.

Before 1.0, `0.x` majors mean `0.x` — a breaking change bumps the minor, so
`^0.1.0` already refuses `0.2.0`. That is the behaviour we want; it just looks
different from what the rule above describes.

A test enforces the mechanical half of this: every package declares the same
version, and every changelog heads with the version its own pubspec declares.
Bumping a release is fifteen identical edits, and the one you miss is not
visible in a diff you are scrolling past.

## Flutter and Dart versions

There are two floors, deliberately.

**The twelve runtime packages** require Dart `^3.10.0`, and the five that need
Flutter say `>=3.38.0`. **The three toolchain packages** — `alloy_analyzer`,
`alloy_generator`, `alloy_lint` — require Dart `^3.13.0`.

The split is measured, not cautious. Below Dart 3.11 the parser stops seeing
`@AlloyParam` on constructor parameters, and `alloy_lint` does not compile at
all: `FormalParameter.type`, `NamedArgument` and `Folder.getFolder` arrived in
analyzer 13, which needs `_fe_analyzer_shared 100`, which needs Dart 3.11. A
generator that reads an annotation wrong is worse than one that refuses to
resolve, so the toolchain stays where it is verified.

What that buys: an application still on Flutter 3.38 can adopt Manual Mode now
and take the generator when it upgrades, losing nothing in between.

`tool/floor_check.sh` proves both floors. It copies each package out of the
workspace and resolves it alone, because a workspace is one resolution and this
one cannot exist on 3.38 — `flutter_test` there pins `test_api 0.7.7`, capping
the `test` runner at 1.26.3 and `analyzer` below 9. Consumers never meet that;
we do, because our analyzer packages and the test runner share a resolution.
Packages declaring a floor above the running SDK are skipped, named, and not
counted as passing.

CI runs it pinned to Flutter 3.38.9 alongside `stable` and `beta`, so an
upcoming Flutter change is found before release and the old floor cannot rot
unnoticed.

Raising a floor later is a breaking change; lowering one is not. That asymmetry
is why this was settled before the first publish rather than after.

## After publishing

`alloy_lint` becomes installable the normal way — just the `plugins:` entry.
Until then the analysis server cannot find it, because it resolves plugins from
pub.dev rather than from the consumer's pubspec, which is why
`compat/external_consumer/analysis_options.yaml` names local paths. Drop that
block once the packages are live, and the stand starts proving the real
installation path too.

## What `pana` can and cannot tell you before the first publish

`pana` resolves against pub.dev and strips `dependency_overrides`, so it scores a package only once
everything it depends on is published. Before the first release that means exactly one package can
be measured — `alloy_annotations`, whose only dependency is `meta` — and each later one becomes
measurable as the one below it lands. Run it as you go rather than saving it for the end:

```bash
dart pub global activate pana
(cd packages/alloy_annotations && dart pub global run pana --no-warning .)
```

Measured 2026-09-01: `alloy_annotations` scores **160/160**, with all six platforms detected and
`is:wasm-ready`, without declaring a `platforms:` key. Two things follow, and both save work:
declaring platforms by hand buys nothing here and can only contradict what the analysis finds; and
the documentation criterion is *20% or more* of the public API, not all of it, so chasing complete
dartdoc coverage is a matter of taste rather than of score.

## Lower bounds

`pana` also checks that a package resolves and analyses at the bottom of its own constraints.
That one is runnable locally against the whole workspace:

```bash
flutter pub downgrade && dart analyze --fatal-infos .
flutter pub upgrade
```

Measured 2026-09-01: clean, with 92 packages moved — including `bloc` at its floor of 9.0.0, which
`alloy_bloc` is the only thing to constrain and which nothing had resolved before.

Restore with `pub upgrade`, never `pub get`: `get` honours the existing lockfile and leaves
`frontend_server_client` downgraded, and that version invokes a `frontend_server.dart.snapshot` Dart
3.13 no longer ships. The symptom is not an error — `dart analyze` stays green while every test file
silently fails to load.

That same downgraded package is why the test *runner* cannot run at the lower bounds at all. It is a
transitive dev dependency nothing here declares, invisible to consumers, who never run these tests —
so `dart analyze` is the whole of the check, and it is also the whole of what `pana` scores.

## `alloy` dev-depends on `alloy_test`

Its own tests use the helpers, which looks like a cycle and is not: dev dependencies are not
transitive, so nothing a consumer resolves is affected, and `pub publish --dry-run` is clean. The
publication order below is unchanged — `alloy` goes out before `alloy_test`, and the dev dependency
plays no part in that.
