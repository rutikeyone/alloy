import 'package:bloc/bloc.dart';

/// Closes [bloc], for a registration that names its teardown rather than
/// declaring it.
///
/// ```dart
/// @CobaltInject(dispose: closeBloc)
/// class CounterCubit extends Cubit<int> { ... }
///
/// scope.registerLazySingleton<CounterCubit>(factory, dispose: closeBloc);
/// ```
///
/// Prefer `CobaltBloc` where the class is yours to change: it keeps the
/// knowledge on the object instead of repeating it at every registration.
/// This is for the ones that are not — a bloc from another package, or one
/// behind a base class you do not control.
///
/// It takes `BlocBase<Object?>` and is still accepted where a function of the
/// registered type is wanted, because Dart checks function parameters
/// contravariantly: every bloc is one of these.
Future<void> closeBloc(BlocBase<Object?> bloc) => bloc.close();
