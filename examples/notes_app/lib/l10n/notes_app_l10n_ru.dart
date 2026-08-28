// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'notes_app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class NotesL10nRu extends NotesL10n {
  NotesL10nRu([String locale = 'ru']) : super(locale);

  @override
  String get twoPhaseStartup => 'Двухфазный старт';

  @override
  String get restartGraph => 'разобрать скоуп приложения и поднять новый';

  @override
  String get phaseZero => 'Фаза 0 — @AlloyBootstrap';

  @override
  String phaseZeroNote(String scope) {
    return 'усыновлены скоупом «$scope», освобождаются вместе с ним';
  }

  @override
  String get phaseOne => 'Фаза 1 — @AlloyInit';

  @override
  String get databaseOpen => 'база данных открыта';

  @override
  String get searchIndexBuilt => 'поисковый индекс построен';

  @override
  String get telemetryStarted => 'телеметрия запущена';

  @override
  String statusLine(String label, String value) {
    return '$label: $value';
  }

  @override
  String apiLine(String url) {
    return 'api: $url';
  }

  @override
  String get sessionScope => 'Сессионный скоуп';

  @override
  String signedInAs(String name) {
    return 'вошли как $name';
  }

  @override
  String get signedOut => 'не выполнен вход';

  @override
  String scopeLine(String name) {
    return 'скоуп: $name';
  }

  @override
  String get noScope => 'нет';

  @override
  String get signIn => 'войти';

  @override
  String get signOut => 'выйти';

  @override
  String get recordActivity => 'записать действие';

  @override
  String activityCount(int count) {
    return 'действий: $count';
  }

  @override
  String get sessionExplained =>
      'Выход разбирает сессионный скоуп. Всё, что построено внутри, уходит вместе с ним — никакого reset() ни в одном репозитории и ни одной подписки на сессию.';

  @override
  String get propertyInjection => 'Инъекция в поля';

  @override
  String get search => 'поиск';

  @override
  String noteCount(int count) {
    return 'всего: $count';
  }

  @override
  String newNote(int number) {
    return 'заметка $number';
  }

  @override
  String get widgetOwnedScope => 'Скоуп, которым владеет виджет';

  @override
  String get draft => 'черновик';

  @override
  String get untitled => 'без названия';

  @override
  String get widgetScopeExplained =>
      'Этот экран объявляет собственный скоуп. Уход с экрана его разбирает — больше об этом никому помнить не нужно.';

  @override
  String get scopeTree => 'Дерево скоупов';

  @override
  String get namedAndMulti => 'Именованные и множественная инъекция';

  @override
  String registrationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count регистрации',
      many: '$count регистраций',
      few: '$count регистрации',
      one: '$count регистрация',
    );
    return '$_temp0';
  }

  @override
  String get sampleNote => 'список покупок';

  @override
  String get environments => 'Окружения';

  @override
  String get activeEnvironment => 'активное окружение';

  @override
  String apiClientLine(String implementation, String detail) {
    return '$implementation → $detail';
  }

  @override
  String get noNetwork => 'без сети';

  @override
  String nothingRegistered(String environment) {
    return 'ничего не зарегистрировано — ни одна реализация не заявляет «$environment»';
  }

  @override
  String get crashReportingStep => 'bootstrap-шаг report-crashes';

  @override
  String get stepRan => 'выполнен';

  @override
  String get stepSkipped => 'пропущен в этом окружении';

  @override
  String get environmentsExplained =>
      'Обе реализации помечены одним и тем же exposeAs. Зарегистрирована только та, что называет это окружение, поэтому ниже по графу никто не знает, какая ему досталась. Выберите окружение, которого не заявляет никто, — и типа просто не будет: get<ApiClient>() бросит, а не вернёт не тот класс.';
}
