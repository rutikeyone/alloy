import 'package:alloy/alloy.dart';
import 'package:alloy_external_consumer/src/device_info.dart';

/// Names the root scope, and promises the one registration `ConsumerScope`
/// makes by hand.
///
/// Without the promise the build fails: `Diagnostics` injects `DeviceInfo`,
/// and nothing in this package annotates it.
@AlloyScopeRoot(name: 'consumer', provides: [DeviceInfo])
class AppScope {
  const AppScope();
}
