# notes_app

A small multi-screen Flutter app that exercises every capability of
[Alloy](https://github.com/rutikeyone/alloy), one screen per case.

> **Not a runnable app.** This package is a library the gallery mounts — it has no `main.dart`
> and no native project of its own. Run it, and everything else, from one place:
>
> ```bash
> cd examples/gallery && flutter run
> ```

```
flutter pub get
dart run build_runner build
```

## Running on a device

`flutter run` picks whatever is already connected. The scripts in `tool/` boot
something first if nothing is:

```
tool/run_android.sh      # boots the first defined AVD, then runs on it
tool/run_ios.sh          # boots an available iPhone simulator, then runs on it
tool/build_all.sh        # regenerates, then builds APK and an unsigned iOS app
```

Both scripts pass extra arguments straight through, so `tool/run_ios.sh
--release` works. Android needs an AVD defined in Android Studio; iOS needs
Xcode with at least one simulator runtime installed.

## What each screen shows

| Screen | Case |
|---|---|
| Home | both startup phases — the bootstrap log and every `@AlloyInit` service |
| Property injection | a controller with an empty constructor and `@injected` fields |
| Widget-owned scope | `AlloyScopeWidget` plus a parameterized factory |
| Session scope | signing out disposes the scope; nothing implements `reset()` |
| Named and multi-injection | three formatters behind one interface |
| Scope tree | the live hierarchy, read from `AlloyScope.children` |
| Environments | one interface, a different class per build |

The restart button in the app bar disposes the root scope and starts a fresh
one. It is there to make bootstrap ownership visible: after a restart the boot
log reads

```
bind-platform
load-remote-config
warm-fonts
bind-platform released      <- the scope disposed the step it had adopted
bind-platform               <- a new instance, not the previous one
load-remote-config
warm-fonts
```

## Environments

This is the one optional case in the app — the other five screens never mention environments, and
a graph that does not split has a single one it never has to name.

This app is built for `dev` unless told otherwise:

```
flutter run --dart-define=NOTES_ENV=prod
flutter test                              # dev, so the fakes
```

`ApiClient` has two implementations annotated with the same `exposeAs`, one for `prod`/`stage` and
one for `dev`/`test`. Only the one naming the active environment is registered, so nothing
downstream knows which it got. The `report-crashes` bootstrap step is restricted the same way and
simply does not appear in the boot log outside `prod` and `stage`.

The environment is a compile-time constant handed to `$startAlloy`, not something a bootstrap step
loads — the graph cannot be built before it is known. `LoadRemoteConfig` is the separate case: a
phase-0 step that fetches values the graph then uses.

The session screen is the one worth reading first. Signing out is
`await scope.dispose()`, and everything the session built goes with it — there
is no session listener anywhere in this app and no repository exposes a
`reset()`.

## Layout

Features first. A layer split lives *inside* a feature, not above it, so
everything one case needs sits together:

```
lib/
  main.dart                  entry point, nothing else
  app/                       composition root — startup, routes, MaterialApp
  bootstrap/                 @AlloyBootstrap steps, phase 0
  core/                      used by more than one feature
  features/
    <feature>/
      domain/                types and interfaces
      data/                  storage, services, repositories
      ui/                    screens, controllers, widgets
      <wiring>.dart          what composes the feature, at its root
```

A feature only gets the folders it needs — `home` and `note_detail` are UI
only, so they have just `ui/`. `session` is the one with wiring at its root:
`session_scope.dart` declares what a session holds and `session_manager.dart`
owns the scope's lifetime, and neither is domain, data or UI.

```
features/
  home/ui/                   the hub and its list tile
  notes/                     domain/ data/ ui/ — the largest feature
  note_detail/ui/            a widget-owned scope and what it registers
  session/                   domain/ data/ ui/ plus the scope and its manager
  formatting/                domain/ data/ ui/ — one interface, three impls
  environments/              domain/ data/ ui/ — one interface, one impl per build
  diagnostics/               domain-less: telemetry and the scope tree screen
```

`lib/alloy.g.dart` is generated: it holds the container, the bootstrap list and
`$startAlloy()`. `lib/features/notes/ui/notes_controller.g.dart` is the
property-injection mixin. Both are committed so the example reads without
running the generator first.

## Running the tests

```
flutter test
```

Two things to copy when testing your own app:

- Build the root scope in `setUp`, never inside `testWidgets`. That body runs
  in a fake-async zone where a `Future.delayed` in an initializer never
  completes.
- Keep whole-graph assertions in a plain `test`. `testWidgets` is for what the
  widgets do.
