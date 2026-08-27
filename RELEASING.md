# Releasing

Thirteen packages depend on each other, so the order is not a preference — a package
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
4. alloy_generator            (alloy_analyzer, alloy_annotations)
   alloy_lint                 (alloy_analyzer)
   alloy_go_router            (alloy_flutter)
   alloy_inspector            (alloy_flutter)
alloy_talker_flutter       (alloy_inspector, alloy_talker)
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
- [ ] Translations updated. `README.ru.md`, `README.zh-CN.md`, `MIGRATION.ru.md` and
      `MIGRATION.zh-CN.md` track the English originals; nothing checks that they
      still say the same thing, so this box is the only thing that does. English
      is authoritative — if a translation is stale, fix it or say so in it.

## Versioning

Lockstep: every package carries the same version. A DI framework whose runtime
and generator drift apart produces generation errors nobody can decipher, so the
constraint between them (`^0.1.0`) is deliberately tight.

Lockstep is the whole policy, including the awkward cases:

- **A breaking change anywhere majors everything.** `alloy_talker` gets a new
  major even if not one line of it changed. The cost is a meaningless version
  bump; the alternative cost is a user resolving `alloy 2.x` against
  `alloy_talker 1.x` and reading a generator error that names neither.
- **A fix in one package still ships as a patch for all ten.** Publishing a
  subset is what lets the set drift.
- **The dependency constraint between our own packages stays exact-major**
  (`^X.Y.0`), never `>=X <Z`. Widening it is the same trap in slower motion.

Before 1.0, `0.x` majors mean `0.x` — a breaking change bumps the minor, so
`^0.1.0` already refuses `0.2.0`. That is the behaviour we want; it just looks
different from what the rule above describes.

## Flutter and Dart versions

Every package requires Dart `^3.13.0`, which no Flutter below **3.47** ships.
The two Flutter packages say so directly (`flutter: ">=3.47.0"`); the pure-Dart
ones do not mention Flutter at all. There is no version spread to document and
none to test against — CI runs `stable` and `beta` instead, so an upcoming
Flutter change is found before it is released rather than after.

Lowering that floor is possible for `alloy` and `alloy_annotations`, which are
plain Dart. It is not possible for `alloy_analyzer`, `alloy_generator` and
`alloy_lint`, which track the current analyzer.

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

Measured 2026-08-27: `alloy_annotations` scores **160/160**, with all six platforms detected and
`is:wasm-ready`, without declaring a `platforms:` key. Two things follow, and both save work:
declaring platforms by hand buys nothing here and can only contradict what the analysis finds; and
the documentation criterion is *20% or more* of the public API, not all of it, so chasing complete
dartdoc coverage is a matter of taste rather than of score.

## Lower bounds

`pana` also checks that a package resolves and analyses at the bottom of its own constraints.
That one is runnable locally against the whole workspace:

```bash
flutter pub downgrade && dart analyze --fatal-infos .
flutter pub get
```

Measured 2026-08-27: clean. The test *runner* cannot run down there — `frontend_server_client`
resolves to 3.2.0, which invokes a `frontend_server.dart.snapshot` that Dart 3.13 no longer ships —
but that is a transitive dev dependency nothing here declares, and it is invisible to consumers,
who never run these tests.

## `alloy` dev-depends on `alloy_test`

Its own tests use the helpers, which looks like a cycle and is not: dev dependencies are not
transitive, so nothing a consumer resolves is affected, and `pub publish --dry-run` is clean. The
publication order below is unchanged — `alloy` goes out before `alloy_test`, and the dev dependency
plays no part in that.
