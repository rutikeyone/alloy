import 'package:alloy/alloy.dart';
import 'package:counter_manual/counter.dart';

Future<void> main() async {
  final app = await startApp();

  final session = openSession(app, 'alice');
  final counter = session.getWithParam<Counter, String>('alice');

  counter
    ..increment()
    ..increment();

  print('value: ${counter.value}');
  print('scopes: ${app.name} -> ${app.children.map((s) => s.name).join()}');

  await session.dispose();
  print(
    'after session dispose, storage open: '
    '${!app.get<CounterStorage>().isClosed}',
  );

  await app.dispose();
  for (final entry
      in app.state == AlloyScopeState.disposed
          ? const ['app disposed']
          : const <String>[]) {
    print(entry);
  }
}
