/// talker adapter for Alloy.
///
/// [AlloyTalkerObserver] reports the graph's events as typed talker logs —
/// `alloy-scope`, `alloy-startup`, `alloy-instance`, `alloy-failure` — each
/// with its own colour, so `TalkerScreen` can filter them apart.
library;

export 'package:alloy_talker/src/alloy_talker_logs.dart';
export 'package:alloy_talker/src/alloy_talker_observer.dart';
