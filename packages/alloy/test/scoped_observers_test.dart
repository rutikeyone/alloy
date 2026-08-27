import 'package:alloy/alloy.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:test/test.dart';

class Marker {}

final class _Recording extends AlloyObserver {
  _Recording(this.label, this.seen);

  final String label;
  final List<String> seen;

  @override
  void onScopePushed(AlloyScopeRef scope) => seen.add('$label:pushed:$scope');

  @override
  void onScopeDisposeStarted(AlloyScopeRef scope) =>
      seen.add('$label:disposing:$scope');
}

void main() {
  group('an observer added when a scope is pushed', () {
    test('sees that scope and its descendants, and nothing above', () async {
      final seen = <String>[];
      final root = alloyTestRoot(name: 'app');

      final session = root.push(
        'session',
        observers: [_Recording('session', seen)],
      );
      final screen = session.push('screen');
      root.push('other');

      await screen.dispose();

      expect(seen, [
        'session:pushed:app/session',
        'session:pushed:session/screen',
        'session:disposing:session/screen',
      ]);
      expect(
        seen.where((entry) => entry.contains('other')),
        isEmpty,
        reason: 'a sibling of the watched scope is none of its business',
      );
    });

    test('does not replace the ones inherited from the root', () async {
      final root0 = <String>[];
      final added = <String>[];
      final root = alloyTestRoot(
        name: 'app',
        observers: [_Recording('root', root0)],
      );

      root.push('session', observers: [_Recording('added', added)]);

      expect(root0, ['root:pushed:app/session']);
      expect(added, ['added:pushed:app/session']);
    });

    test('the first thing it sees is the push that installed it', () {
      final seen = <String>[];
      final root = alloyTestRoot(name: 'app');

      root.push('session', observers: [_Recording('session', seen)]);

      expect(seen.first, 'session:pushed:app/session');
    });

    test('pushing without observers is unchanged', () {
      final seen = <String>[];
      final root = alloyTestRoot(
        name: 'app',
        observers: [_Recording('root', seen)],
      );

      final child = root.push('session');
      child.registerLazySingleton<Marker>(FnFactory((_) => Marker()));

      expect(seen, ['root:pushed:app/session']);
    });
  });
}
