import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final disposeLog = <String>[];

class Draft implements Disposable {
  Draft(this.label);

  final String label;
  var text = '';

  @override
  void dispose() => disposeLog.add(label);
}

class DraftFactory implements AlloyFactory<Draft> {
  const DraftFactory(this.label);

  final String label;

  @override
  Draft create(AlloyResolver resolver) => Draft(label);
}

class PlainScreen extends AlloyScopedWidget {
  const PlainScreen({super.key});

  @override
  void registerScope(AlloyScope scope) =>
      scope.registerLazySingleton<Draft>(const DraftFactory('plain'));

  @override
  Widget buildScoped(BuildContext context) => Text(
    '${context.alloyScope.name}/${context.alloy<Draft>().label}',
    textDirection: TextDirection.ltr,
  );
}

class NamedScreen extends AlloyScopedWidget {
  const NamedScreen({super.key});

  @override
  String get scopeName => 'checkout';

  @override
  void registerScope(AlloyScope scope) =>
      scope.registerLazySingleton<Draft>(const DraftFactory('named'));

  @override
  Widget buildScoped(BuildContext context) =>
      Text(context.alloyScope.name, textDirection: TextDirection.ltr);
}

class CounterScreen extends AlloyScopedStatefulWidget {
  const CounterScreen({super.key});

  @override
  void registerScope(AlloyScope scope) =>
      scope.registerLazySingleton<Draft>(const DraftFactory('counter'));

  @override
  AlloyScopedState<CounterScreen> createState() => CounterScreenState();
}

class CounterScreenState extends AlloyScopedState<CounterScreen> {
  var taps = 0;

  @override
  Widget buildScoped(BuildContext context) {
    final draft = context.alloy<Draft>();
    return GestureDetector(
      onTap: () => setState(() => taps++),
      child: Text(
        '${context.alloyScope.name} $taps ${identityHashCode(draft)}',
        textDirection: TextDirection.ltr,
      ),
    );
  }
}

void main() {
  setUp(disposeLog.clear);

  Widget host(AlloyScope scope, Widget child) =>
      AlloyScopeProvider(scope: scope, child: child);

  group('AlloyScopedWidget', () {
    testWidgets('pushes a scope named after the widget', (tester) async {
      final root = AlloyScope.root(name: 'app');
      addTearDown(root.dispose);

      await tester.pumpWidget(host(root, const PlainScreen()));
      await tester.pumpAndSettle();

      expect(find.text('PlainScreen/plain'), findsOneWidget);
      expect(root.children.single.name, 'PlainScreen');
    });

    testWidgets('an explicit scopeName wins', (tester) async {
      final root = AlloyScope.root(name: 'app');
      addTearDown(root.dispose);

      await tester.pumpWidget(host(root, const NamedScreen()));
      await tester.pumpAndSettle();

      expect(find.text('checkout'), findsOneWidget);
    });

    testWidgets('unmounting disposes what the scope built', (tester) async {
      final root = AlloyScope.root(name: 'app');
      addTearDown(root.dispose);

      await tester.pumpWidget(host(root, const PlainScreen()));
      await tester.pumpAndSettle();

      await tester.pumpWidget(host(root, const SizedBox.shrink()));
      await tester.pumpAndSettle();

      expect(disposeLog, ['plain']);
      expect(root.children, isEmpty);
    });
  });

  group('AlloyScopedStatefulWidget', () {
    testWidgets('setState rebuilds the content, not the scope', (tester) async {
      final root = AlloyScope.root(name: 'app');
      addTearDown(root.dispose);

      await tester.pumpWidget(host(root, const CounterScreen()));
      await tester.pumpAndSettle();

      final before = tester.widget<Text>(find.byType(Text)).data!;
      expect(before, startsWith('CounterScreen 0 '));

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      final after = tester.widget<Text>(find.byType(Text)).data!;
      expect(after, startsWith('CounterScreen 1 '));
      expect(
        after.split(' ').last,
        before.split(' ').last,
        reason: 'the same Draft instance, so the scope was not rebuilt',
      );
      expect(disposeLog, isEmpty);
    });

    testWidgets('unmounting disposes the scope', (tester) async {
      final root = AlloyScope.root(name: 'app');
      addTearDown(root.dispose);

      await tester.pumpWidget(host(root, const CounterScreen()));
      await tester.pumpAndSettle();
      await tester.pumpWidget(host(root, const SizedBox.shrink()));
      await tester.pumpAndSettle();

      expect(disposeLog, ['counter']);
    });
  });

  group('AlloyScopeWidget without a name', () {
    testWidgets('falls back to the builder type', (tester) async {
      final root = AlloyScope.root(name: 'app');
      addTearDown(root.dispose);

      await tester.pumpWidget(
        host(
          root,
          AlloyScopeWidget(
            builder: const AlloyWidgetScopeBuilder(PlainScreen()),
            child: Builder(
              builder: (context) => Text(
                context.alloyScope.name,
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AlloyWidgetScopeBuilder'), findsOneWidget);
    });
  });
}
