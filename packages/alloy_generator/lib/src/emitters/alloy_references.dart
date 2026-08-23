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
  final suffix = declaration.name == null
      ? ''
      : '${declaration.name![0].toUpperCase()}${declaration.name!.substring(1)}';
  return '_${declaration.type.name}${suffix}Factory';
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
