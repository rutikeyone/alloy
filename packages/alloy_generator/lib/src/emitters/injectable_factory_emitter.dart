import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:alloy_generator/src/emitters/alloy_references.dart';
import 'package:code_builder/code_builder.dart';

class InjectableFactoryEmitter {
  const InjectableFactoryEmitter();

  Class emit(AlloyInjectableClass declaration) {
    final concrete = typeReferenceOf(declaration.type);
    final exposed = typeReferenceOf(declaration.exposedType);
    final construction = concrete.newInstance([
      for (final parameter in declaration.constructorParameters)
        resolveCall(parameter),
    ]);

    return Class(
      (b) => b
        ..name = factoryNameOf(declaration)
        ..modifier = ClassModifier.final$
        ..implements.add(
          alloyGeneric(
            declaration.isAsyncInit ? 'AlloyAsyncFactory' : 'AlloyFactory',
            exposed,
          ),
        )
        ..constructors.add(Constructor((c) => c..constant = true))
        ..methods.add(
          declaration.isAsyncInit
              ? _asyncCreate(exposed, construction)
              : _syncCreate(exposed, construction),
        ),
    );
  }

  Method _syncCreate(Reference exposed, Expression construction) => Method(
    (m) => m
      ..name = 'create'
      ..annotations.add(refer('override'))
      ..returns = exposed
      ..requiredParameters.add(_resolverParameter)
      ..lambda = true
      ..body = construction.code,
  );

  Method _asyncCreate(Reference exposed, Expression construction) => Method(
    (m) => m
      ..name = 'create'
      ..annotations.add(refer('override'))
      ..modifier = MethodModifier.async
      ..returns = TypeReference(
        (b) => b
          ..symbol = 'Future'
          ..url = 'dart:async'
          ..types.add(exposed),
      )
      ..requiredParameters.add(_resolverParameter)
      ..body = Block.of([
        declareFinal('instance').assign(construction).statement,
        refer('instance').property('init').call(const []).awaited.statement,
        refer('instance').returned.statement,
      ]),
  );

  static final _resolverParameter = Parameter(
    (p) => p
      ..name = 'resolver'
      ..type = alloyRef('AlloyResolver'),
  );
}
