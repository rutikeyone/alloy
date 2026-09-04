import 'dart:async';
import 'dart:convert';

import 'package:cobalt_analyzer/cobalt_analyzer.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

/// Writes the Cobalt declarations of one library as JSON.
///
/// Phase one of generation. The output is cached rather than written to
/// source; only `CobaltContainerBuilder` reads it.
class CobaltScanGenerator implements Generator {
  const CobaltScanGenerator();

  static const _parser = CobaltParser();

  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) {
    final CobaltLibraryDeclarations declarations;
    try {
      declarations = _parser.parseLibrary(library.element);
    } on CobaltParseError catch (error) {
      throw InvalidGenerationSourceError(error.message, element: error.element);
    }

    if (declarations.isEmpty) return null;
    return jsonEncode(declarations.toJson());
  }
}
