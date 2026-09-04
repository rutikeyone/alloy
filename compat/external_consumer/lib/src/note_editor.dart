import 'package:cobalt/cobalt.dart';
import 'package:cobalt_external_consumer/src/clock.dart';

/// A screen-scoped controller: some of it comes from the graph, the rest from
/// whoever opened the screen.
///
/// This is the shape that dominates a real application's DI — a repository or
/// two from the container, an id and a couple of flags from the route — and
/// the reason `@CobaltParam` exists.
@cobaltInject
class NoteEditor {
  NoteEditor(
    this.clock, {
    @cobaltParam required this.id,
    @cobaltParam required this.title,
    @cobaltParam required this.draft,
  });

  final Clock clock;
  final int id;
  final String title;
  final bool draft;

  String describe() =>
      '$id "$title"${draft ? ' (draft)' : ''} at ${clock.now().toIso8601String()}';
}
