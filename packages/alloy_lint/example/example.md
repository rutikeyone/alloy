# alloy_lint example

An analyzer plugin. Add it to `analysis_options.yaml` at the root of the
package or workspace:

```yaml
plugins:
  alloy_lint: ^0.1.0
```

Then `dart analyze` and the IDE report Alloy mistakes where you make them,
instead of when `build_runner` runs:

```dart
@alloyInject
abstract class Broken {}
// warning: Alloy cannot construct 'Broken': it is abstract.
//          — alloy_injectable_must_be_constructible

@alloyInject
class Controller {
  @injected
  Repository repository;
  // warning: Controller.repository must be declared "late final" to receive
  //          property injection. — alloy_injected_field_must_be_late_final
}

@AlloyInit()
class Telemetry {}
// warning: Telemetry is annotated with @AlloyInit but declares no
//          'Future<void> init()' method. — alloy_init_requires_init_method
```

Twelve rules ship; all read annotations through `alloy_analyzer`, the same
layer the generator uses.

Note that `plugins` only works at the root of a package or workspace, and that
the analysis server resolves plugins from pub.dev rather than from your
pubspec — see the README if you need to point it at local sources.
