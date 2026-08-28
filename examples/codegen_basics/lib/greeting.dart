import 'package:alloy/alloy.dart';
import 'package:codegen_basics/services.dart';

/// Half from the graph, half from whoever built the widget.
///
/// `@alloyParam` marks what the container cannot know. The generator writes
/// `$GreetingArgs` beside the container as a named record, and registers this
/// as a parameterized factory rather than a singleton.
@alloyInject
class Greeting {
  Greeting(
    this._config, {
    @alloyParam required this.name,
    @alloyParam required this.loud,
  });

  final Config _config;
  final String name;
  final bool loud;

  /// Which build the graph was started for — the half `@alloyParam` did not
  /// supply.
  String get environment => _config.environment;

  /// [phrase] shouted or not, which is what `loud` was for.
  ///
  /// The words come from the caller rather than from here: this class is
  /// resolved from a graph and has no `BuildContext`, so it cannot know the
  /// reader's language. Reporting facts and letting the screen name them is
  /// how any layer below the widgets gets localized.
  String render(String phrase) => loud ? phrase.toUpperCase() : phrase;
}
