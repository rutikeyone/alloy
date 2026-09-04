"""Points a copied-out package set at itself by path, for tool/floor_check.sh.

None of these packages exist on pub.dev yet, so a plain `pub get` outside the
workspace looks for the first sibling there and stops. `dependency_overrides`
is the only way to say "use the copy next door" before publication — the same
trick `compat/external_consumer` uses.

Two mistakes are easy here and both were made before this was written:

* overriding *everything* puts `cobalt_analyzer` into resolutions that never ask
  for it, and those then fail on constraints that have nothing to do with the
  package under test;
* overriding only the *direct* names is not enough, because an override has to
  cover every unpublished package in the resolution — `cobalt_flutter` reaches
  `cobalt_annotations` only through `cobalt`.

So: the transitive closure of what each package actually names, and nothing
else.
"""

import pathlib
import re
import sys


def main() -> int:
  work = pathlib.Path(sys.argv[1])
  # `name=path` pairs: the copies keep the layout they have in the repository,
  # so a package that reaches outside itself — `cobalt_lint/test` includes the
  # root analysis options — finds the same thing at the same depth.
  where = dict(member.split('=', 1) for member in sys.argv[2:])
  packages = list(where)

  def named_by(package: str) -> set[str]:
    text = (work / where[package] / 'pubspec.yaml').read_text()
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

    # `cobalt` dev-depends on `cobalt_test`, which depends on `cobalt`. Legal —
    # dev dependencies are not transitive — but the closure walks straight back
    # round it, and pub refuses a package that lists itself.
    reachable.discard(package)

    pubspec = work / where[package] / 'pubspec.yaml'
    text = re.sub(
      r'^resolution: workspace\n', '', pubspec.read_text(), flags=re.M
    )
    # The compatibility stand already overrides these, at paths relative to
    # where it normally sits. Its copy sits somewhere else, so the block is
    # replaced rather than added to — two `dependency_overrides:` keys are not
    # a merge, they are invalid YAML.
    text = re.sub(
      r'^dependency_overrides:\n(?:  .*\n|\n)*', '', text, flags=re.M
    )
    overrides = ''.join(
      f'  {name}: {{path: {work}/{where[name]}}}\n' for name in sorted(reachable)
    )
    pubspec.write_text(f'{text.rstrip(chr(10))}\ndependency_overrides:\n{overrides}')

  return 0


if __name__ == '__main__':
  raise SystemExit(main())
