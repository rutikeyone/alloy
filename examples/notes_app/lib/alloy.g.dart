// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:alloy/alloy.dart' as _i178;
import 'package:notes_app/bootstrap/bind_platform.dart' as _i253;
import 'package:notes_app/bootstrap/load_remote_config.dart' as _i536;
import 'package:notes_app/bootstrap/report_crashes.dart' as _i861;
import 'package:notes_app/bootstrap/warm_fonts.dart' as _i31;
import 'package:notes_app/core/app_config.dart' as _i189;
import 'package:notes_app/core/clock.dart' as _i510;
import 'package:notes_app/core/event_log.dart' as _i153;
import 'package:notes_app/features/diagnostics/data/telemetry.dart' as _i816;
import 'package:notes_app/features/environments/data/fake_api_client.dart'
    as _i256;
import 'package:notes_app/features/environments/data/live_api_client.dart'
    as _i214;
import 'package:notes_app/features/environments/domain/api_client.dart'
    as _i238;
import 'package:notes_app/features/formatting/data/markdown_formatter.dart'
    as _i251;
import 'package:notes_app/features/formatting/data/plain_formatter.dart'
    as _i774;
import 'package:notes_app/features/formatting/data/shouting_formatter.dart'
    as _i652;
import 'package:notes_app/features/formatting/domain/note_formatter.dart'
    as _i293;
import 'package:notes_app/features/notes/data/note_database.dart' as _i41;
import 'package:notes_app/features/notes/data/note_repository.dart' as _i98;
import 'package:notes_app/features/notes/data/search_index.dart' as _i501;
import 'package:notes_app/features/notes/domain/note_store.dart' as _i387;
import 'package:notes_app/features/notes/ui/notes_controller.dart' as _i1050;

final class _AppConfigFactory implements _i178.AlloyFactory<_i189.AppConfig> {
  const _AppConfigFactory();

  @override
  _i189.AppConfig create(_i178.AlloyResolver resolver) => _i189.AppConfig();
}

final class _ClockFactory implements _i178.AlloyFactory<_i510.Clock> {
  const _ClockFactory();

  @override
  _i510.Clock create(_i178.AlloyResolver resolver) => _i510.Clock();
}

final class _EventLogFactory implements _i178.AlloyFactory<_i153.EventLog> {
  const _EventLogFactory();

  @override
  _i153.EventLog create(_i178.AlloyResolver resolver) => _i153.EventLog();
}

final class _TelemetryFactory
    implements _i178.AlloyAsyncFactory<_i816.Telemetry> {
  const _TelemetryFactory();

  @override
  _i687.Future<_i816.Telemetry> create(_i178.AlloyResolver resolver) async {
    final instance = _i816.Telemetry(resolver.get<_i153.EventLog>());
    await instance.init();
    return instance;
  }
}

final class _FakeApiClientFactory
    implements _i178.AlloyFactory<_i238.ApiClient> {
  const _FakeApiClientFactory();

  @override
  _i238.ApiClient create(_i178.AlloyResolver resolver) => _i256.FakeApiClient();
}

final class _LiveApiClientFactory
    implements _i178.AlloyFactory<_i238.ApiClient> {
  const _LiveApiClientFactory();

  @override
  _i238.ApiClient create(_i178.AlloyResolver resolver) =>
      _i214.LiveApiClient(resolver.get<_i189.AppConfig>());
}

final class _MarkdownFormatterMarkdownFactory
    implements _i178.AlloyFactory<_i293.NoteFormatter> {
  const _MarkdownFormatterMarkdownFactory();

  @override
  _i293.NoteFormatter create(_i178.AlloyResolver resolver) =>
      _i251.MarkdownFormatter();
}

final class _PlainFormatterPlainFactory
    implements _i178.AlloyFactory<_i293.NoteFormatter> {
  const _PlainFormatterPlainFactory();

  @override
  _i293.NoteFormatter create(_i178.AlloyResolver resolver) =>
      _i774.PlainFormatter();
}

final class _ShoutingFormatterShoutingFactory
    implements _i178.AlloyFactory<_i293.NoteFormatter> {
  const _ShoutingFormatterShoutingFactory();

  @override
  _i293.NoteFormatter create(_i178.AlloyResolver resolver) =>
      _i652.ShoutingFormatter();
}

final class _NoteDatabaseFactory
    implements _i178.AlloyAsyncFactory<_i41.NoteDatabase> {
  const _NoteDatabaseFactory();

  @override
  _i687.Future<_i41.NoteDatabase> create(_i178.AlloyResolver resolver) async {
    final instance = _i41.NoteDatabase(resolver.get<_i153.EventLog>());
    await instance.init();
    return instance;
  }
}

final class _SearchIndexFactory
    implements _i178.AlloyAsyncFactory<_i501.SearchIndex> {
  const _SearchIndexFactory();

  @override
  _i687.Future<_i501.SearchIndex> create(_i178.AlloyResolver resolver) async {
    final instance = _i501.SearchIndex(
      resolver.get<_i41.NoteDatabase>(),
      resolver.get<_i153.EventLog>(),
    );
    await instance.init();
    return instance;
  }
}

final class _NoteRepositoryFactory
    implements _i178.AlloyFactory<_i387.NoteStore> {
  const _NoteRepositoryFactory();

  @override
  _i387.NoteStore create(_i178.AlloyResolver resolver) => _i98.NoteRepository(
    resolver.get<_i41.NoteDatabase>(),
    resolver.get<_i501.SearchIndex>(),
    resolver.get<_i510.Clock>(),
  );
}

final class _NotesControllerFactory
    implements _i178.AlloyFactory<_i1050.NotesController> {
  const _NotesControllerFactory();

  @override
  _i1050.NotesController create(_i178.AlloyResolver resolver) =>
      _i1050.NotesController();
}

final class $AlloyRootScope implements _i178.AlloyScopeBuilder {
  const $AlloyRootScope({
    this.environment = _i178.AlloyEnvironment.defaultEnvironment,
  });

  final _i178.AlloyEnvironment environment;

  @override
  void build(_i178.AlloyScope scope) {
    scope.registerSingleton<_i189.AppConfig>(
      const _AppConfigFactory().create(scope),
    );
    scope.registerLazySingleton<_i510.Clock>(const _ClockFactory());
    scope.registerLazySingleton<_i153.EventLog>(const _EventLogFactory());
    if (environment.matches(const <String>{'dev', 'test'})) {
      scope.registerLazySingleton<_i238.ApiClient>(
        const _FakeApiClientFactory(),
      );
    }
    scope.registerLazySingleton<_i293.NoteFormatter>(
      const _MarkdownFormatterMarkdownFactory(),
      name: 'markdown',
    );
    scope.registerLazySingleton<_i293.NoteFormatter>(
      const _PlainFormatterPlainFactory(),
      name: 'plain',
    );
    scope.registerLazySingleton<_i293.NoteFormatter>(
      const _ShoutingFormatterShoutingFactory(),
      name: 'shouting',
    );
    scope.registerAsyncSingleton<_i816.Telemetry>(const _TelemetryFactory());
    if (environment.matches(const <String>{'prod', 'stage'})) {
      scope.registerLazySingleton<_i238.ApiClient>(
        const _LiveApiClientFactory(),
      );
    }
    scope.registerAsyncSingleton<_i41.NoteDatabase>(
      const _NoteDatabaseFactory(),
    );
    scope.registerAsyncSingleton<_i501.SearchIndex>(
      const _SearchIndexFactory(),
      dependsOn: {const _i178.AlloyKey(_i41.NoteDatabase)},
    );
    scope.registerLazySingleton<_i387.NoteStore>(
      const _NoteRepositoryFactory(),
    );
    scope.registerFactory<_i1050.NotesController>(
      const _NotesControllerFactory(),
    );
  }
}

List<_i178.AlloyBootstrapStep> $alloyBootstrap(
  _i178.AlloyEnvironment environment,
) => [
  _i253.BindPlatform(),
  _i536.LoadRemoteConfig(),
  _i31.WarmFonts(),
  if (environment.matches(const <String>{'prod', 'stage'}))
    _i861.ReportCrashes(),
];
const String $alloyRootScopeName = 'app';
_i687.Future<_i178.AlloyScope> $startAlloy({
  _i178.AlloyEnvironment environment =
      _i178.AlloyEnvironment.defaultEnvironment,
}) => _i178.AlloyApplication.start(
  root: $AlloyRootScope(environment: environment),
  bootstrap: $alloyBootstrap(environment),
  rootName: $alloyRootScopeName,
);
