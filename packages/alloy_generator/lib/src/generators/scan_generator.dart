import 'dart:async';
import 'dart:convert';

import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

/// Writes the Alloy declarations of one library as JSON.
///
/// Phase one of generation. The output is cached rather than written to
/// source; only `AlloyContainerBuilder` reads it.
class AlloyScanGenerator implements Generator {
  const AlloyScanGenerator();

  static const _parser = AlloyParser();

  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) {
    final AlloyLibraryDeclarations declarations;
    try {
      declarations = _parser.parseLibrary(library.element);
    } on AlloyParseError catch (error) {
      throw InvalidGenerationSourceError(error.message, element: error.element);
    }

    if (declarations.isEmpty) return null;
    return jsonEncode(declarations.toJson());
  }
}
