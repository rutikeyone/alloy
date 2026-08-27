import 'package:alloy_analyzer/src/model/function_ref.dart';
import 'package:alloy_analyzer/src/model/injectable_class.dart';
import 'package:alloy_analyzer/src/model/injected_property.dart';
import 'package:alloy_analyzer/src/model/provider_ref.dart';
import 'package:alloy_analyzer/src/model/type_ref.dart';
import 'package:alloy_analyzer/src/parser/alloy_matchers.dart';
import 'package:alloy_analyzer/src/parser/dart_object_reader.dart';
import 'package:alloy_analyzer/src/parser/environment_reader.dart';
import 'package:alloy_analyzer/src/parser/parse_error.dart';
import 'package:alloy_analyzer/src/parser/type_ref_resolver.dart';
import 'package:alloy_annotations/alloy_annotations.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

/// Reads an `@AlloyModule` class into one registration per annotated member.
///
/// This is the only parser that is one-to-many: a module class is not itself
/// registered, it is a place to hang registrations of types the package does
/// not own.
class AlloyModuleParser {
  const AlloyModuleParser();

  bool declares(ClassElement clazz) => moduleMatcher.matches(clazz);

  List<AlloyInjectableClass> parseClass(ClassElement clazz) {
    _assertUsable(clazz);
    final module = typeRefOfElement(clazz);

    return [
      for (final member in [...clazz.getters, ...clazz.methods])
        if (injectMatcher.matches(member)) _parseMember(clazz, module, member),
    ];
  }

  void _assertUsable(ClassElement clazz) {
    if (clazz.isAbstract) {
      throw AlloyParseError(
        '${clazz.displayName} is abstract, so its members cannot be called. '
        'A module is an ordinary class with a const constructor.',
        clazz,
      );
    }
    if (clazz.typeParameters.isNotEmpty) {
      throw AlloyParseError(
        '${clazz.displayName} declares type parameters, so there is no single '
        'instance to call its members on.',
        clazz,
      );
    }
    final usable = clazz.constructors.any(
      (constructor) =>
          constructor.isPublic &&
          !constructor.isFactory &&
          constructor.isConst &&
          constructor.formalParameters.isEmpty &&
          _isUnnamed(constructor),
    );
    if (!usable) {
      throw AlloyParseError(
        '${clazz.displayName} needs a public const constructor taking no '
        'arguments, so the generated factory can hold '
        'const ${clazz.displayName}() and carry no state of its own.',
        clazz,
      );
    }
  }

  static bool _isUnnamed(ConstructorElement constructor) {
    final name = constructor.name;
    return name == null || name.isEmpty || name == 'new';
  }

  AlloyInjectableClass _parseMember(
    ClassElement clazz,
    AlloyTypeRef module,
    ExecutableElement member,
  ) {
    final where = '${clazz.displayName}.${member.displayName}';

    if (initMatcher.matches(member)) {
      throw AlloyParseError(
        '$where is annotated with @AlloyInit, which a module member does not '
        'take. Return Future<T> instead — that is what makes it async.',
        member,
      );
    }
    if (member.isStatic) {
      throw AlloyParseError(
        '$where is static. Module members are called on '
        'const ${clazz.displayName}(), so they have to be instance members.',
        member,
      );
    }
    if (member.isAbstract) {
      throw AlloyParseError(
        '$where is abstract, so there is no body to call. Register the class '
        'itself with @AlloyInject, and publish it under another type with '
        '@AlloyInject(exposeAs: ...).',
        member,
      );
    }
    if (member is MethodElement && member.typeParameters.isNotEmpty) {
      throw AlloyParseError(
        '$where declares type parameters, so there is no single '
        'instantiation to register.',
        member,
      );
    }

    final annotation = injectMatcher.firstOf(member)!;
    final produced = _producedType(member, where);
    final isAsync = member.returnType.isDartAsyncFuture;
    final lifetime = _lifetimeOf(annotation, isAsync: isAsync);
    final dispose = _disposeOf(annotation, where, member);

    if (dispose != null && lifetime == AlloyLifetime.transient && !isAsync) {
      throw AlloyParseError(
        '$where is transient and also names a dispose function. The scope '
        'does not retain a transient, so it could never call it.',
        member,
      );
    }

    return AlloyInjectableClass(
      type: produced,
      lifetime: lifetime,
      name: annotation.readString('name'),
      exposeAs: _exposeAsOf(annotation),
      isAsyncInit: isAsync,
      environments: environmentsOf(member),
      constructorParameters: [
        for (final parameter in member.formalParameters)
          _parameter(parameter, where, member),
      ],
      properties: const [],
      provider: AlloyProviderRef(
        module: module,
        member: member.displayName,
        isGetter: member is GetterElement,
      ),
      dispose: dispose,
    );
  }

  /// The type the member registers, with one `Future` layer removed.
  ///
  /// A member returning `Future<T>` registers `T` and is built during startup;
  /// nothing else in Alloy treats `Future` specially, so leaving it wrapped
  /// would register `Future<T>` and leave every consumer of `T` unsatisfied.
  AlloyTypeRef _producedType(ExecutableElement member, String where) {
    final returnType = member.returnType;
    var produced = returnType;

    if (returnType.isDartAsyncFuture) {
      final arguments = returnType is InterfaceType
          ? returnType.typeArguments
          : const <DartType>[];
      // A bare `Future` is `Future<dynamic>`, so it arrives here with an
      // argument rather than without one.
      if (arguments.length != 1 || arguments.single is DynamicType) {
        throw AlloyParseError(
          '$where returns a bare Future, so there is no type to register. '
          'Return Future<T> naming what it produces.',
          member,
        );
      }
      produced = arguments.single;
    }

    if (produced is DynamicType ||
        produced is VoidType ||
        produced is NeverType ||
        produced.element == null) {
      throw AlloyParseError(
        '$where returns ${produced.getDisplayString()}, which is not a type '
        'Alloy can register. Return a class.',
        member,
      );
    }

    if (produced.nullabilitySuffix == NullabilitySuffix.question) {
      throw AlloyParseError(
        '$where returns ${produced.getDisplayString()}, and a registration '
        'cannot be nullable — a nullable type marks a *dependency* optional, '
        'not a provider. Return the non-nullable type.',
        member,
      );
    }

    return typeRefOf(produced);
  }

  AlloyInjectedProperty _parameter(
    FormalParameterElement parameter,
    String where,
    ExecutableElement member,
  ) {
    if (paramMatcher.matches(parameter)) {
      throw AlloyParseError(
        '$where takes an @AlloyParam. A module registers types you did not '
        'write, and a call-site value belongs to a class you did — put '
        '@AlloyParam on its constructor instead.',
        member,
      );
    }
    if (parameter.isOptional) {
      throw AlloyParseError(
        '$where takes the optional parameter ${parameter.displayName}. Every '
        'parameter is resolved from the scope, so there is nothing for an '
        'optional one to mean.',
        member,
      );
    }
    return AlloyInjectedProperty(
      field: parameter.name ?? '',
      type: typeRefOf(parameter.type),
      name: namedMatcher.firstOf(parameter)?.readString('name'),
      isNamed: parameter.isNamed,
    );
  }

  AlloyLifetime _lifetimeOf(DartObject annotation, {required bool isAsync}) {
    if (isAsync) return AlloyLifetime.lazySingleton;
    final index = annotation.readEnumIndex('lifetime');
    return index == null
        ? AlloyLifetime.lazySingleton
        : AlloyLifetime.values[index];
  }

  AlloyTypeRef? _exposeAsOf(DartObject annotation) {
    final type = annotation.getField('exposeAs')?.toTypeValue();
    return type == null ? null : typeRefOf(type);
  }

  AlloyFunctionRef? _disposeOf(
    DartObject annotation,
    String where,
    ExecutableElement member,
  ) {
    final function = annotation.getField('dispose')?.toFunctionValue();
    if (function == null) return null;

    final owner = function.enclosingElement;
    if (owner is ClassElement) {
      if (!function.isStatic) {
        throw AlloyParseError(
          '$where names ${function.displayName} as its dispose function, but '
          'that is an instance method. Point at a top-level or static '
          'function.',
          member,
        );
      }
      return AlloyFunctionRef(
        name: function.displayName,
        import: owner.library.uri.toString(),
        owner: owner.displayName,
      );
    }

    return AlloyFunctionRef(
      name: function.displayName,
      import: function.library.uri.toString(),
    );
  }
}
