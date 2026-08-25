import 'dart:async';

import 'package:alloy/alloy.dart';
import 'package:alloy_external_consumer/src/boot_log.dart';

/// A type this package does not own, standing in for the http client or
/// database handle a real application would take from another package.
///
/// Nothing about it is Alloy-shaped: it closes through its own `close()`, not
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
@alloyModule
class PlatformModule {
  const PlatformModule();

  @AlloyInject(dispose: closeChannel)
  Channel channel() => Channel('channel');

  @alloyInject
  Future<Envelope> envelope(Channel channel) async {
    await Future<void>.delayed(Duration.zero);
    return Envelope(channel, 'stamped');
  }
}
