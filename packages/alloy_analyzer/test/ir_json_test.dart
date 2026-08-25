import 'dart:convert';

import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:alloy_annotations/alloy_annotations.dart';
import 'package:test/test.dart';

AlloyLibraryDeclarations roundTrip(AlloyLibraryDeclarations declarations) =>
    AlloyLibraryDeclarations.fromJson(
      jsonDecode(jsonEncode(declarations.toJson())) as Map<String, dynamic>,
    );

const appImport = 'package:app/app.dart';

AlloyTypeRef ref(String name) => AlloyTypeRef(name: name, import: appImport);

void main() {
  group('the IR survives the trip through .alloy.json', () {
    test('a registration keeps its environments', () {
      final result = roundTrip(
        AlloyLibraryDeclarations(
          injectables: [
            AlloyInjectableClass(
              type: ref('SqlNotes'),
              exposeAs: ref('Notes'),
              lifetime: AlloyLifetime.lazySingleton,
              constructorParameters: const [],
              properties: const [],
              environments: const {'prod', 'stage'},
            ),
          ],
        ),
      );

      expect(result.injectables.single.environments, {'prod', 'stage'});
    });

    test('a bootstrap step keeps its environments', () {
      final result = roundTrip(
        AlloyLibraryDeclarations(
          bootstrapSteps: [
            AlloyBootstrapStepClass(
              type: ref('ReportCrashes'),
              order: 1,
              environments: const {'prod'},
            ),
          ],
        ),
      );

      expect(result.bootstrapSteps.single.environments, {'prod'});
    });

    test('naming no environment stays empty rather than becoming null', () {
      final result = roundTrip(
        AlloyLibraryDeclarations(
          injectables: [
            AlloyInjectableClass(
              type: ref('Logger'),
              lifetime: AlloyLifetime.lazySingleton,
              constructorParameters: const [],
              properties: const [],
            ),
          ],
        ),
      );

      expect(result.injectables.single.environments, isEmpty);
    });

    test('IR written before environments existed still reads', () {
      final legacy = {
        'injectables': [
          {
            'type': ref('Logger').toJson(),
            'lifetime': 'lazySingleton',
            'constructorParameters': <dynamic>[],
            'properties': <dynamic>[],
            'name': null,
            'exposeAs': null,
            'isAsyncInit': false,
            'dependsOn': <dynamic>[],
          },
        ],
      };

      final result = AlloyLibraryDeclarations.fromJson(legacy);

      expect(result.injectables.single.environments, isEmpty);
    });

    test('a scope root keeps what it promises is provided elsewhere', () {
      final result = roundTrip(
        AlloyLibraryDeclarations(
          scopeRoots: [
            AlloyScopeRootClass(
              type: ref('AppScope'),
              name: 'app',
              provides: [
                AlloyProvidedRef(type: ref('SessionManager')),
                AlloyProvidedRef(type: ref('Logger'), name: 'audit'),
              ],
            ),
          ],
        ),
      );

      final provides = result.scopeRoots.single.provides;
      expect(provides.map((p) => p.type.name), ['SessionManager', 'Logger']);
      expect(provides.map((p) => p.name), [null, 'audit']);
    });

    test('IR written before provides existed still reads', () {
      final legacy = {
        'scopeRoots': [
          {'type': ref('AppScope').toJson(), 'name': 'app'},
        ],
      };

      final result = AlloyLibraryDeclarations.fromJson(legacy);

      expect(result.scopeRoots.single.provides, isEmpty);
    });
  });
}
