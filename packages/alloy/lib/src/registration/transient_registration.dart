part of 'alloy_registration.dart';

final class TransientRegistration extends AlloyRegistration {
  TransientRegistration({
    required super.key,
    required super.order,
    required this.factory,
  });

  final AlloyFactory<Object> factory;
}
