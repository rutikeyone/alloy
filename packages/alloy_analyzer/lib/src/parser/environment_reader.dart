import 'package:alloy_analyzer/src/parser/alloy_matchers.dart';
import 'package:alloy_analyzer/src/parser/dart_object_reader.dart';
import 'package:analyzer/dart/element/element.dart';

/// The environment names declared on [element] by `@AlloyEnvironment`.
///
/// Empty means the declaration named no environment and belongs to every
/// graph. The annotation may be repeated, so this collects all of them.
///
/// Takes any [Element] rather than a class, because a module member carries
/// the same annotation.
Set<String> environmentsOf(Element element) => {
  for (final annotation in environmentMatcher.allOf(element))
    ?annotation.readString('name'),
};
