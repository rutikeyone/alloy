import 'dart:async';

import 'package:cobalt/cobalt.dart';
import 'package:cobalt_flutter/src/cobalt_scope_provider.dart';
import 'package:flutter/widgets.dart';

/// Owns a child scope for as long as it is mounted.
///
/// On mount it pushes a child of the nearest ancestor scope, fills it from
/// [builder] and awaits its `init()`. On unmount it disposes it. That ties a
/// scope's lifetime to a piece of UI: a screen's dependencies live exactly as
/// long as the screen, with no teardown to remember.
///
/// ```dart
/// CobaltScopeWidget(
///   name: 'note-detail',
///   builder: const NoteDetailScope(),
///   loading: const CircularProgressIndicator(),
///   child: const NoteDetailPage(),
/// )
/// ```
class CobaltScopeWidget extends StatefulWidget {
  /// Creates a widget owning a scope.
  const CobaltScopeWidget({
    required this.builder,
    this.name,
    required this.child,
    this.loading,
    this.errorBuilder,
    super.key,
  });

  /// Name of the scope this widget creates.
  ///
  /// Defaults to the runtime type of [builder], which reads well in the scope
  /// tree and in error messages: a `NoteDetailScope` produces a scope called
  /// `NoteDetailScope`. Pass a name when one builder is used in several places
  /// and the instances need telling apart.
  final String? name;

  /// The name this widget's scope actually gets.
  String get effectiveName => name ?? builder.runtimeType.toString();

  /// Declares what goes into the scope.
  final CobaltScopeBuilder builder;

  /// Shown once the scope is initialized.
  final Widget child;

  /// Shown while `init()` runs. Defaults to an empty box, which is right when
  /// the scope has no async registrations and is ready on the first frame.
  final Widget? loading;

  /// Shown when initialization fails. Without it the error is rethrown during
  /// build, surfacing through the usual Flutter error handling.
  ///
  /// Teardown errors never reach this builder — by then the widget is gone —
  /// and go to `FlutterError.reportError` instead.
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  State<CobaltScopeWidget> createState() => _CobaltScopeWidgetState();
}

class _CobaltScopeWidgetState extends State<CobaltScopeWidget> {
  CobaltScope? _scope;
  Object? _error;
  var _isReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scope != null) return;

    final parent = CobaltScopeProvider.of(context);
    final scope = parent.push(widget.effectiveName);
    scope.runBuilder(widget.builder);
    _scope = scope;
    unawaited(_initialize(scope));
  }

  Future<void> _initialize(CobaltScope scope) async {
    try {
      await scope.init();
      if (mounted) setState(() => _isReady = true);
    } catch (error, stackTrace) {
      if (!mounted) {
        // The widget is gone, so nothing will render this. Report it rather
        // than drop it — an init that fails after unmount is still a failure.
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'cobalt_flutter',
            context: ErrorDescription(
              'initializing the scope owned by CobaltScopeWidget '
              '"${widget.effectiveName}", after it was unmounted',
            ),
          ),
        );
        return;
      }
      setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    final scope = _scope;
    _scope = null;
    if (scope != null) unawaited(_disposeScope(scope));
    super.dispose();
  }

  Future<void> _disposeScope(CobaltScope scope) async {
    try {
      await scope.dispose();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'cobalt_flutter',
          context: ErrorDescription(
            'disposing the scope owned by CobaltScopeWidget '
            '"${widget.effectiveName}"',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      final errorBuilder = widget.errorBuilder;
      if (errorBuilder != null) return errorBuilder(context, error);
      throw error;
    }

    final scope = _scope;
    if (scope == null || !_isReady) {
      return widget.loading ?? const SizedBox.shrink();
    }

    return CobaltScopeProvider(scope: scope, child: widget.child);
  }
}
