// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'counter_bloc.dart';

// **************************************************************************
// PropertyInjectionGenerator
// **************************************************************************

mixin _$CounterBloc implements CobaltInjectable {
  set _repository(Repository value);
  set _telemetry(Telemetry value);
  @override
  void onInject(CobaltResolver resolver) {
    _repository = resolver.get<Repository>();
    _telemetry = resolver.get<Telemetry>();
  }
}
