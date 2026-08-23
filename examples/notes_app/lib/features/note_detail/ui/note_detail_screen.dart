import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/features/note_detail/ui/note_draft.dart';
import 'package:notes_app/features/note_detail/ui/note_title_card.dart';

class NoteDetailScreen extends AlloyScopedStatefulWidget {
  const NoteDetailScreen({super.key});

  @override
  Widget get loading => const Center(child: CircularProgressIndicator());

  @override
  void registerScope(AlloyScope scope) {
    scope
      ..registerLazySingleton<NoteDraft>(const NoteDraftFactory())
      ..registerParamFactory<NoteTitleCard, String>(
        const NoteTitleCardFactory(),
      );
  }

  @override
  AlloyScopedState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends AlloyScopedState<NoteDetailScreen> {
  @override
  Widget buildScoped(BuildContext context) {
    final draft = context.alloy<NoteDraft>();
    final card = context.alloyWithParam<NoteTitleCard, String>(
      draft.text.isEmpty ? 'untitled' : draft.text,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Widget-owned scope')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'scope: ${context.alloyScope.name}',
              key: const Key('scope-name'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('draft-field'),
              decoration: const InputDecoration(labelText: 'draft'),
              onChanged: (value) => setState(() => draft.text = value),
            ),
            const SizedBox(height: 12),
            Text(card.rendered, key: const Key('rendered')),
            const Spacer(),
            const Text(
              'This screen declares its own scope. Leaving it disposes the '
              'scope — nothing else has to remember to.',
            ),
          ],
        ),
      ),
    );
  }
}
