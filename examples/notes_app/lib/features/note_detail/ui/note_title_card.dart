import 'package:alloy/alloy.dart';
import 'package:notes_app/features/formatting/domain/note_formatter.dart';

class NoteTitleCard {
  NoteTitleCard(this._formatter, this.title);

  final NoteFormatter _formatter;
  final String title;

  String get rendered => _formatter.format(title);
}

class NoteTitleCardFactory implements AlloyParamFactory<NoteTitleCard, String> {
  const NoteTitleCardFactory();

  @override
  NoteTitleCard create(AlloyResolver resolver, String param) =>
      NoteTitleCard(resolver.get<NoteFormatter>(name: 'markdown'), param);
}
