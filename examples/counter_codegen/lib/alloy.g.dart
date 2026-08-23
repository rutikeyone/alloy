// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:alloy/alloy.dart' as _i178;
import 'package:counter_codegen/counter_bloc.dart' as _i829;
import 'package:counter_codegen/services.dart' as _i444;

final class _CounterBlocFactory
    implements _i178.AlloyFactory<_i829.CounterBloc> {
  const _CounterBlocFactory();

  @override
  _i829.CounterBloc create(_i178.AlloyResolver resolver) => _i829.CounterBloc();
}

final class _ConfigFactory implements _i178.AlloyFactory<_i444.Config> {
  const _ConfigFactory();

  @override
  _i444.Config create(_i178.AlloyResolver resolver) => _i444.Config();
}

final class _RepositoryFactory implements _i178.AlloyFactory<_i444.Repository> {
  const _RepositoryFactory();

  @override
  _i444.Repository create(_i178.AlloyResolver resolver) =>
      _i444.Repository(resolver.get<_i444.Config>());
}

final class _TelemetryFactory implements _i178.AlloyFactory<_i444.Telemetry> {
  const _TelemetryFactory();

  @override
  _i444.Telemetry create(_i178.AlloyResolver resolver) => _i444.Telemetry();
}

final class $AlloyRootScope implements _i178.AlloyScopeBuilder {
  const $AlloyRootScope();

  @override
  void build(_i178.AlloyScope scope) {
    scope.registerLazySingleton<_i444.Config>(const _ConfigFactory());
    scope.registerLazySingleton<_i444.Telemetry>(const _TelemetryFactory());
    scope.registerLazySingleton<_i444.Repository>(const _RepositoryFactory());
    scope.registerFactory<_i829.CounterBloc>(const _CounterBlocFactory());
  }
}

const String $alloyRootScopeName = 'root';
_i687.Future<_i178.AlloyScope> $startAlloy() => _i178.AlloyApplication.start(
  root: const $AlloyRootScope(),
  rootName: $alloyRootScopeName,
);
