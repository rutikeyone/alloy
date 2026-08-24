import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/material.dart';
import 'package:gallery/design/gallery_theme.dart';

/// Mounts one example with its own root scope.
///
/// The graph is built when this route is pushed and disposed when it is
/// popped, so opening an example twice gives you two unrelated graphs — which
/// is the whole point of the gallery. `AlloyAppScope` is used directly rather
/// than through `.builder`: there is already a `MaterialApp` above, so loading
/// and error render under the gallery's theme without one of their own.
///
/// The example keeps its own colours. A gallery that repainted every example
/// in its own palette would be showing you the gallery, not the example.
class ExampleHost extends StatelessWidget {
  const ExampleHost({
    required this.root,
    required this.child,
    this.bootstrap,
    this.rootName = 'root',
    this.observers = const [],
    this.seedColor,
    super.key,
  });

  final AlloyScopeBuilder root;
  final Widget child;
  final List<AlloyBootstrapStep> Function()? bootstrap;
  final String rootName;
  final List<AlloyObserver> observers;

  /// The example's own seed colour, applied to its subtree only.
  final Color? seedColor;

  @override
  Widget build(BuildContext context) {
    final seed = seedColor;

    final scoped = AlloyAppScope(
      root: root,
      bootstrap: bootstrap,
      rootName: rootName,
      observers: observers,
      loading: const _Starting(),
      errorBuilder: (context, error, retry) =>
          _StartupFailed(error: error, retry: retry),
      child: child,
    );

    if (seed == null) return scoped;
    return Theme(
      data: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
      ),
      child: scoped,
    );
  }
}

class _Starting extends StatelessWidget {
  const _Starting();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _StartupFailed extends StatelessWidget {
  const _StartupFailed({required this.error, required this.retry});

  final Object error;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This example could not start', style: GalleryText.cardTitle),
            const SizedBox(height: 12),
            Text('$error', style: GalleryText.cardBody),
            const SizedBox(height: 20),
            FilledButton(onPressed: retry, child: const Text('Try again')),
          ],
        ),
      ),
    ),
  );
}
