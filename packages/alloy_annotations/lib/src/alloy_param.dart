import 'package:meta/meta_meta.dart';

/// Marks a constructor parameter as a value the call site supplies.
///
/// Everything else in a constructor comes from the graph. This is for what the
/// container cannot know — a record id, a route argument, a flag chosen on the
/// screen that opened this one.
///
/// The class is then registered as a parameterized factory, and resolved with
/// `getWithParam` rather than `get`. The generator writes the argument type
/// beside the container as a named record built from the marked parameters:
///
/// ```dart
/// @alloyInject
/// class NoteEditor {
///   NoteEditor(this._notes, {@alloyParam required this.id, @alloyParam this.draft = false});
///
///   final NoteRepository _notes;
///   final int id;
///   final bool draft;
/// }
///
/// // typedef $NoteEditorArgs = ({int id, bool draft});
/// context.alloyWithParam<NoteEditor, $NoteEditorArgs>((id: 7, draft: true));
/// ```
///
/// A record even for a single value, and a named one: adding a second argument
/// then changes what you pass rather than the name of the type, and the call
/// site keeps reading like the constructor it stands for.
///
/// Not compatible with `@AlloyInit` — the runtime has no asynchronous
/// parameterized factory — nor with a singleton lifetime, since a scope never
/// retains what it builds from a call-site value.
@Target({TargetKind.parameter})
class AlloyParam {
  /// Marks the parameter.
  const AlloyParam();
}

/// The one you write: `@alloyParam`.
const alloyParam = AlloyParam();
