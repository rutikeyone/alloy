import 'package:cobalt/cobalt.dart';

@cobaltInject
class EventLog implements Disposable {
  EventLog();

  final entries = <String>[];
  var isClosed = false;

  void record(String entry) => entries.add(entry);

  @override
  void dispose() {
    record('event-log closed');
    isClosed = true;
  }
}
