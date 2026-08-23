import 'package:alloy/src/factory/alloy_async_factory.dart';
import 'package:alloy/src/factory/alloy_factory.dart';
import 'package:alloy/src/factory/alloy_param_factory.dart';
import 'package:alloy/src/key/alloy_key.dart';

part 'async_singleton_registration.dart';
part 'lazy_singleton_registration.dart';
part 'param_registration.dart';
part 'singleton_registration.dart';
part 'transient_registration.dart';

sealed class AlloyRegistration {
  AlloyRegistration({required this.key, required this.order});

  final AlloyKey key;
  final int order;
}
