/// Shared static analysis layer for Alloy.
///
/// Turns annotated Dart source into a typed intermediate representation that
/// both `alloy_generator` and `alloy_lint` consume, so a declaration is parsed
/// by one implementation rather than two that drift apart.
///
/// Depends on `analyzer` but deliberately not on `build` or the plugin API,
/// which is what keeps the build system out of the analysis server.
library;

export 'package:alloy/alloy.dart' show AlloyCycleError, layeredTopologicalSort;
// The IR exposes these in its own public API — `AlloyInjectableClass.lifetime`
// is an AlloyLifetime — so a reader of the model needs them to say anything
// about what it read.
export 'package:alloy_annotations/alloy_annotations.dart' show AlloyLifetime;

export 'package:alloy_analyzer/src/model/bootstrap_step_class.dart';
export 'package:alloy_analyzer/src/model/function_ref.dart';
export 'package:alloy_analyzer/src/model/injectable_class.dart';
export 'package:alloy_analyzer/src/model/injected_property.dart';
export 'package:alloy_analyzer/src/model/library_declarations.dart';
export 'package:alloy_analyzer/src/model/provided_ref.dart';
export 'package:alloy_analyzer/src/model/provider_ref.dart';
export 'package:alloy_analyzer/src/model/scope_root_class.dart';
export 'package:alloy_analyzer/src/model/type_ref.dart';
export 'package:alloy_analyzer/src/parser/alloy_matchers.dart';
export 'package:alloy_analyzer/src/parser/alloy_parser.dart';
export 'package:alloy_analyzer/src/parser/annotation_matcher.dart';
export 'package:alloy_analyzer/src/parser/bootstrap_parser.dart';
export 'package:alloy_analyzer/src/parser/dart_object_reader.dart';
export 'package:alloy_analyzer/src/parser/injectable_parser.dart';
export 'package:alloy_analyzer/src/parser/module_parser.dart';
export 'package:alloy_analyzer/src/parser/parse_error.dart';
export 'package:alloy_analyzer/src/parser/scope_root_parser.dart';
export 'package:alloy_analyzer/src/parser/type_ref_resolver.dart';
