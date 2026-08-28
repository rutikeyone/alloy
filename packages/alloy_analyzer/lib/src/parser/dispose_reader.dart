import 'package:alloy_analyzer/src/model/function_ref.dart';
import 'package:alloy_analyzer/src/parser/parse_error.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';

/// The function `dispose:` names on [annotation], or null when it names none.
///
/// Shared by the class parser and the module parser because both read the same
/// field of the same annotation. It used to live only in the module parser,
/// and the class path therefore accepted `dispose:` and silently dropped it —
/// the registration was emitted without one and the instance was never closed.
AlloyFunctionRef? disposeOf(DartObject annotation, String where, Element at) {
  final function = annotation.getField('dispose')?.toFunctionValue();
  if (function == null) return null;

  final owner = function.enclosingElement;
  if (owner is! ClassElement) {
    return AlloyFunctionRef(
      name: function.displayName,
      import: function.library.uri.toString(),
    );
  }

  if (!function.isStatic) {
    throw AlloyParseError(
      '$where names ${function.displayName} as its dispose function, but that '
      'is an instance method. Point at a top-level or static function.',
      at,
    );
  }

  return AlloyFunctionRef(
    name: function.displayName,
    import: owner.library.uri.toString(),
    owner: owner.displayName,
  );
}
