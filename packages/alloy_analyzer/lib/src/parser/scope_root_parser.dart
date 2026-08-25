import 'package:alloy_analyzer/src/model/provided_ref.dart';
import 'package:alloy_analyzer/src/model/scope_root_class.dart';
import 'package:alloy_analyzer/src/parser/alloy_matchers.dart';
import 'package:alloy_analyzer/src/parser/dart_object_reader.dart';
import 'package:alloy_analyzer/src/parser/parse_error.dart';
import 'package:alloy_analyzer/src/parser/type_ref_resolver.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';

class AlloyScopeRootParser {
  const AlloyScopeRootParser();

  bool declares(ClassElement clazz) => scopeRootMatcher.matches(clazz);

  AlloyScopeRootClass parseClass(ClassElement clazz) {
    final annotation = scopeRootMatcher.firstOf(clazz)!;
    return AlloyScopeRootClass(
      type: typeRefOfElement(clazz),
      name: annotation.readString('name') ?? 'root',
      provides: _providesOf(annotation, clazz),
    );
  }

  List<AlloyProvidedRef> _providesOf(
    DartObject annotation,
    ClassElement clazz,
  ) {
    final values = annotation.getField('provides')?.toListValue();
    if (values == null) return const [];
    return [for (final value in values) _provided(value, clazz)];
  }

  AlloyProvidedRef _provided(DartObject value, ClassElement clazz) {
    if (value.toTypeValue() case final type?) {
      return AlloyProvidedRef(type: typeRefOf(type));
    }
    if (value.getField('type')?.toTypeValue() case final type?) {
      return AlloyProvidedRef(
        type: typeRefOf(type),
        name: value.readString('name'),
      );
    }
    throw AlloyParseError(
      '${clazz.displayName} lists something in provides that is neither a '
      'type nor an AlloyProvided. Write the type itself, or '
      "AlloyProvided(Type, name: 'qualifier') when the registration is named.",
      clazz,
    );
  }
}
