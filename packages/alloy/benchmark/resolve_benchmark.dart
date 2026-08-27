import 'package:alloy/alloy.dart';

class Filler {
  const Filler();
}

class Formatter {
  const Formatter();
}

final class FillerFactory implements AlloyFactory<Filler> {
  const FillerFactory();
  @override
  Filler create(AlloyResolver resolver) => const Filler();
}

final class FormatterFactory implements AlloyFactory<Formatter> {
  const FormatterFactory();
  @override
  Formatter create(AlloyResolver resolver) => const Formatter();
}

/// 205 registrations, five of them implementations of one interface — the
/// shape measured in the production apps this framework was written for.
AlloyScope buildGraph({int fillers = 200, int formatters = 5}) {
  final scope = AlloyScope.root(name: 'app');
  for (var i = 0; i < fillers; i++) {
    scope.registerLazySingleton<Filler>(const FillerFactory(), name: 'f$i');
  }
  for (var i = 0; i < formatters; i++) {
    scope.registerLazySingleton<Formatter>(
      const FormatterFactory(),
      name: 'p$i',
    );
  }
  return scope;
}

double microsPer(String label, int runs, void Function() body) {
  for (var i = 0; i < runs ~/ 10; i++) {
    body();
  }
  final watch = Stopwatch()..start();
  for (var i = 0; i < runs; i++) {
    body();
  }
  watch.stop();
  final per = watch.elapsedMicroseconds / runs;
  print('${label.padRight(46)} ${per.toStringAsFixed(3)} us');
  return per;
}

Future<void> main() async {
  final root = buildGraph();
  root.get<Filler>(name: 'f0');
  root.get<Formatter>(name: 'p0');

  var deep = root;
  for (var i = 0; i < 4; i++) {
    deep = deep.push('level$i');
  }

  microsPer('get<T>() cache hit, own scope', 200000, () {
    root.get<Filler>(name: 'f0');
  });
  microsPer('get<T>() cache hit, 4 scopes up', 200000, () {
    deep.get<Filler>(name: 'f0');
  });
  microsPer('getAll<T>() 5 of 205, own scope', 20000, () {
    root.getAll<Formatter>();
  });
  microsPer('getAll<T>() 5 of 205, 4 scopes up', 20000, () {
    deep.getAll<Formatter>();
  });
  microsPer('isRegistered<T>()', 200000, () {
    root.isRegistered<Filler>(name: 'f0');
  });

  await root.dispose();
}
