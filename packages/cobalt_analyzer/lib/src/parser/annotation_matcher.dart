import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';

const cobaltAnnotationsPackage = 'cobalt_annotations';

/// Matches an annotation by class name and owning package.
///
/// Matching on the package rather than the exact library path means moving a
/// declaration between files inside `cobalt_annotations` does not break the
/// generator, and test stubs of the annotations still resolve.
class CobaltAnnotationMatcher {
  const CobaltAnnotationMatcher(
    this.typeName, {
    this.package = cobaltAnnotationsPackage,
  });

  final String typeName;
  final String package;

  /// The first matching annotation on [element], evaluated to a constant, or
  /// `null` when there is none.
  DartObject? firstOf(Element element) => allOf(element).firstOrNull;

  /// Every matching annotation on [element], in source order.
  ///
  /// Annotations that may be repeated read this; [firstOf] is the single-use
  /// case expressed on top of it.
  List<DartObject> allOf(Element element) {
    final values = <DartObject>[];
    for (final annotation in element.metadata.annotations) {
      final value = annotation.computeConstantValue();
      final declaration = value?.type?.element;
      if (declaration == null || declaration.name != typeName) continue;

      final uri = declaration.library?.uri;
      if (uri == null || !_isFromPackage(uri)) continue;
      values.add(value!);
    }
    return values;
  }

  /// Whether [element] carries this annotation.
  bool matches(Element element) => firstOf(element) != null;

  bool _isFromPackage(Uri uri) =>
      uri.scheme == 'package' &&
      uri.pathSegments.isNotEmpty &&
      uri.pathSegments.first == package;
}
