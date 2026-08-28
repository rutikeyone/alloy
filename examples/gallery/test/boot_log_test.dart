import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/catalog/catalog.dart';
import 'package:notes_app/bootstrap/boot_log.dart';
import 'package:notes_app/bootstrap/load_remote_config.dart';

import 'support.dart';

void main() {
  testWidgets('a second visit does not stack onto the first one’s boot log', (
    tester,
  ) async {
    final entry = buildCatalog(englishStrings)
        .firstWhere((e) => e.id == 'startup');

    Future<void> visit(String key) async {
      await tester.pumpWidget(
        galleryHarness(
          home: Builder(key: ValueKey(key), builder: entry.open!),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
    }

    await visit('first');
    expect(BootLog.steps, isNotEmpty, reason: 'the first visit ran phase 0');

    await visit('second');

    // One occurrence each, not two: the log is a process-wide static, so a
    // visit has to clear it or it shows every earlier visit as well.
    //
    // Only the steps are counted. The outgoing graph's "released" line can
    // still land here, because teardown is not awaited — one scope is on its
    // way out while the next is coming up. That is Alloy's documented
    // behaviour showing through, not this screen misreporting.
    for (final step in ['bind-platform', 'load-remote-config', 'warm-fonts']) {
      expect(
        BootLog.steps.where((s) => s == step),
        hasLength(1),
        reason: '$step appears once per visit, not once per visit ever made',
      );
    }
  });

  testWidgets('a visit does not read the last one’s remote config', (
    tester,
  ) async {
    final entry = buildCatalog(englishStrings)
        .firstWhere((e) => e.id == 'startup');

    // The value the step writes is a static too. Poisoning it stands in for
    // "some earlier visit left this behind": a visit must not surface it.
    LoadRemoteConfig.apiBaseUrl = 'https://stale.example/v0';

    await tester.pumpWidget(
      galleryHarness(home: Builder(builder: entry.open!)),
    );
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(find.textContaining('stale.example'), findsNothing);
  });
}
