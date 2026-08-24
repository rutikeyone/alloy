import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:codegen_basics/alloy.g.dart';
import 'package:codegen_basics/counter_bloc.dart';
import 'package:flutter/material.dart';

/// The smallest thing you can copy to start a generated project.
///
/// Everything the graph needs comes from `alloy.g.dart`, which
/// `dart run build_runner build` writes from the annotations in
/// `services.dart` and `counter_bloc.dart`. There is no hand-written wiring.
void main() => runApp(
  MaterialApp(
    title: 'Alloy codegen basics',
    theme: ThemeData(colorSchemeSeed: Colors.teal),
    builder: AlloyAppScope.builder(
      root: const $AlloyRootScope(),
      rootName: $alloyRootScopeName,
      loading: const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
    home: const CounterScreen(),
  ),
);

class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Alloy codegen basics')),
    // A scope that lives exactly as long as this screen. The bloc below is a
    // transient, so it would be rebuilt on every resolve — putting it in a
    // scope of its own is what gives it a lifetime and a disposal point.
    body: const AlloyScopeWidget(
      name: 'counter-screen',
      builder: _ScreenScope(),
      child: _Counter(),
    ),
  );
}

/// Registers nothing new — it exists to give the screen its own node in the
/// scope tree, which is where screen-scoped state would go as the app grows.
final class _ScreenScope implements AlloyScopeBuilder {
  const _ScreenScope();

  @override
  void build(AlloyScope scope) {}
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  late final CounterBloc _bloc = context.alloy<CounterBloc>();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_bloc.value}',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        Text('environment: ${_bloc.environment}'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => setState(_bloc.increment),
          child: const Text('increment'),
        ),
      ],
    ),
  );
}
