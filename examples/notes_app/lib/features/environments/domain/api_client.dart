/// What the graph handed the screen, without saying it in any language.
///
/// A registration is resolved from a scope, so it has no `BuildContext` and
/// cannot know what the reader reads. It reports facts — which class answered,
/// where it would go — and the screen turns them into a sentence. That split
/// is what makes a layer below the widgets localizable at all.
abstract interface class ApiClient {
  /// Which implementation was registered — a type name, so it does not
  /// translate. Naming it is the point of the screen.
  String get implementation;

  /// Where it would go, or null when it goes nowhere.
  String? get endpoint;

  Future<List<String>> fetchHeadlines();
}
