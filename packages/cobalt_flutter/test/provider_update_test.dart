import 'package:cobalt_flutter/cobalt_flutter.dart';
import 'package:cobalt_test/cobalt_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class Label {
  const Label(this.text);

  final String text;
}

CobaltScope scopeSaying(String text) =>
    cobaltTestRoot(name: 'app')..registerSingleton<Label>(Label(text));

/// Swaps the scope in place, keeping one child instance for the whole test.
///
/// Rebuilding the tree from `pumpWidget` would prove nothing: the reader would
/// be rebuilt because its ancestors were, whatever the provider decided. Here
/// the child widget is the same object every time, so the only thing that can
/// rebuild it is the provider notifying its dependents.
class _Host extends StatefulWidget {
  const _Host({required this.child, required this.first, super.key});

  final Widget child;
  final CobaltScope first;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late CobaltScope _scope = widget.first;

  void swap(CobaltScope next) => setState(() => _scope = next);

  @override
  Widget build(BuildContext context) =>
      CobaltScopeProvider(scope: _scope, child: widget.child);
}

class _Reader extends StatelessWidget {
  const _Reader({required this.builds});

  final List<String> builds;

  @override
  Widget build(BuildContext context) {
    final text = context.cobalt<Label>().text;
    builds.add(text);
    return Text(text, textDirection: TextDirection.ltr);
  }
}

void main() {
  /// A mutation making `updateShouldNotify` always return false passed every
  /// test in this package. Swapping the scope is how a restarted graph reaches
  /// the widgets below it, so it is pinned here.
  group('a provider handed a different scope', () {
    testWidgets('rebuilds what read the old one', (tester) async {
      final builds = <String>[];
      final key = GlobalKey<_HostState>();

      await tester.pumpWidget(
        _Host(
          key: key,
          first: scopeSaying('first'),
          child: _Reader(builds: builds),
        ),
      );
      expect(builds, ['first']);

      key.currentState!.swap(scopeSaying('second'));
      await tester.pump();

      expect(builds, ['first', 'second']);
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('leaves it alone when handed the same scope again', (
      tester,
    ) async {
      final builds = <String>[];
      final key = GlobalKey<_HostState>();
      final scope = scopeSaying('only');

      await tester.pumpWidget(
        _Host(
          key: key,
          first: scope,
          child: _Reader(builds: builds),
        ),
      );
      expect(builds, ['only']);

      key.currentState!.swap(scope);
      await tester.pump();

      expect(
        builds,
        ['only'],
        reason:
            'the same scope object is not a change, and notifying anyway '
            'would rebuild every reader on any parent rebuild',
      );
    });
  });
}
