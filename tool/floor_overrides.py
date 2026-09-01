"""Points a copied-out package set at itself by path, for tool/floor_check.sh.

None of these packages exist on pub.dev yet, so a plain `pub get` outside the
workspace looks for the first sibling there and stops. `dependency_overrides`
is the only way to say "use the copy next door" before publication — the same
trick `compat/external_consumer` uses.

Two mistakes are easy here and both were made before this was written:

* overriding *everything* puts `alloy_analyzer` into resolutions that never ask
  for it, and those then fail on constraints that have nothing to do with the
  package under test;
* overriding only the *direct* names is not enough, because an override has to
  cover every unpublished package in the resolution — `alloy_flutter` reaches
  `alloy_annotations` only through `alloy`.

So: the transitive closure of what each package actually names, and nothing
else.
"""

import pathlib
import re
import sys


def main() -> int:
  work = pathlib.Path(sys.argv[1])
  packages = sys.argv[2:]

  def named_by(package: str) -> set[str]:
    text = (work / package / 'pubspec.yaml').read_text()
    return {
      other
      for other in packages
      if other != package and re.search(rf'^  {other}:', text, flags=re.M)
    }

  direct = {package: named_by(package) for package in packages}

  for package in packages:
    reachable = set(direct[package])
    while True:
      grown = reachable | {n for r in reachable for n in direct[r]}
      if grown == reachable:
        break
      reachable = grown

    # `alloy` dev-depends on `alloy_test`, which depends on `alloy`. Legal —
    # dev dependencies are not transitive — but the closure walks straight back
    # round it, and pub refuses a package that lists itself.
    reachable.discard(package)

    pubspec = work / package / 'pubspec.yaml'
    text = re.sub(
      r'^resolution: workspace\n', '', pubspec.read_text(), flags=re.M
    )
    overrides = ''.join(
      f'  {name}: {{path: {work}/{name}}}\n' for name in sorted(reachable)
    )
    pubspec.write_text(f'{text.rstrip(chr(10))}\ndependency_overrides:\n{overrides}')

  return 0


if __name__ == '__main__':
  raise SystemExit(main())
