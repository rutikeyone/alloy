import 'package:cobalt_flutter/cobalt_flutter.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/features/note_detail/ui/note_draft.dart';
import 'package:notes_app/features/note_detail/ui/note_title_card.dart';
import 'package:notes_app/l10n/notes_app_l10n.dart';

class NoteDetailScreen extends CobaltScopedStatefulWidget {
  const NoteDetailScreen({super.key});

  @override
  Widget get loading => const Center(child: CircularProgressIndicator());

  @override
  void registerScope(CobaltScope scope) {
    scope
      ..registerLazySingleton<NoteDraft>(const NoteDraftFactory())
      ..registerParamFactory<NoteTitleCard, String>(
        const NoteTitleCardFactory(),
      );
  }

  @override
  CobaltScopedState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends CobaltScopedState<NoteDetailScreen> {
  @override
  Widget buildScoped(BuildContext context) {
    final l10n = NotesL10n.of(context);
    final draft = context.cobalt<NoteDraft>();
    final card = context.cobaltWithParam<NoteTitleCard, String>(
      draft.text.isEmpty ? l10n.untitled : draft.text,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.widgetOwnedScope)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.scopeLine(context.cobaltScope.name),
              key: const Key('scope-name'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('draft-field'),
              decoration: InputDecoration(labelText: l10n.draft),
              onChanged: (value) => setState(() => draft.text = value),
            ),
            const SizedBox(height: 12),
            Text(card.rendered, key: const Key('rendered')),
            const Spacer(),
            Text(l10n.widgetScopeExplained),
          ],
        ),
      ),
    );
  }
}
