part of 'cobalt_registration.dart';

final class SingletonRegistration extends CobaltRegistration {
  SingletonRegistration({
    required super.key,
    required super.order,
    required this.value,
  });

  final Object value;
}
