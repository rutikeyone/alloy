import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';

Future<ClassElement> classNamed(String name, String source) async {
  final library = await libraryFrom(source);
  return library.classes.firstWhere((clazz) => clazz.name == name);
}

/// The resolved library for [source].
Future<LibraryElement> libraryFrom(String source) async => resolveSource(
  '''
library test_input;

import 'package:alloy_annotations/alloy_annotations.dart';

$source
''',
  (resolver) async => (await resolver.findLibraryByName('test_input'))!,
  // The input has to live in a package that depends on alloy_annotations,
  // and the real sources have to be readable — otherwise the annotations
  // resolve to null and every matcher silently says "not annotated".
  inputId: AssetId('alloy_analyzer', 'lib/_test_input.dart'),
  readAllSourcesFromFilesystem: true,
);
