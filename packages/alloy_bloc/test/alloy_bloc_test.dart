import 'package:alloy/alloy.dart';
import 'package:alloy_bloc/alloy_bloc.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:bloc/bloc.dart';
import 'package:test/test.dart';

/// A bloc that says how it closes.
class CounterCubit extends Cubit<int> with AlloyBloc {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
}

/// The same thing, saying nothing — the shape that leaks.
class SilentCubit extends Cubit<int> {
  SilentCubit() : super(0);
}

/// Something ordinary to sit beside a bloc in the teardown order.
class Recorder implements Disposable {
  Recorder(this.label, this.log);

  final String label;
  final List<String> log;

  @override
  void dispose() => log.add(label);
}

void main() {
  test('a bloc with the mixin is closed by its scope', () async {
    final scope = alloyTestRoot();
    final cubit = CounterCubit();
    scope.registerSingleton<CounterCubit>(cubit);

    expect(cubit.isClosed, isFalse);
    await scope.dispose();

    expect(cubit.isClosed, isTrue);
  });

  test('one without it is not, which is the whole point', () async {
    final scope = alloyTestRoot();
    final cubit = SilentCubit();
    scope.registerSingleton<SilentCubit>(cubit);

    await scope.dispose();

    expect(
      cubit.isClosed,
      isFalse,
      reason:
          'close() is neither the interface the scope looks for nor even the '
          'right name, and Dart has no structural typing to bridge the gap',
    );
  });

  test('closeBloc reaches a class the mixin cannot', () async {
    final scope = alloyTestRoot();
    final cubit = SilentCubit();
    // The claim worth pinning: closeBloc takes BlocBase<Object?> and is still
    // accepted where a function of SilentCubit is wanted, because Dart checks
    // function parameters contravariantly.
    scope.registerSingleton<SilentCubit>(cubit, dispose: closeBloc);

    await scope.dispose();

    expect(cubit.isClosed, isTrue);
  });

  test('a lazy bloc is closed only if it was built', () async {
    final scope = alloyTestRoot()
      ..registerLazySingleton<CounterCubit>(FnFactory((_) => CounterCubit()));

    await scope.dispose();

    expect(
      scope.state,
      AlloyScopeState.disposed,
      reason: 'nothing was resolved, so there was nothing to close',
    );
  });

  test('a bloc closes in creation order with everything else', () async {
    final log = <String>[];
    final scope = alloyTestRoot()
      ..registerLazySingleton<Recorder>(FnFactory((_) => Recorder('db', log)))
      ..registerLazySingleton<CounterCubit>(
        FnFactory((resolver) {
          resolver.get<Recorder>();
          return CounterCubit();
        }),
      );

    scope.get<CounterCubit>();
    await scope.dispose();

    expect(
      log,
      ['db'],
      reason:
          'the cubit was built after the recorder and so is closed before '
          'it — the bloc is not a special case in the teardown order',
    );
  });

  test('the scope owns it, so a closed bloc is still what resolves', () async {
    final scope = alloyTestRoot();
    final cubit = CounterCubit()..increment();
    scope.registerSingleton<CounterCubit>(cubit);

    expect(scope.get<CounterCubit>().state, 1);
    await scope.dispose();

    expect(cubit.isClosed, isTrue);
  });
}
