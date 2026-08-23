/// Flutter bindings for Alloy.
///
/// Re-exports the whole runtime, so a Flutter app needs this import alone.
/// [AlloyScopeProvider] publishes a scope to a subtree, [AlloyScopeWidget]
/// owns one for as long as it is mounted, and `context.alloy<T>()` resolves
/// from whichever is nearest.
library;

export 'package:alloy/alloy.dart';

export 'package:alloy_flutter/src/alloy_app_scope.dart';
export 'package:alloy_flutter/src/alloy_app_scope_controller.dart';
export 'package:alloy_flutter/src/alloy_build_context.dart';
export 'package:alloy_flutter/src/alloy_scope_provider.dart';
export 'package:alloy_flutter/src/alloy_scoped_stateful_widget.dart';
export 'package:alloy_flutter/src/alloy_scoped_widget.dart';
export 'package:alloy_flutter/src/alloy_scope_widget.dart';
