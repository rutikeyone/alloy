// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'graph_events_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class GraphEventsL10nRu extends GraphEventsL10n {
  GraphEventsL10nRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Cobalt · наблюдаемость';

  @override
  String get liveLog => 'живой журнал';

  @override
  String get everyEvent =>
      'Каждое событие ниже — это граф, рассказывающий о себе';

  @override
  String get everyEventDetail =>
      'CobaltTalkerObserver кладёт каждый вид под свой заголовок, поэтому экран журнала умеет их разделять.';

  @override
  String get openSession => 'Открыть сессионный скоуп';

  @override
  String get openSessionDetail =>
      'пуш, async-инициализация, несколько объектов';

  @override
  String get openBrokenSession => 'Открыть тот, который не закроется';

  @override
  String get openBrokenSessionDetail =>
      'его разбор бросает исключение, намеренно';

  @override
  String get closeSession => 'Закрыть сессию';

  @override
  String get nothingOpen => 'ничего не открыто';

  @override
  String scopeNamed(String name) {
    return 'скоуп «$name»';
  }

  @override
  String get eventsRecorded => 'Событий записано';

  @override
  String get noFailures => 'Сбоев не зарегистрировано';

  @override
  String get noFailuresDetail => 'закройте сессию, которая не закроется';

  @override
  String reportSummary(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count крошки',
      many: '$count крошек',
      few: '$count крошки',
      one: '$count крошка',
    );
    return '$kind · $_temp0';
  }
}
