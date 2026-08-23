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

## Versioning

Lockstep: every package carries the same version. A DI framework whose runtime
and generator drift apart produces generation errors nobody can decipher, so the
constraint between them (`^0.1.0`) is deliberately tight.

## After publishing

`alloy_lint` becomes installable the normal way — just the `plugins:` entry.
Until then the analysis server cannot find it, because it resolves plugins from
pub.dev rather than from the consumer's pubspec, which is why
`compat/external_consumer/analysis_options.yaml` names local paths. Drop that
block once the packages are live, and the stand starts proving the real
installation path too.
