import 'package:meta/meta_meta.dart';

/// Fills the annotated field from the scope instead of from a constructor.
///
/// The field must be `late final`, and the class must mix in the generated
/// `_$ClassName`, which declares a setter for each annotated field and assigns
/// them all in `onInject`. The scope calls `onInject` immediately after the
/// constructor returns, so the fields are set before anyone can read them.
///
/// This is how a controller keeps an empty constructor no matter how many
/// dependencies it has:
///
/// ```dart
/// @cobaltTransient
/// class NotesController with _$NotesController {
///   NotesController();
///
///   @injected
///   late final NoteStore _store;
/// }
/// ```
///
/// `late final` still means write-once: a second assignment throws
/// `LateInitializationError`. Because the generated mixin lands in a part file
/// of the same library, private fields work.
@Target({TargetKind.field})
class Injected {
  /// Creates an annotation marking a field for property injection.
  const Injected({this.name});

  /// Resolves the named registration rather than the default one.
  final String? name;
}

/// Fills the annotated `late final` field from the scope.
const injected = Injected();
