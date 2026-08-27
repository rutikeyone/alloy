import 'package:alloy_analyzer/src/model/injectable_class.dart';
import 'package:alloy_analyzer/src/model/injected_property.dart';
import 'package:alloy_analyzer/src/model/type_ref.dart';
import 'package:alloy_analyzer/src/parser/alloy_matchers.dart';
import 'package:alloy_analyzer/src/parser/dart_object_reader.dart';
import 'package:alloy_analyzer/src/parser/environment_reader.dart';
import 'package:alloy_analyzer/src/parser/parse_error.dart';
import 'package:alloy_analyzer/src/parser/type_ref_resolver.dart';
import 'package:alloy_annotations/alloy_annotations.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';

class AlloyInjectableParser {
  const AlloyInjectableParser();

  bool declares(ClassElement clazz) =>
      injectMatcher.matches(clazz) || initMatcher.matches(clazz);

  AlloyInjectableClass parseClass(ClassElement clazz) {
    final initAnnotation = initMatcher.firstOf(clazz);
    final isAsyncInit = initAnnotation != null;
    final annotation = injectMatcher.firstOf(clazz) ?? initAnnotation!;

    if (clazz.typeParameters.isNotEmpty) {
      final parameters = clazz.typeParameters
          .map((parameter) => parameter.displayName)
          .join(', ');
      throw AlloyParseError(
        '${clazz.displayName} declares type parameters <$parameters>, so there '
        'is no single instantiation to register. Annotate a concrete subtype, '
        'or expose one with @AlloyInject(exposeAs: ...).',
        clazz,
      );
    }

    final constructor = _constructorOf(clazz);
    final takesParams = constructor.formalParameters.any(paramMatcher.matches);

    for (final parameter in constructor.formalParameters) {
      if (!paramMatcher.matches(parameter) || !parameter.isOptional) continue;
      throw AlloyParseError(
        '${clazz.displayName} marks ${parameter.displayName} with @AlloyParam '
        'and leaves it optional. The record the call site passes has no '
        'defaults, so the default would never be used. Make it required, or '
        'make its type nullable and pass null.',
        clazz,
      );
    }

    if (takesParams && isAsyncInit) {
      throw AlloyParseError(
        '${clazz.displayName} is annotated with @AlloyInit and takes an '
        '@AlloyParam. There is no asynchronous parameterized factory: phase 1 '
        'builds what it finds, and a call-site value does not exist yet. Take '
        "the value through a child scope's registration instead.",
        clazz,
      );
    }

    if (takesParams &&
        _lifetimeOf(annotation, isAsyncInit: false) ==
            AlloyLifetime.singleton) {
      throw AlloyParseError(
        '${clazz.displayName} asks for a singleton and takes an @AlloyParam. '
        'A singleton is built while the container is assembled, when no call '
        'site has supplied anything yet. Drop the lifetime — a parameterized '
        'registration is never retained by the scope.',
        clazz,
      );
    }

    if (isAsyncInit && !_hasInitMethod(clazz)) {
      throw AlloyParseError(
        '${clazz.displayName} is annotated with @AlloyInit but declares no '
        "'Future<void> init()' method. Implement AsyncInitializable.",
        clazz,
      );
    }

    return AlloyInjectableClass(
      type: typeRefOfElement(clazz),
      lifetime: _lifetimeOf(annotation, isAsyncInit: isAsyncInit),
      name: annotation.readString('name'),
      exposeAs: _exposeAsOf(annotation),
      isAsyncInit: isAsyncInit,
      dependsOn: _dependsOnOf(initAnnotation),
      environments: environmentsOf(clazz),
      constructorParameters: [
        for (final parameter in constructor.formalParameters)
          AlloyInjectedProperty(
            field: parameter.name ?? '',
            type: typeRefOf(parameter.type),
            name: namedMatcher.firstOf(parameter)?.readString('name'),
            isNamed: parameter.isNamed,
            isParam: paramMatcher.matches(parameter),
          ),
      ],
      properties: [
        for (final field in clazz.fields)
          if (injectedMatcher.matches(field)) _property(clazz, field),
      ],
    );
  }

  ConstructorElement _constructorOf(ClassElement clazz) {
    if (clazz.isAbstract) {
      throw AlloyParseError(
        '${clazz.displayName} is abstract and cannot be constructed.',
        clazz,
      );
    }

    final constructor = clazz.constructors
        .where((c) => c.isPublic && !c.isFactory)
        .firstOrNull;
    if (constructor == null) {
      throw AlloyParseError(
        '${clazz.displayName} has no public generative constructor.',
        clazz,
      );
    }
    return constructor;
  }

  bool _hasInitMethod(ClassElement clazz) =>
      clazz.methods.any((method) => method.name == 'init') ||
      clazz.allSupertypes.any(
        (supertype) => supertype.methods.any((method) => method.name == 'init'),
      );

  AlloyLifetime _lifetimeOf(
    DartObject annotation, {
    required bool isAsyncInit,
  }) {
    if (isAsyncInit) return AlloyLifetime.lazySingleton;
    final index = annotation.readEnumIndex('lifetime');
    return index == null
        ? AlloyLifetime.lazySingleton
        : AlloyLifetime.values[index];
  }

  AlloyTypeRef? _exposeAsOf(DartObject annotation) {
    final type = annotation.getField('exposeAs')?.toTypeValue();
    return type == null ? null : typeRefOf(type);
  }

  List<AlloyTypeRef> _dependsOnOf(DartObject? initAnnotation) {
    final values = initAnnotation?.getField('dependsOn')?.toListValue();
    if (values == null) return const [];
    return [
      for (final value in values)
        if (value.toTypeValue() case final type?) typeRefOf(type),
    ];
  }

  AlloyInjectedProperty _property(ClassElement clazz, FieldElement field) {
    if (field.isStatic) {
      throw AlloyParseError(
        '${clazz.displayName}.${field.displayName} is static and cannot be '
        'injected.',
        field,
      );
    }
    if (!field.isLate) {
      throw AlloyParseError(
        '${clazz.displayName}.${field.displayName} must be declared '
        '"late final" to receive property injection.',
        field,
      );
    }

    return AlloyInjectedProperty(
      field: field.displayName,
      type: typeRefOf(field.type),
      name:
          namedMatcher.firstOf(field)?.readString('name') ??
          injectedMatcher.firstOf(field)?.readString('name'),
    );
  }
}
