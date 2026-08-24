import 'package:alloy/alloy.dart';
import 'package:teardown/src/services.dart';
import 'package:teardown/src/trace.dart';

/// A graph that tears down cleanly. Registration order is deliberately *not*
/// dependency order — the point is that it does not matter.
class CleanScope implements AlloyScopeBuilder {
  const CleanScope(this.trace);

  final Trace trace;

  @override
  void build(AlloyScope scope) {
    scope
      ..registerSingleton<Trace>(trace)
      ..registerLazySingleton<Cache>(CacheFactory(trace))
      ..registerLazySingleton<Uploader>(UploaderFactory(trace))
      ..registerLazySingleton<Database>(DatabaseFactory(trace));
  }
}

/// The same graph plus two services that misbehave on the way out.
class BrokenScope implements AlloyScopeBuilder {
  const BrokenScope(this.trace);

  final Trace trace;

  @override
  void build(AlloyScope scope) {
    scope
      ..registerSingleton<Trace>(trace)
      ..registerSingleton<Database>(Database(trace))
      ..registerSingleton<FlakySocket>(FlakySocket(trace))
      ..registerSingleton<StuckWatcher>(StuckWatcher(trace));
  }
}

final class DatabaseFactory implements AlloyFactory<Database> {
  const DatabaseFactory(this.trace);

  final Trace trace;

  @override
  Database create(AlloyResolver resolver) => Database(trace);
}

final class CacheFactory implements AlloyFactory<Cache> {
  const CacheFactory(this.trace);

  final Trace trace;

  @override
  Cache create(AlloyResolver resolver) =>
      Cache(trace, resolver.get<Database>());
}

final class UploaderFactory implements AlloyFactory<Uploader> {
  const UploaderFactory(this.trace);

  final Trace trace;

  @override
  Uploader create(AlloyResolver resolver) => Uploader(trace);
}
