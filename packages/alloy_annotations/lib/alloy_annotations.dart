/// Annotations for Alloy, a dependency injection framework for Dart and
/// Flutter.
///
/// This library holds nothing but the markers the generator reads, so a
/// package that only declares annotations does not pull in the runtime. Most
/// applications import `package:alloy/alloy.dart`, which re-exports all of it.
library;

export 'package:alloy_annotations/src/alloy_bootstrap.dart';
export 'package:alloy_annotations/src/alloy_environment.dart';
export 'package:alloy_annotations/src/alloy_init.dart';
export 'package:alloy_annotations/src/alloy_inject.dart';
export 'package:alloy_annotations/src/alloy_lifetime.dart';
export 'package:alloy_annotations/src/alloy_module.dart';
export 'package:alloy_annotations/src/alloy_param.dart';
export 'package:alloy_annotations/src/alloy_provided.dart';
export 'package:alloy_annotations/src/alloy_scope_root.dart';
export 'package:alloy_annotations/src/injected.dart';
export 'package:alloy_annotations/src/named.dart';
