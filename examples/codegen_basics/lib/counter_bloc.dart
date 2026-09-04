import 'package:cobalt/cobalt.dart';
import 'package:codegen_basics/services.dart';

part 'counter_bloc.g.dart';

@cobaltTransient
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
