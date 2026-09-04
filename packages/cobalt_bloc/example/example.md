# cobalt_bloc example

```dart
import 'package:cobalt/cobalt.dart';
import 'package:cobalt_bloc/cobalt_bloc.dart';
import 'package:bloc/bloc.dart';

@cobaltInject
class CounterCubit extends Cubit<int> with CobaltBloc {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
}
```

The scope closes it in the same reverse-creation order as everything else it owns, so a cubit built
from a repository is closed before that repository is.

For a bloc you cannot mix into — one from another package, or behind a base class you do not
control — name the function instead:

```dart
@CobaltInject(dispose: closeBloc)
class ForeignCubit extends SomeoneElsesCubit { ... }
```

With `flutter_bloc`, provide it with `BlocProvider.value`. `BlocProvider(create: ...)` would close a
bloc the scope still owns, and the next resolve would hand back a dead one.
