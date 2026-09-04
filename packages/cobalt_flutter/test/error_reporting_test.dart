import 'package:cobalt_flutter/cobalt_flutter.dart';
import 'package:cobalt_test/cobalt_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class Stubborn implements Disposable {
  @override
  void dispose() => throw StateError('will not close');
}

final class StubbornScope implements CobaltScopeBuilder {
  const StubbornScope();

  @override
  void build(CobaltScope scope) =>
      scope.registerSingleton<Stubborn>(Stubborn());
}

void main() {
  late List<FlutterErrorDetails> reported;

  /// The handler has to be replaced inside the test body: `testWidgets`
  /// installs the binding's own during its setup, so anything put in place
  /// from `setUp` is overwritten before the first pump.
  void capture() {
    reported = [];
    final previous = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = previous);
  }

  /// The paths that run when teardown fails and no widget is left to render
  /// it. Dropping the error there would be the quiet kind of loss, so both
  /// report — and until now nothing checked that they do.
  ///
  /// `CobaltScopeWidget` has a third report, for an `init()` that fails after
  /// unmount. It is not driven here: the widget's own dispose awaits that same
  /// future behind the teardown deadline, so a widget test reaches the branch
  /// only by sitting out a timer, and forcing it would have tested the clock
  /// rather than the code.
  group('a failure with nobody left to show it', () {
    testWidgets('a teardown that throws on unmount is reported', (
      tester,
    ) async {
      capture();
      await tester.pumpWidget(
        CobaltScopeProvider(
          scope: cobaltTestRoot(name: 'app'),
          child: const CobaltScopeWidget(
            name: 'session',
            builder: StubbornScope(),
            child: SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      expect(reported, hasLength(1));
      expect(reported.single.exception, isA<CobaltDisposeError>());
      expect(reported.single.context.toString(), contains('session'));
    });

    testWidgets('CobaltAppScope reports a root it could not release', (
      tester,
    ) async {
      capture();
      await tester.pumpWidget(
        const CobaltAppScope(
          root: StubbornScope(),
          rootName: 'app',
          child: SizedBox(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      expect(reported, hasLength(1));
      expect(reported.single.exception, isA<CobaltDisposeError>());
      expect(
        reported.single.context.toString(),
        contains('the root scope owned by CobaltAppScope'),
      );
    });
  });
}
