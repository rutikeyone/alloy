"""The packages whose declared floor the running Dart satisfies.

Printed as one line for tool/floor_check.sh to loop over. A package that asks
for more than the SDK in hand is not a failure — it is a package this run has
nothing to say about, and saying so is the difference between a check that is
honest about its coverage and one that quietly shrinks.
"""

import pathlib
import re
import sys


def floor_of(pubspec: pathlib.Path) -> tuple[int, ...] | None:
  for line in pubspec.read_text().splitlines():
    found = re.match(r'^  sdk: \^?([0-9]+)\.([0-9]+)\.([0-9]+)', line)
    if found:
      return tuple(int(part) for part in found.groups())
  return None


def main() -> int:
  root = pathlib.Path(sys.argv[1])
  running = tuple(int(part) for part in sys.argv[2].split('.'))

  selected = [
    package
    for package in sys.argv[3:]
    if (floor := floor_of(root / 'packages' / package / 'pubspec.yaml')) is not None
    and floor <= running
  ]

  print(' '.join(selected))
  return 0


if __name__ == '__main__':
  raise SystemExit(main())
