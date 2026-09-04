import 'package:cobalt/cobalt.dart';
import 'package:cobalt_external_consumer/src/boot_log.dart';

/// Closes [cache] at teardown.
///
/// Top-level rather than a method on the class, because the point of this
/// registration is a class that *cannot* say how to close itself: it extends
/// nothing of Cobalt's and its closing method is not called `dispose`. Every
/// `Bloc`, `Cubit`, `ChangeNotifier` and `StreamController` is this shape.
void closeSessionCache(SessionCache cache) => cache.close();

/// A class Cobalt has no way to recognise as closeable.
///
/// It implements neither `Disposable` nor `AsyncDisposable`, and `close` is
/// not a name the runtime knows. Without `dispose:` on the annotation the
/// scope would hold it and let it go unclosed — which is exactly what used to
/// happen, because the class parser accepted the argument and dropped it.
@CobaltInject(dispose: closeSessionCache)
class SessionCache {
  SessionCache();

  var isClosed = false;

  void close() {
    isClosed = true;
    BootLog.record('session-cache closed');
  }
}
