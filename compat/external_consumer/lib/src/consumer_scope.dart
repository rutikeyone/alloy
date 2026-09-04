import 'package:cobalt/cobalt.dart';
import 'package:cobalt_external_consumer/cobalt.g.dart';
import 'package:cobalt_external_consumer/src/device_info.dart';

/// The whole root scope: what the generator found, plus the one thing it
/// cannot know about.
///
/// `DeviceInfo` is registered first so it is released last — everything built
/// on top of it goes away before the value it describes does.
class ConsumerScope implements CobaltScopeBuilder {
  const ConsumerScope(this.device);

  final DeviceInfo device;

  @override
  void build(CobaltScope scope) {
    scope.registerSingleton<DeviceInfo>(device);
    const $CobaltRootScope().build(scope);
  }
}

/// Starts the graph the way an application would: composing the generated
/// container rather than calling `$startCobalt` and hoping.
Future<CobaltScope> startConsumer({
  DeviceInfo device = const DeviceInfo('test-device'),
}) => CobaltApplication.start(
  root: ConsumerScope(device),
  bootstrap: $cobaltBootstrap,
  rootName: $cobaltRootScopeName,
);
