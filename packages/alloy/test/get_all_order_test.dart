import 'package:alloy/alloy.dart';
import 'package:test/test.dart';

class Formatter {
  const Formatter(this.label);

  final String label;
}

void main() {
  /// `getAll` used to sort a copy of the matches by registration order. It no
  /// longer does, because iterating `_registrations` is already that order —
  /// which is a property of `_put` inserting and never replacing, not
  /// something the reader arranges. These pin it, so a change to registration
  /// cannot quietly reorder what every consumer of a multi-binding sees.
  group('getAll order', () {
    test('is registration order, not declaration or alphabetical', () {
      final scope = AlloyScope.root(name: 'app')
        ..registerSingleton<Formatter>(const Formatter('zulu'), name: 'z')
        ..registerSingleton<Formatter>(const Formatter('alpha'), name: 'a')
        ..registerSingleton<Formatter>(const Formatter('mike'), name: 'm');
      addTearDown(scope.dispose);

      expect(scope.getAll<Formatter>().map((each) => each.label), [
        'zulu',
        'alpha',
        'mike',
      ]);
    });

    test('walks own registrations first, then each ancestor in turn', () {
      final root = AlloyScope.root(name: 'app')
        ..registerSingleton<Formatter>(const Formatter('root-1'), name: 'r1')
        ..registerSingleton<Formatter>(const Formatter('root-2'), name: 'r2');
      addTearDown(root.dispose);

      final child = root.push('session')
        ..registerSingleton<Formatter>(const Formatter('child'), name: 'c');

      expect(child.getAll<Formatter>().map((each) => each.label), [
        'child',
        'root-1',
        'root-2',
      ]);
    });

    test('a shadowed key is taken from the nearest scope only once', () {
      final root = AlloyScope.root(name: 'app')
        ..registerSingleton<Formatter>(const Formatter('root'), name: 'shared');
      addTearDown(root.dispose);

      final child = root.push(
        'session',
      )..registerSingleton<Formatter>(const Formatter('child'), name: 'shared');

      expect(child.getAll<Formatter>().map((each) => each.label), ['child']);
    });

    test('is stable across calls', () {
      final scope = AlloyScope.root(name: 'app');
      addTearDown(scope.dispose);
      for (var i = 0; i < 20; i++) {
        scope.registerSingleton<Formatter>(Formatter('$i'), name: '$i');
      }

      final first = scope.getAll<Formatter>().map((each) => each.label);
      expect(scope.getAll<Formatter>().map((each) => each.label), first);
    });
  });
}
