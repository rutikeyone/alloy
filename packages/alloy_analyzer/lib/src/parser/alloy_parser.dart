import 'package:alloy_analyzer/src/model/library_declarations.dart';
import 'package:alloy_analyzer/src/parser/bootstrap_parser.dart';
import 'package:alloy_analyzer/src/parser/injectable_parser.dart';
import 'package:alloy_analyzer/src/parser/scope_root_parser.dart';
import 'package:analyzer/dart/element/element.dart';

/// Reads every Alloy declaration out of one library.
class AlloyParser {
  const AlloyParser();

  static const _injectables = AlloyInjectableParser();
  static const _bootstrap = AlloyBootstrapParser();
  static const _scopeRoot = AlloyScopeRootParser();

  /// Collects the injectables, bootstrap steps and scope roots declared in
  /// [library]. Throws `AlloyParseError` for a declaration Alloy cannot use.
  AlloyLibraryDeclarations parseLibrary(LibraryElement library) {
    final classes = library.classes;

    return AlloyLibraryDeclarations(
      injectables: [
        for (final clazz in classes)
          if (_injectables.declares(clazz)) _injectables.parseClass(clazz),
      ],
      bootstrapSteps: [
        for (final clazz in classes)
          if (_bootstrap.declares(clazz)) _bootstrap.parseClass(clazz),
      ],
      scopeRoots: [
        for (final clazz in classes)
          if (_scopeRoot.declares(clazz)) _scopeRoot.parseClass(clazz),
      ],
    );
  }
}
