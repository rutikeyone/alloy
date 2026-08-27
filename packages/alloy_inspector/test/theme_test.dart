import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_inspector/alloy_inspector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the palette', () {
    testWidgets('is derived from the host theme when nobody sets one', (
      tester,
    ) async {
      final host = ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      );
      late AlloyInspectorThemeData palette;

      await tester.pumpWidget(
        MaterialApp(
          theme: host,
          home: Builder(
            builder: (context) {
              palette = AlloyInspectorTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(palette.background, host.colorScheme.surface);
      expect(palette.accent, host.colorScheme.primary);
      expect(palette.failure, host.colorScheme.error);
    });

    testWidgets('an inherited one reaches a descendant', (tester) async {
      const mine = AlloyInspectorThemeData(
        background: Color(0xFF101010),
        surface: Color(0xFF202020),
        onSurface: Color(0xFFEEEEEE),
        muted: Color(0xFF999999),
        outline: Color(0xFF333333),
        accent: Color(0xFF00E5FF),
        scope: Color(0xFF00E5FF),
        startup: Color(0xFF76FF03),
        instance: Color(0xFF999999),
        failure: Color(0xFFFF5252),
      );
      late AlloyInspectorThemeData seen;

      await tester.pumpWidget(
        MaterialApp(
          home: AlloyInspectorTheme(
            data: mine,
            child: Builder(
              builder: (context) {
                seen = AlloyInspectorTheme.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(seen, mine);
    });

    /// Thirteen kinds, four families: a kind added without a colour should
    /// fail here rather than paint itself grey in a corner of a screen.
    test('every event kind lands in a family', () {
      for (final kind in AlloyEventKind.values) {
        expect(
          AlloyInspectorFamily.values,
          contains(AlloyInspectorFamily.of(kind)),
          reason: '$kind',
        );
      }
    });

    test('every family names the title the talker adapter writes', () {
      expect(AlloyInspectorFamily.values.map((f) => f.talkerTitle).toSet(), {
        'alloy-scope',
        'alloy-startup',
        'alloy-instance',
        'alloy-failure',
      });
    });

    test('every lifetime and level has a colour', () {
      final palette = AlloyInspectorThemeData.of(ThemeData.light());
      for (final kind in AlloyRegistrationKind.values) {
        expect(() => palette.colorOfLifetime(kind), returnsNormally);
      }
      for (final level in AlloyLogLevel.values) {
        expect(() => palette.colorOfLevel(level), returnsNormally);
      }
    });

    test('copyWith replaces only what it is given', () {
      final base = AlloyInspectorThemeData.of(ThemeData.light());
      final changed = base.copyWith(failure: const Color(0xFF123456));

      expect(changed.failure, const Color(0xFF123456));
      expect(changed.accent, base.accent);
      expect(changed == base, isFalse);
    });
  });
}
