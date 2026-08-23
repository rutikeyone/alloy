import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:alloy_generator/src/emitters/injection_mixin_emitter.dart';
import 'package:alloy_annotations/alloy_annotations.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

/// Emits the `_$ClassName` mixin that fills `@injected` fields.
///
/// Runs as a shared part builder, so the mixin lands in the same library as
/// the class and can therefore assign private fields. Classes without
/// `@injected` fields produce nothing.
class PropertyInjectionGenerator extends GeneratorForAnnotation<AlloyInject> {
  const PropertyInjectionGenerator();

  static const _parser = AlloyInjectableParser();
  static const _emitter = InjectionMixinEmitter();

  @override
  String? generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@AlloyInject can only be applied to classes.',
        element: element,
      );
    }

    final AlloyInjectableClass parsed;
    try {
      parsed = _parser.parseClass(element);
    } on AlloyParseError catch (error) {
      throw InvalidGenerationSourceError(error.message, element: error.element);
    }

    if (!parsed.hasPropertyInjection) return null;
    return _emitter.emit(parsed);
  }
}
