/// Code generator for Cobalt.
///
/// An application never imports this: `build_runner` finds `builder.dart`
/// through `build.yaml`, and everything else here happens behind it.
///
/// Only the error is exported. The emitters, the generators and the allocator
/// are `src/` and stay there — they were exported for the tests once, and the
/// tests import them directly instead, because a type that ships is a type
/// that cannot be reshaped without a major version. Generation runs in two
/// phases because a build step sees one library at a time: `CobaltScanGenerator`
/// writes a per-library IR, and `CobaltContainerBuilder` aggregates every IR
/// file into one container.
library;

export 'package:cobalt_generator/src/errors/cobalt_generation_error.dart';
