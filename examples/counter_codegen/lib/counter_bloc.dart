import 'package:alloy/alloy.dart';
import 'package:counter_codegen/services.dart';

part 'counter_bloc.g.dart';

@alloyTransient
class CounterBloc with _$CounterBloc {
  CounterBloc();

  @injected
  late final Repository _repository;

  @injected
  late final Telemetry _telemetry;

  static const _key = 'counter';

  int get value => _repository.read(_key);

  String get environment => _repository.config.environment;

  void increment() {
    _repository.write(_key, value + 1);
    _telemetry.record('increment -> $value');
  }
}
