import 'package:cobalt/cobalt.dart';
import 'package:notes_app/features/formatting/domain/note_formatter.dart';

@CobaltInject(name: 'markdown', exposeAs: NoteFormatter)
class MarkdownFormatter implements NoteFormatter {
  MarkdownFormatter();

  @override
  String get label => 'markdown';

  @override
  String format(String title) => '# $title';
}
