import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:alloy_annotations/alloy_annotations.dart';
import 'package:alloy_generator/src/emitters/alloy_factory_names.dart';
import 'package:alloy_generator/src/emitters/alloy_references.dart';
import 'package:code_builder/code_builder.dart';

class RootScopeEmitter {
  const RootScopeEmitter();

  Class emit(
    List<AlloyInjectableClass> ordered,
    AlloyFactoryNames names, {
    required bool usesEnvironments,
  }) => Class(
    (b) => b
      ..name = r'$AlloyRootScope'
      ..modifier = ClassModifier.final$
      ..implements.add(alloyRef('AlloyScopeBuilder'))
      ..constructors.add(
        Constructor(
          (c) => c
            ..constant = true
            ..optionalParameters.addAll([
              if (usesEnvironments)
                Parameter(
                  (p) => p
                    ..name = 'environment'
                    ..named = true
                    ..toThis = true
                    ..defaultTo = defaultEnvironment.code,
                ),
            ]),
        ),
      )
      ..fields.addAll([
        if (usesEnvironments)
          Field(
            (f) => f
              ..name = 'environment'
              ..modifier = FieldModifier.final$
              ..type = alloyRef('AlloyEnvironment'),
          ),
      ])
      ..methods.add(
        Method(
          (m) => m
            ..name = 'build'
            ..annotations.add(refer('override'))
            ..returns = refer('void')
            ..requiredParameters.add(
              Parameter(
                (p) => p
                  ..name = 'scope'
                  ..type = alloyRef('AlloyScope'),
              ),
            )
            ..body = Block.of([
              for (final declaration in ordered)
                guardedBy(
                  declaration.environments,
                  _register(declaration, names),
                ),
            ]),
        ),
      ),
  );

  Code _register(AlloyInjectableClass declaration, AlloyFactoryNames names) {
    final exposed = typeReferenceOf(declaration.exposedType);
    final factory = refer(names.of(declaration)).constInstance(const []);

    final dispose = declaration.dispose;
    final named = <String, Expression>{
      if (declaration.name != null) 'name': literalString(declaration.name!),
      if (declaration.isAsyncInit && declaration.dependsOn.isNotEmpty)
        'dependsOn': literalSet({
          for (final dependency in declaration.dependsOn)
            alloyRef('AlloyKey').constInstance([typeReferenceOf(dependency)]),
        }),
      if (dispose != null) 'dispose': functionReferenceOf(dispose),
    };

    if (declaration.takesCallSiteValues) {
      return refer('scope')
          .property('registerParamFactory')
          .call([factory], named, [exposed, refer(names.argsOf(declaration))])
          .statement;
    }

    final method = declaration.isAsyncInit
        ? 'registerAsyncSingleton'
        : switch (declaration.lifetime) {
            AlloyLifetime.transient => 'registerFactory',
            AlloyLifetime.lazySingleton => 'registerLazySingleton',
            AlloyLifetime.singleton => 'registerSingleton',
          };

    final argument =
        !declaration.isAsyncInit &&
            declaration.lifetime == AlloyLifetime.singleton
        ? factory.property('create').call([refer('scope')])
        : factory;

    return refer('scope')
        .property(method)
        .call([argument], named, [exposed])
        .statement;
  }
}
