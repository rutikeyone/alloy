import 'package:alloy/alloy.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:test/test.dart';

class DevWithMocks extends AlloyEnvironment {
  const DevWithMocks() : super('dev');

  @override
  bool matches(Set<String> environments) =>
      super.matches(environments) || environments.contains('mock');
}

void main() {
  group('AlloyEnvironment', () {
    test('an unrestricted registration belongs to every environment', () {
      for (final environment in const [
        AlloyEnvironment.dev,
        AlloyEnvironment.stage,
        AlloyEnvironment.prod,
        AlloyEnvironment.test,
        AlloyEnvironment('canary'),
      ]) {
        expect(environment.matches(const {}), isTrue);
      }
    });

    test('the default environment holds an unsplit graph and nothing more', () {
      const environment = AlloyEnvironment.defaultEnvironment;

      expect(environment.matches(const {}), isTrue);
      expect(environment.matches(const {'dev'}), isFalse);
      expect(environment.matches(const {'prod'}), isFalse);
      expect(
        environment.matches(const {'default'}),
        isTrue,
        reason: 'naming it explicitly is allowed, if pointless',
      );
    });

    test('a restricted registration belongs only where it is named', () {
      expect(AlloyEnvironment.dev.matches(const {'dev'}), isTrue);
      expect(AlloyEnvironment.dev.matches(const {'prod'}), isFalse);
      expect(AlloyEnvironment.dev.matches(const {'dev', 'stage'}), isTrue);
    });

    test('a name of your own is not second class', () {
      const canary = AlloyEnvironment('canary');

      expect(canary.matches(const {'canary'}), isTrue);
      expect(canary.matches(const {}), isTrue);
      expect(AlloyEnvironment.prod.matches(const {'canary'}), isFalse);
    });

    test('matching can be widened by subclassing', () {
      const environment = DevWithMocks();

      expect(environment.matches(const {'dev'}), isTrue);
      expect(environment.matches(const {'mock'}), isTrue);
      expect(environment.matches(const {'prod'}), isFalse);
    });

    test('equality is by name, and a subclass is not its base', () {
      expect(const AlloyEnvironment('dev'), equals(AlloyEnvironment.dev));
      expect(
        const AlloyEnvironment('dev'),
        isNot(equals(const DevWithMocks())),
      );
      expect(AlloyEnvironment.dev, isNot(equals(AlloyEnvironment.prod)));
    });
  });

  group('a manually built graph', () {
    test('selects an implementation the same way the generator does', () async {
      Future<String> noteStoreIn(AlloyEnvironment environment) async {
        final scope = alloyTestRoot(name: 'app');
        if (environment.matches(const {'prod'})) {
          scope.registerSingleton<String>('sql');
        }
        if (environment.matches(const {'dev', 'test'})) {
          scope.registerSingleton<String>('fake');
        }
        await scope.init();
        final value = scope.get<String>();
        await scope.dispose();
        return value;
      }

      expect(await noteStoreIn(AlloyEnvironment.prod), 'sql');
      expect(await noteStoreIn(AlloyEnvironment.dev), 'fake');
      expect(await noteStoreIn(AlloyEnvironment.test), 'fake');
    });
  });
}
