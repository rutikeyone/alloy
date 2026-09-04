import 'package:cobalt_test/cobalt_test.dart';
import 'package:test/test.dart';

/// Two gaps the first packages to actually use this one walked into.
void main() {
  test('a recorder takes a report from a type of your own', () {
    final recorder = DisposeRecorder()..record('mine');
    recorder.value('theirs').dispose();

    expect(
      recorder.entries,
      ['mine', 'theirs'],
      reason:
          'value and factory only help when the recorder supplies the '
          'object; a fixture with fields of its own reports for itself',
    );
  });

  test('a parameterized registration has a function factory too', () {
    final scope = cobaltTestRoot()
      ..registerParamFactory<String, int>(
        FnParamFactory((_, id) => 'ticket-$id'),
      );

    expect(scope.getWithParam<String, int>(7), 'ticket-7');
  });
}
