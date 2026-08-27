import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:alloy_generator/src/emitters/injection_mixin_emitter.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

/// Emits the `_$ClassName` mixin that fills `@injected` fields.
///
/// Runs as a shared part builder, so the mixin lands in the same library as
/// the class and can therefore assign private fields. Classes without
/// `@injected` fields produce nothing.
///
/// Which classes count is decided by [AlloyInjectableParser.declares], the
/// same reading the container uses, and that is the point: `@AlloyInit` makes
/// a class injectable too, so a class annotated with it alone used to be
/// registered by the container and left without a mixin. Its fields were never
/// assigned and it failed with a `LateInitializationError` at first use, while
/// the lint told you to mix in something the generator was never going to
/// write.
class PropertyInjectionGenerator implements Generator {
  /// Creates the generator.
  const PropertyInjectionGenerator();

  static const _parser = AlloyInjectableParser();
  static const _emitter = InjectionMixinEmitter();

  @override
  String? generate(LibraryReader library, BuildStep buildStep) {
    final mixins = <String>[];

    for (final clazz in library.element.classes) {
      if (!_parser.declares(clazz)) continue;

      final AlloyInjectableClass parsed;
      try {
        parsed = _parser.parseClass(clazz);
      } on AlloyParseError catch (error) {
        throw InvalidGenerationSourceError(
          error.message,
          element: error.element,
        );
      }

      if (!parsed.hasPropertyInjection) continue;
      mixins.add(_emitter.emit(parsed));
    }

    if (mixins.isEmpty) return null;
    return mixins.join('\n\n');
  }

  /// Names the banner source_gen writes above the output.
  ///
  /// `GeneratorForAnnotation` prints this for free; a plain [Generator] would
  /// otherwise put `Instance of '...'` into every generated file.
  @override
  String toString() => 'PropertyInjectionGenerator';
}
