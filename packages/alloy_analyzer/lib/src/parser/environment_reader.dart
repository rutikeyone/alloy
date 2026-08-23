import 'package:alloy_analyzer/src/parser/alloy_matchers.dart';
import 'package:alloy_analyzer/src/parser/dart_object_reader.dart';
import 'package:analyzer/dart/element/element.dart';

/// The environment names declared on [clazz] by `@AlloyEnvironment`.
///
/// Empty means the declaration named no environment and belongs to every
/// graph. The annotation may be repeated, so this collects all of them.
Set<String> environmentsOf(ClassElement clazz) => {
  for (final annotation in environmentMatcher.allOf(clazz))
    ?annotation.readString('name'),
};
