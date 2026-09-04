import 'dart:convert';
import 'dart:io';

import 'package:cobalt_analyzer/cobalt_analyzer.dart';
import 'package:cobalt_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

import 'builder_support.dart';

/// Sources live under `cobalt_generator` so the resolver has this package's
/// dependencies in hand.
const _pkg = 'cobalt_generator';

void main() {
  final builder = cobaltScanBuilder(const BuilderOptions({}));
  late PackageConfig packages;
  late Map<String, Object> deps;

  setUpAll(() async {
    packages = (await findPackageConfig(Directory.current))!;
    deps = sourcesOf(packages, 'cobalt_annotations')
      ..addAll(sourcesOf(packages, 'meta'));
  });

  group('the scan builder', () {
    test('leaves a library with no annotations alone', () async {
      await testBuilder(
        builder,
        {...deps, '$_pkg|lib/plain.dart': 'class Plain {\n  Plain();\n}\n'},
        packageConfig: packages,
        generateFor: {'$_pkg|lib/plain.dart'},
        outputs: const {},
      );
    });

    test('writes IR that decodes back into declarations', () async {
      String? written;

      await testBuilder(
        builder,
        {
          ...deps,
          '$_pkg|lib/graph.dart': '''
import 'package:cobalt_annotations/cobalt_annotations.dart';

@cobaltInject
class Logger {
  Logger();
}

@cobaltInject
class Api {
  Api(this.logger);
  final Logger logger;
}
''',
        },
        packageConfig: packages,
        generateFor: {'$_pkg|lib/graph.dart'},
        outputs: {
          '$_pkg|lib/graph.cobalt.json': decodedMatches(
            predicate<String>((value) {
              written = value;
              return true;
            }),
          ),
        },
      );

      final decoded = CobaltLibraryDeclarations.fromJson(
        jsonDecode(written!) as Map<String, dynamic>,
      );
      expect(
        decoded.injectables.map((declaration) => declaration.type.name),
        containsAll(['Logger', 'Api']),
        reason:
            'an empty result here would mean the annotations resolved to '
            'nothing, not that the library declares nothing',
      );
      expect(
        decoded.injectables
            .firstWhere((declaration) => declaration.type.name == 'Api')
            .constructorParameters
            .single
            .type
            .name,
        'Logger',
      );
    });

    /// A parse failure is reported, not thrown: build_runner catches it and
    /// logs it at severe, which is what fails the build for a real consumer.
    test('reports a declaration it cannot parse, and writes nothing', () async {
      final severe = <String>[];

      await testBuilder(
        builder,
        {
          ...deps,
          '$_pkg|lib/broken.dart': '''
import 'package:cobalt_annotations/cobalt_annotations.dart';

@cobaltInject
abstract class Store {}
''',
        },
        packageConfig: packages,
        generateFor: {'$_pkg|lib/broken.dart'},
        outputs: const {},
        onLog: (LogRecord record) {
          if (record.level >= Level.SEVERE) severe.add(record.toString());
        },
      );

      expect(
        severe.join('\n'),
        allOf(contains('Store'), contains('abstract')),
        reason: 'the message has to name the class, not the builder',
      );
    });
  });
}
