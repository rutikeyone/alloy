import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:code_builder/code_builder.dart';

const alloyUrl = 'package:alloy/alloy.dart';

Reference alloyRef(String symbol) => refer(symbol, alloyUrl);

TypeReference alloyGeneric(String symbol, Reference argument) => TypeReference(
  (b) => b
    ..symbol = symbol
    ..url = alloyUrl
    ..types.add(argument),
);

Reference typeReferenceOf(AlloyTypeRef type) {
  if (type.typeArguments.isEmpty) return refer(type.name, type.import);
  return TypeReference(
    (b) => b
      ..symbol = type.name
      ..url = type.import
      ..types.addAll([for (final a in type.typeArguments) typeReferenceOf(a)]),
  );
}

String factoryNameOf(AlloyInjectableClass declaration) {
  final suffix = _capitalised(declaration.name);
  final provider = declaration.provider;
  // A module member is named after where it lives, not after what it returns:
  // two modules may legitimately both provide a Dio, and naming both factories
  // after the return type would put two _DioFactory classes in one file.
  if (provider != null) {
    return '_${provider.module.name}${_capitalised(provider.member)}'
        '${suffix}Factory';
  }
  return '_${declaration.type.name}${suffix}Factory';
}

String _capitalised(String? value) => value == null || value.isEmpty
    ? ''
    : '${value[0].toUpperCase()}${value.substring(1)}';

/// Refers to a function the generated code calls by name.
Expression functionReferenceOf(AlloyFunctionRef function) {
  final owner = function.owner;
  return owner == null
      ? refer(function.name, function.import)
      : refer(owner, function.import).property(function.name);
}

Expression resolveCall(AlloyInjectedProperty dependency) {
  final name = dependency.name;
  return refer('resolver')
      .property('get')
      .call(
        const [],
        {if (name != null) 'name': literalString(name)},
        [typeReferenceOf(dependency.type)],
      );
}

Expression get defaultEnvironment =>
    alloyRef('AlloyEnvironment').property('defaultEnvironment');

Expression environmentGuard(Set<String> environments) => refer('environment')
    .property('matches')
    .call([
      literalConstSet(
        (environments.toList()..sort()).toSet(),
        refer('String', 'dart:core'),
      ),
    ]);

Code guardedBy(Set<String> environments, Code statement) => environments.isEmpty
    ? statement
    : Block.of([
        const Code('if ('),
        environmentGuard(environments).code,
        const Code(') {'),
        statement,
        const Code('}'),
      ]);
