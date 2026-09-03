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

/// The type of one field of a call-site record.
///
/// Unlike [typeReferenceOf] this keeps the `?`. That function deliberately
/// drops it, because it also builds `registerLazySingleton<T>` and
/// `AlloyKey(T)`, where nullability would change the registration. A record
/// field is the opposite case: dropping it there narrows the argument, so a
/// constructor willing to take null would be handed a type that cannot
/// express it.
Reference recordFieldTypeOf(AlloyTypeRef type) {
  if (!type.isNullable) return typeReferenceOf(type);
  return TypeReference(
    (b) => b
      ..symbol = type.name
      ..url = type.import
      ..isNullable = true
      ..types.addAll([for (final a in type.typeArguments) typeReferenceOf(a)]),
  );
}

/// Refers to a function the generated code calls by name.
Expression functionReferenceOf(AlloyFunctionRef function) {
  final owner = function.owner;
  return owner == null
      ? refer(function.name, function.import)
      : refer(owner, function.import).property(function.name);
}

/// Emits the resolve for one dependency.
///
/// A nullable dependency reads through `getOrNull`, so a graph that does not
/// register it injects null instead of failing. The type argument stays
/// non-nullable either way — `getOrNull<Foo>()` returns `Foo?`, and
/// `AlloyResolver` bounds every type parameter to `Object`.
///
/// The branch belongs here rather than in [typeReferenceOf]: that one also
/// builds `registerLazySingleton<T>` and `AlloyKey(T)`, where a `?` would
/// change the registration itself.
Expression resolveCall(AlloyInjectedProperty dependency) {
  final name = dependency.name;
  return refer('resolver')
      .property(dependency.type.isNullable ? 'getOrNull' : 'get')
      .call(
        const [],
        {if (name != null) 'name': literalString(name)},
        [typeReferenceOf(dependency.type)],
      );
}

Expression get defaultEnvironment =>
    alloyRef('AlloyEnvironment').property('defaultEnvironment');

Expression environmentGuard(Set<String> environments) =>
    refer('environment').property('matches').call([
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
