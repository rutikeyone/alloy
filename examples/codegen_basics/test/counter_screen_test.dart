import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:codegen_basics/alloy.g.dart';
import 'package:codegen_basics/counter_screen.dart';
import 'package:codegen_basics/greeting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// The screen is where the generated container meets widgets, and where a
  /// parameterized registration is actually resolved. It was written and run
  /// by nothing.
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AlloyAppScope(
          root: $AlloyRootScope(),
          rootName: $alloyRootScopeName,
          child: CounterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the screen resolves its bloc from the generated graph', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('0'), findsOneWidget);
    expect(find.text('environment: test'), findsOneWidget);

    await tester.tap(find.text('increment'));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('a parameterized registration is resolved with its record', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(
      find.text('hello Alloy from test'),
      findsOneWidget,
      reason:
          'the config came from the graph, the name and the flag from the '
          'call site',
    );
  });

  testWidgets('the record is what the call site passes, not a fixed value', (
    tester,
  ) async {
    late Greeting loud;
    await tester.pumpWidget(
      MaterialApp(
        home: AlloyAppScope(
          root: const $AlloyRootScope(),
          rootName: $alloyRootScopeName,
          child: Builder(
            builder: (context) {
              loud = context.alloyWithParam<Greeting, $GreetingArgs>((
                name: 'World',
                loud: true,
              ));
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(loud.render(), 'HELLO WORLD FROM TEST');
  });
}
