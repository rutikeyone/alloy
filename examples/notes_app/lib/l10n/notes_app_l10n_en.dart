// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'notes_app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class NotesL10nEn extends NotesL10n {
  NotesL10nEn([String locale = 'en']) : super(locale);

  @override
  String get twoPhaseStartup => 'Two-phase startup';

  @override
  String get restartGraph => 'dispose the app scope and start a new one';

  @override
  String get phaseZero => 'Phase 0 — @AlloyBootstrap';

  @override
  String phaseZeroNote(String scope) {
    return 'adopted by scope \"$scope\", released when it is disposed';
  }

  @override
  String get phaseOne => 'Phase 1 — @AlloyInit';

  @override
  String get databaseOpen => 'database open';

  @override
  String get searchIndexBuilt => 'search index built';

  @override
  String get telemetryStarted => 'telemetry started';

  @override
  String statusLine(String label, String value) {
    return '$label: $value';
  }

  @override
  String apiLine(String url) {
    return 'api: $url';
  }

  @override
  String get sessionScope => 'Session scope';

  @override
  String signedInAs(String name) {
    return 'signed in as $name';
  }

  @override
  String get signedOut => 'signed out';

  @override
  String scopeLine(String name) {
    return 'scope: $name';
  }

  @override
  String get noScope => 'none';

  @override
  String get signIn => 'sign in';

  @override
  String get signOut => 'sign out';

  @override
  String get recordActivity => 'record activity';

  @override
  String activityCount(int count) {
    return 'activity: $count';
  }

  @override
  String get sessionExplained =>
      'Signing out disposes the session scope. Everything built inside it goes with it — no reset() on any repository, no session listener anywhere.';

  @override
  String get propertyInjection => 'Property injection';

  @override
  String get search => 'search';

  @override
  String noteCount(int count) {
    return 'count: $count';
  }

  @override
  String newNote(int number) {
    return 'note $number';
  }

  @override
  String get widgetOwnedScope => 'Widget-owned scope';

  @override
  String get draft => 'draft';

  @override
  String get untitled => 'untitled';

  @override
  String get widgetScopeExplained =>
      'This screen declares its own scope. Leaving it disposes the scope — nothing else has to remember to.';

  @override
  String get scopeTree => 'Scope tree';

  @override
  String get namedAndMulti => 'Named and multi-injection';

  @override
  String registrationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registrations',
      one: '1 registration',
    );
    return '$_temp0';
  }

  @override
  String get sampleNote => 'shopping list';

  @override
  String get environments => 'Environments';

  @override
  String get activeEnvironment => 'active environment';

  @override
  String apiClientLine(String implementation, String detail) {
    return '$implementation → $detail';
  }

  @override
  String get noNetwork => 'no network';

  @override
  String nothingRegistered(String environment) {
    return 'nothing registered — no implementation claims \"$environment\"';
  }

  @override
  String get crashReportingStep => 'report-crashes bootstrap step';

  @override
  String get stepRan => 'ran';

  @override
  String get stepSkipped => 'skipped in this environment';

  @override
  String get environmentsExplained =>
      'Both implementations are annotated with the same exposeAs. Only the one naming this environment is registered, so nothing downstream knows which it got. Pick an environment nobody claims and the type is simply absent — get<ApiClient>() would throw rather than hand back the wrong class.';
}
