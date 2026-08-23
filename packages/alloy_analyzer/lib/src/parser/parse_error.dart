import 'package:analyzer/dart/element/element.dart';

/// A declaration Alloy cannot turn into a registration.
///
/// Carries the offending [element] so the generator can point `build_runner`
/// at the exact source location.
class AlloyParseError implements Exception {
  AlloyParseError(this.message, this.element);

  final String message;
  final Element element;

  @override
  String toString() => 'AlloyParseError: $message';
}
