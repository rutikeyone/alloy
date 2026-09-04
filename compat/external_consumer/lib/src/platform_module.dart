import 'dart:async';

import 'package:cobalt/cobalt.dart';
import 'package:cobalt_external_consumer/src/boot_log.dart';

/// A type this package does not own, standing in for the http client or
/// database handle a real application would take from another package.
///
/// Nothing about it is Cobalt-shaped: it closes through its own `close()`, not
/// through `Disposable`, which is exactly why the module has to say how.
class Channel {
  Channel(this.name);

  final String name;
  var isOpen = true;

  void close() {
    isOpen = false;
    BootLog.record('$name closed');
  }
}

class Envelope {
  Envelope(this.channel, this.stamp);

  final Channel channel;
  final String stamp;
}

void closeChannel(Channel channel) => channel.close();

/// Registers types the generator cannot annotate, because they belong to
/// somebody else.
@cobaltModule
class PlatformModule {
  const PlatformModule();

  @CobaltInject(dispose: closeChannel)
  Channel channel() => Channel('channel');

  /// Named parameters, which a member may take like any constructor. Real
  /// clients from other packages are built this way far more often than
  /// positionally.
  @cobaltInject
  Future<Envelope> envelope({required Channel channel}) async {
    await Future<void>.delayed(Duration.zero);
    return Envelope(channel, 'stamped');
  }
}
