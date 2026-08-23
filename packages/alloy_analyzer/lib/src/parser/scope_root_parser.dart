import 'package:alloy_analyzer/src/model/scope_root_class.dart';
import 'package:alloy_analyzer/src/parser/alloy_matchers.dart';
import 'package:alloy_analyzer/src/parser/dart_object_reader.dart';
import 'package:alloy_analyzer/src/parser/type_ref_resolver.dart';
import 'package:analyzer/dart/element/element.dart';

class AlloyScopeRootParser {
  const AlloyScopeRootParser();

  bool declares(ClassElement clazz) => scopeRootMatcher.matches(clazz);

  AlloyScopeRootClass parseClass(ClassElement clazz) {
    final annotation = scopeRootMatcher.firstOf(clazz)!;
    return AlloyScopeRootClass(
      type: typeRefOfElement(clazz),
      name: annotation.readString('name') ?? 'root',
    );
  }
}
