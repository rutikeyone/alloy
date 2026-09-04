/// talker adapter for Cobalt.
///
/// [CobaltTalkerObserver] reports the graph's events as typed talker logs —
/// `cobalt-scope`, `cobalt-startup`, `cobalt-instance`, `cobalt-failure` — each
/// with its own colour, so `TalkerScreen` can filter them apart.
library;

export 'package:cobalt_talker/src/cobalt_talker_logs.dart';
export 'package:cobalt_talker/src/cobalt_talker_observer.dart';
