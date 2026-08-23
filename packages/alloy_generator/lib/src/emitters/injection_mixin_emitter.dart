import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:code_builder/code_builder.dart';

class InjectionMixinEmitter {
  const InjectionMixinEmitter();

  String emit(AlloyInjectableClass declaration) {
    final mixin = Mixin(
      (b) => b
        ..name = '_\$${declaration.type.name}'
        ..implements.add(refer('AlloyInjectable'))
        ..methods.addAll([
          for (final property in declaration.properties) _setter(property),
          _onInject(declaration),
        ]),
    );

    return Library((b) => b..body.add(mixin))
        .accept(DartEmitter(useNullSafetySyntax: true))
        .toString();
  }

  Method _setter(AlloyInjectedProperty property) => Method(
    (m) => m
      ..name = property.field
      ..type = MethodType.setter
      ..requiredParameters.add(
        Parameter(
          (p) => p
            ..name = 'value'
            ..type = refer(_localTypeName(property.type)),
        ),
      ),
  );

  Method _onInject(AlloyInjectableClass declaration) => Method(
    (m) => m
      ..name = 'onInject'
      ..annotations.add(refer('override'))
      ..returns = refer('void')
      ..requiredParameters.add(
        Parameter(
          (p) => p
            ..name = 'resolver'
            ..type = refer('AlloyResolver'),
        ),
      )
      ..body = Block.of([
        for (final property in declaration.properties)
          refer(property.field).assign(_resolve(property)).statement,
      ]),
  );

  Expression _resolve(AlloyInjectedProperty property) {
    final name = property.name;
    return refer('resolver')
        .property('get')
        .call(
          const [],
          {if (name != null) 'name': literalString(name)},
          [refer(_localTypeName(property.type))],
        );
  }

  static String _localTypeName(AlloyTypeRef type) {
    final buffer = StringBuffer(type.name);
    if (type.typeArguments.isNotEmpty) {
      buffer
        ..write('<')
        ..write(type.typeArguments.map(_localTypeName).join(', '))
        ..write('>');
    }
    return buffer.toString();
  }
}
