import 'package:alloy/alloy.dart';
import 'package:alloy_external_consumer/src/clock.dart';

/// A screen-scoped controller: some of it comes from the graph, the rest from
/// whoever opened the screen.
///
/// This is the shape that dominates a real application's DI — a repository or
/// two from the container, an id and a couple of flags from the route — and
/// the reason `@AlloyParam` exists.
@alloyInject
class NoteEditor {
  NoteEditor(
    this.clock, {
    @alloyParam required this.id,
    @alloyParam required this.title,
    @alloyParam this.draft = false,
  });

  final Clock clock;
  final int id;
  final String title;
  final bool draft;

  String describe() =>
      '$id "$title"${draft ? ' (draft)' : ''} at ${clock.now().toIso8601String()}';
}
