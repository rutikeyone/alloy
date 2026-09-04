import 'dart:async';
import 'dart:math';

import 'package:cobalt/cobalt.dart';

/// Closes a [StreamController] the graph handed out.
///
/// A top-level function, because the type belongs to `dart:async` and cannot
/// be made to implement [Disposable].
Future<void> closeEvents(StreamController<String> events) => events.close();

/// Registers types this package did not write.
///
/// `@CobaltInject` goes on a class, so it only reaches classes you own. Whatever
/// comes from the SDK or another package arrives through a module instead.
@cobaltModule
class PlatformModule {
  const PlatformModule();

  /// A seeded [Random] so the example is reproducible.
  @cobaltInject
  Random get random => Random(7);

  /// Something with a real teardown: the scope closes it on the way down.
  @CobaltInject(dispose: closeEvents)
  StreamController<String> events() => StreamController<String>.broadcast();
}
