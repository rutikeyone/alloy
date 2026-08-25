import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:alloy_generator/src/emitters/alloy_references.dart';
import 'package:code_builder/code_builder.dart';

class InjectableFactoryEmitter {
  const InjectableFactoryEmitter();

  Class emit(AlloyInjectableClass declaration) {
    final exposed = typeReferenceOf(declaration.exposedType);
    final provider = declaration.provider;
    final construction = provider == null
        ? _construct(declaration)
        : _callProvider(declaration, provider);

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
        ..methods.add(switch ((declaration.isAsyncInit, provider)) {
          (false, _) => _syncCreate(exposed, construction),
          // A module member is the whole job already: awaiting the call is
          // all there is. A class is constructed first and initialised after.
          (true, != null) => _awaitCreate(exposed, construction),
          (true, _) => _asyncCreate(exposed, construction),
        }),
    );
  }

  Expression _construct(AlloyInjectableClass declaration) =>
      typeReferenceOf(declaration.type).newInstance([
        for (final parameter in declaration.constructorParameters)
          resolveCall(parameter),
      ]);

  Expression _callProvider(
    AlloyInjectableClass declaration,
    AlloyProviderRef provider,
  ) {
    final module = typeReferenceOf(provider.module).constInstance(const []);
    final member = module.property(provider.member);
    if (provider.isGetter) return member;
    return member.call([
      for (final parameter in declaration.constructorParameters)
        resolveCall(parameter),
    ]);
  }

  Method _awaitCreate(Reference exposed, Expression call) => Method(
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
      ..lambda = true
      ..body = call.awaited.code,
  );

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
