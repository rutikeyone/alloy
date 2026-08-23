part of 'alloy_registration.dart';

final class ParamRegistration extends AlloyRegistration {
  ParamRegistration({
    required super.key,
    required super.order,
    required this.factory,
  });

  final AlloyParamFactory<Object, Object> factory;
}
