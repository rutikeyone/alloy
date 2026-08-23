part of 'alloy_registration.dart';

final class SingletonRegistration extends AlloyRegistration {
  SingletonRegistration({
    required super.key,
    required super.order,
    required this.value,
  });

  final Object value;
}
