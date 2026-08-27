import 'package:alloy/alloy.dart';
import 'package:alloy_inspector/alloy_inspector.dart';
import 'package:alloy_talker/alloy_talker.dart';
import 'package:alloy_talker_flutter/alloy_talker_flutter.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker/talker.dart';

class Marker implements Disposable {
  @override
  void dispose() {}
}

void main() {
  final palette = AlloyInspectorThemeData.of(ThemeData.dark());

  group('the bridge to talker', () {
    test('carries the surfaces across', () {
      final theme = talkerScreenThemeOf(palette);

      expect(theme.backgroundColor, palette.background);
      expect(theme.textColor, palette.onSurface);
      expect(theme.cardColor, palette.surface);
    });

    test('colours each family under the title it is filed as', () {
      final theme = talkerScreenThemeOf(palette);

      for (final family in AlloyInspectorFamily.values) {
        expect(
          theme.logColors[family.talkerTitle],
          palette.colorOfFamily(family),
          reason: family.name,
        );
      }
    });

    /// Asserted against the field `talker_flutter` actually colours by, which
    /// is `key` and not `title`. The first version of this test compared the
    /// bridge to the titles the observer writes; both halves agreed with each
    /// other and with nothing else, and the screen painted every startup entry
    /// the blue talker uses for any info line. Only running it showed that.
    test(
      'the key talker colours by is one the bridge has a colour for',
      () async {
        final talker = Talker();
        final scope = alloyTestRoot(
          name: 'app',
          observers: [AlloyTalkerObserver(talker, verbose: true)],
        )..registerLazySingleton<Marker>(FnFactory((_) => Marker()));

        scope
          ..push('session')
          ..get<Marker>();
        await scope.dispose();

        final keyed = {
          for (final entry in talker.history)
            if (entry.key?.startsWith('alloy-') ?? false) entry.key!,
        };
        final titled = {
          for (final entry in talker.history)
            if (entry.title?.startsWith('alloy-') ?? false) entry.title!,
        };

        expect(
          keyed,
          isNotEmpty,
          reason:
              'a log with no key is coloured by '
              'level, which is the same blue for every info line',
        );
        expect(keyed, titled, reason: 'key and title name the same family');
        expect(
          keyed.difference(talkerScreenThemeOf(palette).logColors.keys.toSet()),
          isEmpty,
        );
      },
    );
  });

  testWidgets('the screen takes the inherited palette', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AlloyInspectorTheme(
          data: palette,
          child: AlloyTalkerScreen(talker: Talker()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AlloyTalkerScreen), findsOneWidget);
  });
}
