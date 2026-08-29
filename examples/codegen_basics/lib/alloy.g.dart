// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;
import 'dart:math' as _i407;

import 'package:alloy/alloy.dart' as _i178;
import 'package:codegen_basics/counter_bloc.dart' as _i1015;
import 'package:codegen_basics/greeting.dart' as _i767;
import 'package:codegen_basics/platform_module.dart' as _i122;
import 'package:codegen_basics/services.dart' as _i700;

typedef $GreetingArgs = ({String name, bool loud});

final class _PlatformModuleEventsFactory
    implements _i178.AlloyFactory<_i687.StreamController<String>> {
  const _PlatformModuleEventsFactory();

  @override
  _i687.StreamController<String> create(_i178.AlloyResolver resolver) =>
      const _i122.PlatformModule().events();
}

final class _PlatformModuleRandomFactory
    implements _i178.AlloyFactory<_i407.Random> {
  const _PlatformModuleRandomFactory();

  @override
  _i407.Random create(_i178.AlloyResolver resolver) =>
      const _i122.PlatformModule().random;
}

final class _CounterBlocFactory
    implements _i178.AlloyFactory<_i1015.CounterBloc> {
  const _CounterBlocFactory();

  @override
  _i1015.CounterBloc create(_i178.AlloyResolver resolver) =>
      _i1015.CounterBloc();
}

final class _GreetingFactory
    implements _i178.AlloyParamFactory<_i767.Greeting, $GreetingArgs> {
  const _GreetingFactory();

  @override
  _i767.Greeting create(_i178.AlloyResolver resolver, $GreetingArgs args) =>
      _i767.Greeting(
        resolver.get<_i700.Config>(),
        name: args.name,
        loud: args.loud,
      );
}

final class _ConfigFactory implements _i178.AlloyFactory<_i700.Config> {
  const _ConfigFactory();

  @override
  _i700.Config create(_i178.AlloyResolver resolver) => _i700.Config();
}

final class _RepositoryFactory implements _i178.AlloyFactory<_i700.Repository> {
  const _RepositoryFactory();

  @override
  _i700.Repository create(_i178.AlloyResolver resolver) =>
      _i700.Repository(resolver.get<_i700.Config>());
}

final class _TelemetryFactory implements _i178.AlloyFactory<_i700.Telemetry> {
  const _TelemetryFactory();

  @override
  _i700.Telemetry create(_i178.AlloyResolver resolver) => _i700.Telemetry();
}

final class $AlloyRootScope implements _i178.AlloyScopeBuilder {
  const $AlloyRootScope();

  @override
  void build(_i178.AlloyScope scope) {
    scope.registerLazySingleton<_i687.StreamController<String>>(
      const _PlatformModuleEventsFactory(),
      dispose: _i122.closeEvents,
    );
    scope.registerLazySingleton<_i407.Random>(
      const _PlatformModuleRandomFactory(),
    );
    scope.registerLazySingleton<_i700.Config>(const _ConfigFactory());
    scope.registerLazySingleton<_i700.Telemetry>(const _TelemetryFactory());
    scope.registerParamFactory<_i767.Greeting, $GreetingArgs>(
      const _GreetingFactory(),
    );
    scope.registerLazySingleton<_i700.Repository>(const _RepositoryFactory());
    scope.registerFactory<_i1015.CounterBloc>(const _CounterBlocFactory());
  }
}

const String $alloyRootScopeName = 'root';
_i687.Future<_i178.AlloyScope> $startAlloy() => _i178.AlloyApplication.start(
  root: const $AlloyRootScope(),
  rootName: $alloyRootScopeName,
);
