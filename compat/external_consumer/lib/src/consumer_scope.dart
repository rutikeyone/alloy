import 'package:alloy/alloy.dart';
import 'package:alloy_external_consumer/alloy.g.dart';
import 'package:alloy_external_consumer/src/device_info.dart';

/// The whole root scope: what the generator found, plus the one thing it
/// cannot know about.
///
/// `DeviceInfo` is registered first so it is released last — everything built
/// on top of it goes away before the value it describes does.
class ConsumerScope implements AlloyScopeBuilder {
  const ConsumerScope(this.device);

  final DeviceInfo device;

  @override
  void build(AlloyScope scope) {
    scope.registerSingleton<DeviceInfo>(device);
    const $AlloyRootScope().build(scope);
  }
}

/// Starts the graph the way an application would: composing the generated
/// container rather than calling `$startAlloy` and hoping.
Future<AlloyScope> startConsumer({
  DeviceInfo device = const DeviceInfo('test-device'),
}) => AlloyApplication.start(
  root: ConsumerScope(device),
  bootstrap: $alloyBootstrap,
  rootName: $alloyRootScopeName,
);
