import 'dart:io';

import 'package:alloy_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

import 'builder_support.dart';

const _pkg = 'alloy_generator';

void main() {
  final builder = alloyPropertyInjectionBuilder(const BuilderOptions({}));
  late PackageConfig packages;
  late Map<String, Object> deps;

  setUpAll(() async {
    packages = (await findPackageConfig(Directory.current))!;
    deps = sourcesOf(packages, 'alloy_annotations')
      ..addAll(sourcesOf(packages, 'meta'));
  });

  group('the property injection builder', () {
    /// Most annotated classes take their dependencies through the
    /// constructor. Emitting an empty part for them would make `part` a
    /// requirement of `@AlloyInject` rather than of `@injected`.
    test('writes nothing for a class with no injected fields', () async {
      await testBuilder(
        builder,
        {
          ...deps,
          '$_pkg|lib/plain.dart': '''
import 'package:alloy_annotations/alloy_annotations.dart';

@alloyInject
class Api {
  Api(this.logger);
  final Object logger;
}
''',
        },
        packageConfig: packages,
        generateFor: {'$_pkg|lib/plain.dart'},
        outputs: const {},
      );
    });

    test('emits a mixin that can assign a private field', () async {
      await testBuilder(
        builder,
        {
          ...deps,
          '$_pkg|lib/controller.dart': '''
import 'package:alloy_annotations/alloy_annotations.dart';

class Store {}

@alloyTransient
class Controller {
  Controller();

  @injected
  late final Store _store;
}
''',
        },
        packageConfig: packages,
        generateFor: {'$_pkg|lib/controller.dart'},
        outputs: {
          '$_pkg|lib/controller.alloy.g.part': decodedMatches(
            allOf(
              contains(r'mixin _$Controller implements AlloyInjectable'),
              contains('set _store('),
              contains('void onInject(AlloyResolver resolver)'),
            ),
          ),
        },
      );
    });
  });
}
