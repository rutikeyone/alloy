// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:alloy/alloy.dart' as _i178;
import 'package:alloy_external_consumer/src/bind_platform.dart' as _i978;
import 'package:alloy_external_consumer/src/clock.dart' as _i713;
import 'package:alloy_external_consumer/src/database.dart' as _i629;
import 'package:alloy_external_consumer/src/report.dart' as _i552;
import 'package:alloy_external_consumer/src/repository.dart' as _i309;
import 'package:alloy_external_consumer/src/search_index.dart' as _i115;
import 'package:alloy_external_consumer/src/system_clock.dart' as _i358;

final class _SystemClockFactory implements _i178.AlloyFactory<_i713.Clock> {
  const _SystemClockFactory();

  @override
  _i713.Clock create(_i178.AlloyResolver resolver) => _i358.SystemClock();
}

final class _DatabaseFactory
    implements _i178.AlloyAsyncFactory<_i629.Database> {
  const _DatabaseFactory();

  @override
  _i687.Future<_i629.Database> create(_i178.AlloyResolver resolver) async {
    final instance = _i629.Database();
    await instance.init();
    return instance;
  }
}

final class _ReportFactory implements _i178.AlloyFactory<_i552.Report> {
  const _ReportFactory();

  @override
  _i552.Report create(_i178.AlloyResolver resolver) => _i552.Report();
}

final class _CatalogFactory implements _i178.AlloyFactory<_i309.Catalog> {
  const _CatalogFactory();

  @override
  _i309.Catalog create(_i178.AlloyResolver resolver) => _i309.Catalog(
    resolver.get<_i309.Repository<_i309.User>>(),
    resolver.get<_i309.Repository<_i309.Order>>(),
  );
}

final class _OrderRepositoryFactory
    implements _i178.AlloyFactory<_i309.Repository<_i309.Order>> {
  const _OrderRepositoryFactory();

  @override
  _i309.Repository<_i309.Order> create(_i178.AlloyResolver resolver) =>
      _i309.OrderRepository();
}

final class _UserRepositoryFactory
    implements _i178.AlloyFactory<_i309.Repository<_i309.User>> {
  const _UserRepositoryFactory();

  @override
  _i309.Repository<_i309.User> create(_i178.AlloyResolver resolver) =>
      _i309.UserRepository();
}

final class _SearchIndexFactory
    implements _i178.AlloyAsyncFactory<_i115.SearchIndex> {
  const _SearchIndexFactory();

  @override
  _i687.Future<_i115.SearchIndex> create(_i178.AlloyResolver resolver) async {
    final instance = _i115.SearchIndex(resolver.get<_i629.Database>());
    await instance.init();
    return instance;
  }
}

final class $AlloyRootScope implements _i178.AlloyScopeBuilder {
  const $AlloyRootScope();

  @override
  void build(_i178.AlloyScope scope) {
    scope.registerLazySingleton<_i713.Clock>(const _SystemClockFactory());
    scope.registerAsyncSingleton<_i629.Database>(const _DatabaseFactory());
    scope.registerLazySingleton<_i309.Repository<_i309.Order>>(
      const _OrderRepositoryFactory(),
    );
    scope.registerLazySingleton<_i309.Repository<_i309.User>>(
      const _UserRepositoryFactory(),
    );
    scope.registerLazySingleton<_i309.Catalog>(const _CatalogFactory());
    scope.registerAsyncSingleton<_i115.SearchIndex>(
      const _SearchIndexFactory(),
      dependsOn: {const _i178.AlloyKey(_i629.Database)},
    );
    scope.registerFactory<_i552.Report>(const _ReportFactory());
  }
}

List<_i178.AlloyBootstrapStep> get $alloyBootstrap => [_i978.BindPlatform()];
const String $alloyRootScopeName = 'consumer';
_i687.Future<_i178.AlloyScope> $startAlloy() => _i178.AlloyApplication.start(
  root: const $AlloyRootScope(),
  bootstrap: $alloyBootstrap,
  rootName: $alloyRootScopeName,
);
