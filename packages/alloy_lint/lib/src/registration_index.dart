import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';

/// Every type name something in the package registers.
///
/// The generator answers "is this dependency registered?" from a fully
/// resolved, whole-package IR. A rule cannot: the analysis server hands it one
/// library at a time, and the only synchronous view of the others is their
/// parsed source. So this index is built from syntax, and is deliberately
/// coarser than `AlloyTypeRef.signature` in one direction only.
///
/// It holds bare type names — no library, no type arguments, no `@Named`
/// qualifier. Every one of those omissions makes the index match *more*, so
/// the rule stays silent in cases the build still rejects. Missing a report is
/// acceptable; inventing one from an editor that cannot see the whole graph is
/// not. The build remains the authority.
class AlloyRegistrationIndex {
  const AlloyRegistrationIndex(this.names);

  final Set<String> names;

  bool contains(String typeName) => names.contains(typeName);

  /// Reads [files], or returns null when any of them will not parse.
  ///
  /// Null rather than a partial index on purpose: a file that was skipped is a
  /// file whose registrations are missing, and the rule would then report them
  /// as unregistered. Silence is the only safe answer to an incomplete read.
  static AlloyRegistrationIndex? read(
    Iterable<String> files,
    AnalysisSession session,
  ) {
    final names = <String>{};
    for (final path in files) {
      final parsed = session.getParsedUnit(path);
      if (parsed is! ParsedUnitResult || parsed.diagnostics.isNotEmpty) {
        return null;
      }
      _collect(parsed.unit, names);
    }
    return AlloyRegistrationIndex(names);
  }

  static void _collect(CompilationUnit unit, Set<String> names) {
    for (final declaration in unit.declarations) {
      if (declaration is! ClassDeclaration) continue;
      for (final annotation in declaration.metadata) {
        switch (annotation.name.name.split('.').last) {
          case 'AlloyInject':
          case 'alloyInject':
          case 'alloySingleton':
          case 'alloyTransient':
          case 'AlloyInit':
          case 'alloyInit':
            names.add(declaration.namePart.typeName.lexeme);
            _addArgument(annotation, 'exposeAs', names);
          case 'AlloyScopeRoot':
            _addArgumentList(annotation, 'provides', names);
        }
      }
    }
  }

  static void _addArgument(
    Annotation annotation,
    String parameter,
    Set<String> names,
  ) {
    final value = _namedArgument(annotation, parameter);
    if (value != null) _addExpression(value, names);
  }

  static void _addArgumentList(
    Annotation annotation,
    String parameter,
    Set<String> names,
  ) {
    final value = _namedArgument(annotation, parameter);
    if (value is! ListLiteral) return;
    for (final element in value.elements) {
      if (element is Expression) _addExpression(element, names);
    }
  }

  static Expression? _namedArgument(Annotation annotation, String parameter) {
    for (final argument
        in annotation.arguments?.arguments ?? const <Argument>[]) {
      if (argument is NamedArgument && argument.name.lexeme == parameter) {
        return argument.argumentExpression;
      }
    }
    return null;
  }

  /// Reads the type an expression names, in every shape `provides` and
  /// `exposeAs` accept: `Foo`, `prefix.Foo`, `Repository<User>` and
  /// `AlloyProvided(Foo, name: 'x')`.
  static void _addExpression(Expression expression, Set<String> names) {
    switch (expression) {
      case SimpleIdentifier(:final name):
        names.add(name);
      case PrefixedIdentifier(identifier: SimpleIdentifier(:final name)):
        names.add(name);
      case TypeLiteral(:final type):
        names.add(type.name.lexeme);
      // Unresolved, `Repository<User>` is ambiguous — the parser cannot tell a
      // generic type from a generic function, and only rewrites it to a
      // TypeLiteral during resolution, which this index never gets.
      case FunctionReference(:final function):
        _addExpression(function, names);
      case InstanceCreationExpression(:final argumentList):
        _addFirstArgument(argumentList, names);
      case MethodInvocation(:final argumentList):
        _addFirstArgument(argumentList, names);
    }
  }

  static void _addFirstArgument(ArgumentList arguments, Set<String> names) {
    final first = arguments.arguments.firstOrNull;
    if (first != null) _addExpression(first.argumentExpression, names);
  }
}

/// Keeps one [AlloyRegistrationIndex] per package, rebuilt when a file
/// changes.
///
/// The rule needs the whole package to answer a question about one class, so
/// without this the package would be reparsed once per analysed library. What
/// makes caching affordable is that checking is far cheaper than building:
/// listing `lib` and reading modification stamps costs a stat per file,
/// parsing costs a parse per file.
class AlloyRegistrationIndexCache {
  final _byPackageRoot = <String, _CachedIndex>{};

  /// The index for the package rooted at [packageRoot], or null when it cannot
  /// be read whole.
  AlloyRegistrationIndex? of(Folder packageRoot, AnalysisSession session) {
    final lib = packageRoot.getFolder('lib');
    if (!lib.exists) return null;

    final stamps = <String, int>{};
    _stamp(lib, stamps);

    final cached = _byPackageRoot[packageRoot.path];
    if (cached != null && cached.matches(stamps)) return cached.index;

    final index = AlloyRegistrationIndex.read(stamps.keys, session);
    if (index == null) return null;

    _byPackageRoot[packageRoot.path] = _CachedIndex(stamps, index);
    return index;
  }

  static void _stamp(Folder folder, Map<String, int> stamps) {
    for (final child in folder.getChildren()) {
      if (child is Folder) {
        _stamp(child, stamps);
      } else if (child is File && child.path.endsWith('.dart')) {
        stamps[child.path] = child.modificationStamp;
      }
    }
  }
}

class _CachedIndex {
  _CachedIndex(this.stamps, this.index);

  final Map<String, int> stamps;
  final AlloyRegistrationIndex index;

  bool matches(Map<String, int> other) {
    if (other.length != stamps.length) return false;
    for (final entry in other.entries) {
      if (stamps[entry.key] != entry.value) return false;
    }
    return true;
  }
}
