# cobalt_analyzer

Shared static analysis layer for [Cobalt](https://github.com/rutikeyone/cobalt). It turns annotated
Dart source into a typed intermediate representation.

Both `cobalt_generator` and `cobalt_lint` consume this package, so a declaration is parsed by one
implementation rather than two that drift apart. It depends on `analyzer` but deliberately not on
`build` or on the plugin API, so the lint plugin does not pull the build system into the analysis
server.

This is an internal package. Depend on it only if you are building your own tooling on top of
Cobalt's annotations.
