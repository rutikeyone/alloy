# alloy_annotations

Annotations for [Alloy](https://github.com/rutikeyone/alloy), a dependency injection framework for
Dart and Flutter.

This package holds nothing but the annotations, so neither the runtime nor the analyzer leaks into
a dependency graph that only needs the markers. Most applications depend on `alloy` instead, which
re-exports everything here.

| Annotation | Applies to | Effect |
|---|---|---|
| `@AlloyInject` / `@alloyInject` | class | registers the class; `lifetime`, `name`, `exposeAs` |
| `@alloySingleton` / `@alloyTransient` | class | shorthands for the other two lifetimes |
| `@Injected` / `@injected` | `late final` field | fills the field through the generated mixin |
| `@Named` | parameter or field | selects a named registration |
| `@AlloyBootstrap` | class | a phase-0 step, run before the container exists |
| `@AlloyInit` | class | an async singleton, with `dependsOn` |
| `@AlloyModule` / `@alloyModule` | class | its annotated members register types you do not own |
| `@AlloyScopeRoot` | class | names the root scope; `provides` declares registrations made by hand |
| `AlloyProvided` | inside `provides` | a hand-made registration that carries a `@Named` qualifier |
| `@AlloyEnvironment` | class | optional — restricts the registration to an environment; repeat it for several |
