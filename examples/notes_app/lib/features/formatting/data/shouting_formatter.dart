import 'package:cobalt/cobalt.dart';
import 'package:notes_app/features/formatting/domain/note_formatter.dart';

@CobaltInject(name: 'shouting', exposeAs: NoteFormatter)
class ShoutingFormatter implements NoteFormatter {
  ShoutingFormatter();

  @override
  String get label => 'shouting';

  @override
  String format(String title) => '${title.toUpperCase()}!';
}
