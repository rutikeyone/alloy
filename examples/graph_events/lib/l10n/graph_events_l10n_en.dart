// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'graph_events_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class GraphEventsL10nEn extends GraphEventsL10n {
  GraphEventsL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Alloy · observability';

  @override
  String get liveLog => 'the live log';

  @override
  String get everyEvent => 'Every event below is the graph reporting itself';

  @override
  String get everyEventDetail =>
      'AlloyTalkerObserver files each kind under its own title, so the log screen can filter them apart.';

  @override
  String get openSession => 'Open a session scope';

  @override
  String get openSessionDetail => 'a push, an async init, some instances';

  @override
  String get openBrokenSession => 'Open one that will not close';

  @override
  String get openBrokenSessionDetail => 'its teardown throws, on purpose';

  @override
  String get closeSession => 'Close the session';

  @override
  String get nothingOpen => 'nothing open';

  @override
  String scopeNamed(String name) {
    return 'scope \"$name\"';
  }

  @override
  String get eventsRecorded => 'Events recorded';

  @override
  String get noFailures => 'No failures reported';

  @override
  String get noFailuresDetail => 'close the session that will not close';

  @override
  String reportSummary(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count breadcrumbs',
      one: '1 breadcrumb',
    );
    return '$kind · $_temp0';
  }
}
