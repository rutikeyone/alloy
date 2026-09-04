# cobalt_analyzer example

Not used directly by applications. It is the parsing layer `cobalt_generator`
and `cobalt_lint` share, so the build and the IDE agree on what a declaration
means.

```dart
import 'package:cobalt_analyzer/cobalt_analyzer.dart';

const parser = CobaltInjectableParser();

// `clazz` is a resolved ClassElement from package:analyzer.
if (parser.declares(clazz)) {
  final declaration = parser.parseClass(clazz);

  print(declaration.exposedType);   // Repository<User>
  print(declaration.lifetime);      // CobaltLifetime.lazySingleton
  print(declaration.environments);  // {prod, stage}
}
```

The IR round-trips through JSON, which is what lets the generator run in two
phases: a build step sees one library at a time, so `cobalt_scan` writes
per-library IR and `cobalt_container` aggregates it.

`CobaltTypeRef.signature` is the single definition of registration identity —
type arguments are part of it, nullability is not.
