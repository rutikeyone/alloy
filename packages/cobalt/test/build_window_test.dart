import 'package:cobalt/cobalt.dart';
import 'package:cobalt_test/cobalt_test.dart';
import 'package:test/test.dart';

class Gen {}

class Manual {
  Manual(this.gen);

  final Gen gen;
}

/// Registers eagerly *before* the thing it needs, which is the shape a
/// migration lands in: hand-written registrations at the top of `build()`,
/// the generated container at the bottom.
class TooEager implements CobaltScopeBuilder {
  const TooEager();

  @override
  void build(CobaltScope scope) {
    scope
      ..registerSingleton<Manual>(Manual(scope.get<Gen>()))
      ..registerLazySingleton<Gen>(FnFactory((_) => Gen()));
  }
}

/// The same two registrations, the lazy way round.
class Patient implements CobaltScopeBuilder {
  const Patient();

  @override
  void build(CobaltScope scope) {
    scope
      ..registerLazySingleton<Manual>(FnFactory((r) => Manual(r.get<Gen>())))
      ..registerLazySingleton<Gen>(FnFactory((_) => Gen()));
  }
}

void main() {
  test('a lazy registration does not care what order build() ran in', () async {
    final scope = cobaltTestRoot()..runBuilder(const Patient());

    expect(scope.get<Manual>().gen, isA<Gen>());
  });

  test('an eager one does, and the error says so', () async {
    final scope = cobaltTestRoot();

    expect(
      () => scope.runBuilder(const TooEager()),
      throwsA(
        isA<CobaltNotRegisteredError>()
            .having((it) => it.whileBuilding, 'whileBuilding', isTrue)
            .having(
              (it) => it.toString(),
              'message',
              contains('still being built'),
            ),
      ),
    );
  });

  test('outside a builder the message does not guess', () async {
    final scope = cobaltTestRoot();

    expect(
      () => scope.get<Gen>(),
      throwsA(
        isA<CobaltNotRegisteredError>()
            .having((it) => it.whileBuilding, 'whileBuilding', isFalse)
            .having(
              (it) => it.toString(),
              'message',
              isNot(contains('still being built')),
            ),
      ),
    );
  });

  test('the window closes even when the builder throws', () async {
    final scope = cobaltTestRoot();

    expect(() => scope.runBuilder(const TooEager()), throwsA(anything));
    expect(
      () => scope.get<Gen>(),
      throwsA(
        isA<CobaltNotRegisteredError>().having(
          (it) => it.whileBuilding,
          'whileBuilding',
          isFalse,
        ),
      ),
      reason: 'a builder that threw must not leave the window open',
    );
  });
}
