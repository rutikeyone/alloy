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
/// There is no per-example palette. Every example is painted by the one theme
/// above, so moving between them changes what the graph does and nothing else.
class ExampleHost extends StatelessWidget {
  const ExampleHost({
    required this.root,
    required this.child,
    this.bootstrap,
    this.rootName = 'root',
    this.observers = const [],
    super.key,
  });

  final AlloyScopeBuilder root;
  final Widget child;
  final List<AlloyBootstrapStep> Function()? bootstrap;
  final String rootName;
  final List<AlloyObserver> observers;

  @override
  Widget build(BuildContext context) => AlloyAppScope(
    root: root,
    bootstrap: bootstrap,
    rootName: rootName,
    observers: observers,
    loading: const _Starting(),
    errorBuilder: (context, error, retry) =>
        _StartupFailed(error: error, retry: retry),
    child: child,
  );
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
