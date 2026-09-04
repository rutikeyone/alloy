import 'package:cobalt/cobalt.dart';
import 'package:notes_app/features/formatting/domain/note_formatter.dart';

@CobaltInject(name: 'plain', exposeAs: NoteFormatter)
class PlainFormatter implements NoteFormatter {
  PlainFormatter();

  @override
  String get label => 'plain';

  @override
  String format(String title) => title;
}
