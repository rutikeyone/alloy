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
    @alloyParam this.loud = false,
  });

  final Config _config;
  final String name;
  final bool loud;

  String render() {
    final text = 'hello $name from ${_config.environment}';
    return loud ? text.toUpperCase() : text;
  }
}
