/// Code generator for Cobalt.
///
/// Exposed for testing and for tools building on top of it; applications only
/// need `builder.dart`, which `build_runner` finds through `build.yaml`.
///
/// Generation runs in two phases because a build step sees one library at a
/// time: `CobaltScanGenerator` writes a per-library IR, and
/// `CobaltContainerBuilder` aggregates every IR file into one container.
library;

export 'package:cobalt_generator/src/builders/container_builder.dart';
export 'package:cobalt_generator/src/emitters/cobalt_references.dart';
export 'package:cobalt_generator/src/emitters/bootstrap_emitter.dart';
export 'package:cobalt_generator/src/emitters/container_source_emitter.dart';
export 'package:cobalt_generator/src/emitters/injectable_factory_emitter.dart';
export 'package:cobalt_generator/src/emitters/injection_mixin_emitter.dart';
export 'package:cobalt_generator/src/emitters/root_scope_emitter.dart';
export 'package:cobalt_generator/src/emitters/start_function_emitter.dart';
export 'package:cobalt_generator/src/errors/cobalt_generation_error.dart';
export 'package:cobalt_generator/src/generators/property_injection_generator.dart';
export 'package:cobalt_generator/src/generators/scan_generator.dart';
export 'package:cobalt_generator/src/hashed_allocator.dart';
