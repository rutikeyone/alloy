import 'package:alloy/alloy.dart';
import 'package:alloy_logger/alloy_logger.dart';
import 'package:logger/logger.dart' as pretty;
import 'package:test/test.dart';

void main() {
  late List<pretty.LogEvent> events;
  late void Function(pretty.LogEvent) listener;
  late AlloyLoggerSink sink;

  setUp(() {
    events = [];
    listener = events.add;
    pretty.Logger.addLogListener(listener);
    sink = AlloyLoggerSink(
      logger: pretty.Logger(level: pretty.Level.trace, output: _SilentOutput()),
    );
  });

  tearDown(() => pretty.Logger.removeLogListener(listener));

  group('AlloyLoggerSink', () {
    test('every Alloy level maps onto a real logger level', () {
      expect(AlloyLoggerSink.levelOf(AlloyLogLevel.trace), pretty.Level.trace);
      expect(AlloyLoggerSink.levelOf(AlloyLogLevel.debug), pretty.Level.debug);
      expect(AlloyLoggerSink.levelOf(AlloyLogLevel.info), pretty.Level.info);
      expect(
        AlloyLoggerSink.levelOf(AlloyLogLevel.warning),
        pretty.Level.warning,
      );
      expect(AlloyLoggerSink.levelOf(AlloyLogLevel.error), pretty.Level.error);
      expect(
        [
          pretty.Level.all,
          pretty.Level.off,
        ].contains(AlloyLoggerSink.levelOf(AlloyLogLevel.trace)),
        isFalse,
        reason: 'Logger.log throws ArgumentError on all/off',
      );
    });

    test('a record reaches the logger with its error attached', () {
      final boom = StateError('boom');
      sink.write(
        AlloyLogRecord(
          kind: AlloyEventKind.scopeInitFailed,
          level: AlloyLogLevel.error,
          message: 'it broke',
          error: boom,
        ),
      );

      expect(events.single.message, 'it broke');
      expect(events.single.level, pretty.Level.error);
      expect(events.single.error, same(boom));
    });

    test('the graph drives it end to end', () async {
      final root = AlloyScope.root(
        name: 'app',
        observers: [AlloyLogObserver(sink)],
      );
      root.push('session');
      await root.dispose();

      expect(
        events.map((e) => e.message),
        containsAllInOrder(<Object>[
          'scope "app/session" pushed',
          'scope "app/session" disposing',
        ]),
      );
    });
  });
}

class _SilentOutput extends pretty.LogOutput {
  @override
  void output(pretty.OutputEvent event) {}
}
