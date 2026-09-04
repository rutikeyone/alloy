import 'package:cobalt_generator/src/builders/container_builder.dart';
import 'package:cobalt_generator/src/generators/property_injection_generator.dart';
import 'package:cobalt_generator/src/generators/scan_generator.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

Builder cobaltPropertyInjectionBuilder(BuilderOptions options) =>
    SharedPartBuilder(const [PropertyInjectionGenerator()], 'cobalt');

Builder cobaltScanBuilder(BuilderOptions options) => LibraryBuilder(
  const CobaltScanGenerator(),
  generatedExtension: '.cobalt.json',
  formatOutput: (generated, _) =>
      generated.replaceAll(RegExp(r'^//.*$', multiLine: true), '').trim(),
);

Builder cobaltContainerBuilder(BuilderOptions options) =>
    const CobaltContainerBuilder();
