import 'package:cobalt_flutter/cobalt_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolving with no provider above', () {
    testWidgets('says so with its own error, not a bare CobaltError', (
      tester,
    ) async {
      late BuildContext captured;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      );

      expect(
        () => CobaltScopeProvider.of(captured),
        throwsA(isA<CobaltNoScopeError>()),
      );
    });

    /// The trap this repository walked into four times, now in the message.
    testWidgets('the message warns about a pushed route', (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      );

      expect(
        () => CobaltScopeProvider.of(captured),
        throwsA(
          isA<CobaltNoScopeError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('pushed route'), contains('pass the scope in')),
          ),
        ),
      );
    });

    testWidgets('maybeOf stays quiet where of throws', (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      );

      expect(CobaltScopeProvider.maybeOf(captured), isNull);
    });
  });

  group('asking to restart with no owner above', () {
    testWidgets('names CobaltAppScope, not the provider', (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        CobaltScopeProvider(
          scope: CobaltScope.root(name: 'app'),
          child: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(
        () => CobaltAppScope.of(captured),
        throwsA(
          isA<CobaltNoAppScopeError>().having(
            (error) => error.toString(),
            'message',
            allOf(
              contains('CobaltAppScope'),
              contains('only publishes a scope somebody else owns'),
            ),
          ),
        ),
        reason:
            'a provider above is exactly the case where the two are easy to '
            'confuse: it publishes a scope but owns none',
      );
    });
  });
}
