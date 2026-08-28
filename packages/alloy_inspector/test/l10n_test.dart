import 'dart:convert';
import 'dart:io';

import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_inspector/alloy_inspector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// The inspector as a host mounts it, in [locale].
///
/// [installed] is the difference between a host that added
/// `AlloyInspectorL10n.delegate` and one that only localized itself — both are
/// real, and the second is the common one.
Widget inspectorIn(
  Locale locale,
  AlloyScope scope,
  AlloyInspectorLog log, {
  bool installed = true,
  List<Locale> supported = const [Locale('en'), Locale('ru'), Locale('zh')],
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: [
    if (installed) AlloyInspectorL10n.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: supported,
  home: AlloyInspectorScreen(log: log, scope: scope),
);

void main() {
  late AlloyInspectorLog log;
  late AlloyScope scope;

  setUp(() {
    clocksBuilt = 0;
    log = AlloyInspectorLog();
    scope = buildGraph(log);
    addTearDown(log.dispose);
  });

  testWidgets('the inspector speaks the host app language', (tester) async {
    await tester.pumpWidget(inspectorIn(const Locale('ru'), scope, log));
    await tester.pump();

    expect(find.text('Alloy · инспектор'), findsOneWidget);
    expect(find.text('Дерево'), findsOneWidget);
    expect(find.text('фильтр регистраций'), findsOneWidget);
  });

  testWidgets('Chinese is a translation, not a fallback', (tester) async {
    await tester.pumpWidget(inspectorIn(const Locale('zh'), scope, log));
    await tester.pump();

    expect(find.text('Alloy · 检查器'), findsOneWidget);
    expect(find.text('作用域树'), findsOneWidget);
  });

  testWidgets('a host that installed no delegate still gets its own language', (
    tester,
  ) async {
    await tester.pumpWidget(
      inspectorIn(const Locale('ru'), scope, log, installed: false),
    );
    await tester.pump();

    expect(
      find.text('Alloy · инспектор'),
      findsOneWidget,
      reason:
          'the delegate wins where it is installed and the ambient locale '
          'decides where it is not — an inspector you drop in to look at a '
          'graph has to render before anyone edits localizationsDelegates',
    );
  });

  testWidgets('a language nobody translated falls back to English', (
    tester,
  ) async {
    await tester.pumpWidget(
      inspectorIn(
        const Locale('fr'),
        scope,
        log,
        installed: false,
        supported: const [Locale('fr')],
      ),
    );
    await tester.pump();

    expect(find.text('Alloy · inspector'), findsOneWidget);
  });

  testWidgets('a node counts its registrations and children in words that '
      'agree with the number', (tester) async {
    scope.push('one');

    await tester.pumpWidget(inspectorIn(const Locale('en'), scope, log));
    await tester.pump();

    expect(
      find.text('3 reg · 1 child'),
      findsOneWidget,
      reason:
          'this line was English prose glued together with a plus, and it '
          'said "1 child" and "2 child" alike — only running it showed that',
    );

    scope.push('two');
    await tester.pumpWidget(inspectorIn(const Locale('en'), scope, log));
    await tester.pump();
    expect(find.text('3 reg · 2 children'), findsOneWidget);

    await tester.pumpWidget(inspectorIn(const Locale('ru'), scope, log));
    await tester.pump();
    expect(find.text('3 рег. · 2 дочерних'), findsOneWidget);
  });

  test('every translation covers the template, key for key', () {
    Set<String> keysOf(String name) {
      final decoded = jsonDecode(
        File('l10n/$name.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      return decoded.keys.where((key) => !key.startsWith('@')).toSet();
    }

    final template = keysOf('inspector_en');
    expect(template, isNotEmpty);

    for (final locale in ['ru', 'zh']) {
      expect(
        keysOf('inspector_$locale'),
        template,
        reason:
            'a missing translation is only a warning from gen-l10n, and then '
            'that one string silently comes back in English — which reads as '
            'a rendering bug rather than as a gap in the translation',
      );
    }
  });
}
