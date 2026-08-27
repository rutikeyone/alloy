import 'dart:convert';

import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:alloy_annotations/alloy_annotations.dart';
import 'package:alloy_generator/alloy_generator.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

/// One library's IR, as `alloy_scan` writes it.
String ir(List<AlloyInjectableClass> injectables) => jsonEncode(
  AlloyLibraryDeclarations(
    injectables: injectables,
    bootstrapSteps: const [],
    scopeRoots: const [],
  ).toJson(),
);

AlloyInjectableClass declaredIn(String library, String name) =>
    AlloyInjectableClass(
      type: AlloyTypeRef(name: name, import: library),
      lifetime: AlloyLifetime.lazySingleton,
      constructorParameters: const [],
      properties: const [],
    );

void main() {
  group('the container builder', () {
    test('writes nothing when the package declares nothing', () async {
      await testBuilder(const AlloyContainerBuilder(), {
        'app|lib/plain.dart': 'class Plain {}',
      }, outputs: const {});
    });

    test('writes nothing when every scanned library was empty', () async {
      await testBuilder(const AlloyContainerBuilder(), {
        'app|lib/empty.alloy.json': ir(const []),
      }, outputs: const {});
    });

    /// The whole reason generation is two-phase.
    ///
    /// build_runner hands a builder one library at a time, so the container —
    /// which is a fact about the package, not about any library — can only be
    /// assembled by a second pass over what the first one left behind.
    test('merges the IR of several libraries into one container', () async {
      await testBuilder(
        const AlloyContainerBuilder(),
        {
          'app|lib/a.alloy.json': ir([declaredIn('package:app/a.dart', 'A')]),
          'app|lib/b.alloy.json': ir([declaredIn('package:app/b.dart', 'B')]),
        },
        outputs: {
          'app|lib/alloy.g.dart': decodedMatches(
            allOf(
              contains('_AFactory'),
              contains('_BFactory'),
              contains(r'class $AlloyRootScope'),
            ),
          ),
        },
      );
    });

    test('writes into the package it was asked about', () async {
      await testBuilder(
        const AlloyContainerBuilder(),
        {
          'other|lib/a.alloy.json': ir([
            declaredIn('package:other/a.dart', 'A'),
          ]),
        },
        rootPackage: 'other',
        outputs: {
          'other|lib/alloy.g.dart': decodedMatches(contains('_AFactory')),
        },
      );
    });
  });
}
