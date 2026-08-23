part of 'alloy_registration.dart';

final class LazySingletonRegistration extends AlloyRegistration {
  LazySingletonRegistration({
    required super.key,
    required super.order,
    required this.factory,
  });

  final AlloyFactory<Object> factory;

  Object? instance;
}
