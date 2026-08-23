/// Alloy — a dependency injection framework for Dart and Flutter.
///
/// Alloy works with or without code generation. The generator writes exactly
/// what you would write by hand, using only what this library exports, so both
/// modes share one runtime and one set of guarantees.
///
/// The starting points are [AlloyScope] for the container and
/// [AlloyApplication] for two-phase startup. For widgets, add
/// `package:alloy_flutter/alloy_flutter.dart`.
library;

export 'package:alloy_annotations/alloy_annotations.dart';

export 'package:alloy/src/bootstrap/alloy_application.dart';
export 'package:alloy/src/bootstrap/alloy_bootstrap_step.dart';
export 'package:alloy/src/bootstrap/alloy_scope_builder.dart';
export 'package:alloy/src/errors/alloy_bootstrap_error.dart';
export 'package:alloy/src/errors/alloy_dispose_error.dart';
export 'package:alloy/src/errors/alloy_dispose_failure.dart';
export 'package:alloy/src/errors/alloy_dispose_stage.dart';
export 'package:alloy/src/errors/alloy_duplicate_registration_error.dart';
export 'package:alloy/src/errors/alloy_error.dart';
export 'package:alloy/src/errors/alloy_not_ready_error.dart';
export 'package:alloy/src/errors/alloy_not_registered_error.dart';
export 'package:alloy/src/errors/alloy_scope_state_error.dart';
export 'package:alloy/src/factory/alloy_async_factory.dart';
export 'package:alloy/src/factory/alloy_factory.dart';
export 'package:alloy/src/factory/alloy_param_factory.dart';
export 'package:alloy/src/graph/alloy_cycle_error.dart';
export 'package:alloy/src/graph/topological_sort.dart';
export 'package:alloy/src/key/alloy_key.dart';
export 'package:alloy/src/logging/alloy_developer_log_sink.dart';
export 'package:alloy/src/logging/alloy_log_level.dart';
export 'package:alloy/src/logging/alloy_log_observer.dart';
export 'package:alloy/src/logging/alloy_log_record.dart';
export 'package:alloy/src/logging/alloy_log_sink.dart';
export 'package:alloy/src/logging/alloy_multi_sink.dart';
export 'package:alloy/src/logging/alloy_print_log_sink.dart';
export 'package:alloy/src/lifecycle/alloy_injectable.dart';
export 'package:alloy/src/lifecycle/alloy_resolver.dart';
export 'package:alloy/src/lifecycle/async_disposable.dart';
export 'package:alloy/src/lifecycle/async_initializable.dart';
export 'package:alloy/src/lifecycle/disposable.dart';
export 'package:alloy/src/observer/alloy_observer.dart';
export 'package:alloy/src/observer/alloy_scope_ref.dart';
export 'package:alloy/src/scope/alloy_scope.dart';
export 'package:alloy/src/scope/alloy_scope_state.dart';
