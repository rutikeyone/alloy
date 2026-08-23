import 'package:alloy/alloy.dart';
import 'package:notes_app/core/event_log.dart';

class NoteDraft implements Disposable {
  NoteDraft(this._log);

  final EventLog _log;

  var text = '';
  var isDiscarded = false;

  @override
  void dispose() {
    isDiscarded = true;
    _log.record('draft discarded');
  }
}

class NoteDraftFactory implements AlloyFactory<NoteDraft> {
  const NoteDraftFactory();

  @override
  NoteDraft create(AlloyResolver resolver) =>
      NoteDraft(resolver.get<EventLog>());
}
