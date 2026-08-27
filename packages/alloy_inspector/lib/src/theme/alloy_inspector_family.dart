import 'package:alloy_flutter/alloy_flutter.dart';

/// The four things an Alloy event can be about.
///
/// Thirteen kinds is too many to give a colour each, and colouring by level
/// says how loud an event is rather than what it concerns. These four are the
/// division `AlloyTalkerObserver` already makes when it picks a log type, and
/// keeping them the same is what lets one palette dress both screens.
enum AlloyInspectorFamily {
  /// A scope appeared or went away.
  scope,

  /// Startup: bootstrap steps and async initialization.
  startup,

  /// An instance was built or released.
  instance,

  /// Something failed.
  failure;

  /// Which family [kind] belongs to.
  static AlloyInspectorFamily of(AlloyEventKind kind) => switch (kind) {
    AlloyEventKind.scopePushed ||
    AlloyEventKind.scopeDisposeStarted ||
    AlloyEventKind.scopeDisposed => AlloyInspectorFamily.scope,
    AlloyEventKind.scopeInitStarted ||
    AlloyEventKind.scopeInitCompleted ||
    AlloyEventKind.bootstrapStepStarted ||
    AlloyEventKind.bootstrapStepCompleted => AlloyInspectorFamily.startup,
    AlloyEventKind.instanceCreated ||
    AlloyEventKind.instanceDisposed => AlloyInspectorFamily.instance,
    AlloyEventKind.scopeInitFailed ||
    AlloyEventKind.scopeDisposeFailed ||
    AlloyEventKind.bootstrapStepFailed ||
    AlloyEventKind.bootstrapStepReleaseFailed => AlloyInspectorFamily.failure,
  };

  /// The title `alloy_talker` files this family under.
  ///
  /// `TalkerScreenTheme` colours by title, so this is the whole of the bridge
  /// between a palette here and a themed talker screen.
  String get talkerTitle => switch (this) {
    AlloyInspectorFamily.scope => 'alloy-scope',
    AlloyInspectorFamily.startup => 'alloy-startup',
    AlloyInspectorFamily.instance => 'alloy-instance',
    AlloyInspectorFamily.failure => 'alloy-failure',
  };
}
