import 'package:alloy/alloy.dart';
import 'package:bloc/bloc.dart';

/// Makes a `Bloc` or `Cubit` something its scope knows how to close.
///
/// A scope releases what implements [Disposable] or [AsyncDisposable], and
/// Dart has no structural typing — so `close()` is invisible to it, being
/// neither the right interface nor even the right name. Register a bloc
/// without saying so and it is built, used, and never closed.
///
/// ```dart
/// @alloyInject
/// class CounterCubit extends Cubit<int> with AlloyBloc {
///   CounterCubit() : super(0);
/// }
/// ```
///
/// Nothing else changes: the scope calls [dispose], which calls `close`, in
/// the same reverse-creation order as everything else it owns.
///
/// Use [closeBloc] instead where a mixin will not reach — a bloc from another
/// package, or one whose class you cannot edit.
mixin AlloyBloc<State> on BlocBase<State> implements AsyncDisposable {
  /// Closes the bloc, on the scope's word rather than a widget's.
  @override
  Future<void> dispose() => close();
}
