part of 'alloy_registration.dart';

final class LazySingletonRegistration extends AlloyRegistration {
  LazySingletonRegistration({
    required super.key,
    required super.order,
    required this.factory,
    this.teardown,
  });

  final AlloyFactory<Object> factory;
  final AlloyTeardown? teardown;

  Object? instance;
}
