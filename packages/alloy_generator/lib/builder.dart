import 'package:alloy_generator/src/builders/container_builder.dart';
import 'package:alloy_generator/src/generators/property_injection_generator.dart';
import 'package:alloy_generator/src/generators/scan_generator.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

Builder alloyPropertyInjectionBuilder(BuilderOptions options) =>
    SharedPartBuilder(const [PropertyInjectionGenerator()], 'alloy');

Builder alloyScanBuilder(BuilderOptions options) => LibraryBuilder(
  const AlloyScanGenerator(),
  generatedExtension: '.alloy.json',
  formatOutput: (generated, _) =>
      generated.replaceAll(RegExp(r'^//.*$', multiLine: true), '').trim(),
);

Builder alloyContainerBuilder(BuilderOptions options) =>
    const AlloyContainerBuilder();
