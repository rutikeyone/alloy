# Releasing

Ten packages depend on each other, so the order is not a preference — a package
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
4. alloy_generator            (alloy_analyzer, alloy_annotations)
   alloy_lint                 (alloy_analyzer)
   alloy_go_router            (alloy_flutter)
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
