#!/usr/bin/env sh
# Proves the declared floor: every package resolves, analyses and tests on the
# oldest SDK it claims to support.
#
# It copies the packages out of the workspace first, and that is the whole
# reason this script exists rather than a few lines in CI. A workspace is one
# resolution, and this one cannot exist on the old SDK: `flutter_test` there
# pins `test_api 0.7.7`, which caps the `test` runner at 1.26.3, which caps
# `analyzer` below 9 — while `alloy_analyzer` needs 12 or better. A consumer
# never meets that, because a consumer does not have the `test` runner sitting
# in the same resolution as our analyzer packages. We do. So each package is
# resolved on its own, which is also what pub.dev does when it scores them.
#
# Run it with the old SDK first on PATH:
#
#   PATH="$HOME/Flutter/Sdk/flutter_3_38_9_version/flutter/bin:$PATH" ./tool/floor_check.sh
set -e
cd "$(dirname "$0")/.."

ROOT=$PWD
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

DART_PACKAGES="alloy_annotations alloy alloy_bloc alloy_talker alloy_logging alloy_logger alloy_test alloy_analyzer alloy_generator alloy_lint"
FLUTTER_PACKAGES="alloy_flutter alloy_go_router alloy_inspector alloy_talker_flutter alloy_test_flutter"

echo "Dart:    $(dart --version 2>&1)"
echo "Flutter: $(flutter --version 2>&1 | head -1)"
echo

# Each package is checked against the floor it declares, not against a list
# kept here. The toolchain three sit a floor higher than the rest — see the
# guard in packages/alloy/test/registered_packages_test.dart for why — so on an
# old SDK they are skipped rather than failed, and the day they come down they
# join without anyone remembering to edit this.
DART_VERSION=$(dart --version 2>&1 | sed -E 's/.*version: ([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
ALL=$(python3 "$ROOT/tool/floor_select.py" "$ROOT" "$DART_VERSION" $DART_PACKAGES $FLUTTER_PACKAGES)

for package in $DART_PACKAGES $FLUTTER_PACKAGES; do
  case " $ALL " in
    *" $package "*) ;;
    *) printf '%-22s skipped, declares a floor above %s\n' "$package" "$DART_VERSION" ;;
  esac
done

for package in $ALL; do
  mkdir -p "$WORK/$package"
  # Everything but the build output, which is large and rebuilt anyway.
  (cd "$ROOT/packages/$package" && tar cf - \
    --exclude build --exclude .dart_tool --exclude coverage .) \
    | (cd "$WORK/$package" && tar xf -)
done

python3 "$ROOT/tool/floor_overrides.py" "$WORK" $ALL

failed=""
for package in $ALL; do
  case " $FLUTTER_PACKAGES " in
    *" $package "*) get="flutter pub get"; run="flutter test" ;;
    # `-x repo` drops the two guards that read the repository around this
    # package: the root documents, the other pubspecs, the CI workflow. They
    # are right to live where they do and cannot run from a copy taken out of
    # the tree. See packages/alloy/dart_test.yaml.
    *) get="dart pub get"; run="dart test -x repo" ;;
  esac

  log=$WORK/$package.log
  printf '%-22s ' "$package"

  if ! (cd "$WORK/$package" && $get >"$log" 2>&1); then
    echo "RESOLVE FAILED"; tail -8 "$log"; failed="$failed $package"; continue
  fi
  if ! (cd "$WORK/$package" && dart analyze --fatal-infos . >>"$log" 2>&1); then
    echo "ANALYZE FAILED"; tail -20 "$log"; failed="$failed $package"; continue
  fi
  if [ ! -d "$WORK/$package/test" ]; then
    echo "ok (resolved, analysed; no tests)"
    continue
  fi
  if ! (cd "$WORK/$package" && $run >>"$log" 2>&1); then
    echo "TESTS FAILED"; tail -30 "$log"; failed="$failed $package"; continue
  fi
  echo "ok (resolved, analysed, tested)"
done

if [ -n "$failed" ]; then
  echo
  echo "Floor not met by:$failed"
  exit 1
fi

echo
echo "Every package meets the floor it declares."
