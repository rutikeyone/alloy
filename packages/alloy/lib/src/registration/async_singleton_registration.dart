part of 'alloy_registration.dart';

final class AsyncSingletonRegistration extends AlloyRegistration {
  AsyncSingletonRegistration({
    required super.key,
    required super.order,
    required this.factory,
    required this.dependsOn,
  });

  final AlloyAsyncFactory<Object> factory;
  final Set<AlloyKey> dependsOn;

  Object? instance;
  bool isReady = false;
}
