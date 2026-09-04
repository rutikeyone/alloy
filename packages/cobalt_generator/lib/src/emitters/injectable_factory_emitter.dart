import 'package:cobalt_analyzer/cobalt_analyzer.dart';
import 'package:cobalt_generator/src/emitters/cobalt_factory_names.dart';
import 'package:cobalt_generator/src/emitters/cobalt_references.dart';
import 'package:code_builder/code_builder.dart';

class InjectableFactoryEmitter {
  const InjectableFactoryEmitter();

  Class emit(CobaltInjectableClass declaration, CobaltFactoryNames names) {
    final exposed = typeReferenceOf(declaration.exposedType);
    final provider = declaration.provider;
    final construction = provider == null
        ? _construct(declaration)
        : _callProvider(declaration, provider);

    final args = declaration.takesCallSiteValues
        ? refer(names.argsOf(declaration))
        : null;

    return Class(
      (b) => b
        ..name = names.of(declaration)
        ..modifier = ClassModifier.final$
        ..implements.add(
          args != null
              ? TypeReference(
                  (t) => t
                    ..symbol = 'CobaltParamFactory'
                    ..url = cobaltUrl
                    ..types.addAll([exposed, args]),
                )
              : cobaltGeneric(
                  declaration.isAsyncInit
                      ? 'CobaltAsyncFactory'
                      : 'CobaltFactory',
                  exposed,
                ),
        )
        ..constructors.add(Constructor((c) => c..constant = true))
        ..methods.add(switch ((args, declaration.isAsyncInit, provider)) {
          (final Reference args, _, _) => _paramCreate(
            exposed,
            args,
            construction,
          ),
          (_, false, _) => _syncCreate(exposed, construction),
          // A module member is the whole job already: awaiting the call is
          // all there is. A class is constructed first and initialised after.
          (_, true, != null) => _awaitCreate(exposed, construction),
          (_, true, _) => _asyncCreate(exposed, construction),
        }),
    );
  }

  /// Rebuilds the constructor call the way it was declared.
  ///
  /// Positional and named have to be kept apart: passing a named parameter
  /// positionally produces a file that does not compile, and every injectable
  /// class in this repository's own examples happens to be positional, so
  /// nothing noticed until a production graph was read.
  Expression _construct(CobaltInjectableClass declaration) =>
      typeReferenceOf(declaration.type).newInstance(
        [
          for (final parameter in declaration.constructorParameters)
            if (!parameter.isNamed) _argument(parameter),
        ],
        {
          for (final parameter in declaration.constructorParameters)
            if (parameter.isNamed) parameter.field: _argument(parameter),
        },
      );

  /// Where one argument comes from: the call site, or the graph.
  Expression _argument(CobaltInjectedProperty parameter) => parameter.isParam
      ? refer('args').property(parameter.field)
      : resolveCall(parameter);

  Expression _callProvider(
    CobaltInjectableClass declaration,
    CobaltProviderRef provider,
  ) {
    final module = typeReferenceOf(provider.module).constInstance(const []);
    final member = module.property(provider.member);
    if (provider.isGetter) return member;
    return member.call(
      [
        for (final parameter in declaration.constructorParameters)
          if (!parameter.isNamed) resolveCall(parameter),
      ],
      {
        for (final parameter in declaration.constructorParameters)
          if (parameter.isNamed) parameter.field: resolveCall(parameter),
      },
    );
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

  Method _paramCreate(
    Reference exposed,
    Reference args,
    Expression construction,
  ) => Method(
    (m) => m
      ..name = 'create'
      ..annotations.add(refer('override'))
      ..returns = exposed
      ..requiredParameters.addAll([
        _resolverParameter,
        Parameter(
          (p) => p
            ..name = 'args'
            ..type = args,
        ),
      ])
      ..lambda = true
      ..body = construction.code,
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
      ..type = cobaltRef('CobaltResolver'),
  );
}
