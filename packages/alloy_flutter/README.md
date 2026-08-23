# alloy_flutter

Flutter bindings for [Alloy](https://github.com/rutikeyone/alloy).

```dart
AlloyScopeProvider(
  scope: await $startAlloy(),
  child: const MyApp(),
);
```

Resolve from any descendant:

```dart
final repo = context.alloy<NoteStore>();
```

## Widget-owned scopes

A scope can belong to a piece of UI: created when it mounts, disposed when it unmounts, so a
screen's dependencies live exactly as long as the screen.

The short way is to extend `AlloyScopedWidget`, which collapses the scope declaration, the wrapper
and the content into one class:

```dart
class NoteDetailScreen extends AlloyScopedWidget {
  const NoteDetailScreen({super.key});

  @override
  void registerScope(AlloyScope scope) =>
      scope.registerLazySingleton<NoteDraft>(const NoteDraftFactory());

  @override
  Widget buildScoped(BuildContext context) =>
      Text(context.alloy<NoteDraft>().text);
}
```

`buildScoped` runs below the scope, so `context.alloy<T>()` resolves from it. Override `scopeName`,
`loading` or `errorBuilder` when the defaults do not fit; the scope is otherwise named after the
widget, which is what shows up in the scope tree.

`AlloyScopedStatefulWidget` is the stateful counterpart — the widget declares the scope, its
`AlloyScopedState` overrides `buildScoped`, and `setState` rebuilds only the content. The scope is
created once on mount, not on every rebuild.

Use `AlloyScopeWidget` directly when the scope has to wrap part of a subtree rather than a whole
widget:

```dart
AlloyScopeWidget(
  builder: const NoteDetailScope(),
  loading: const CircularProgressIndicator(),
  errorBuilder: (context, error) => ErrorView(error),
  child: const NoteDetailPage(),
)
```

`name` is optional everywhere and defaults to the builder's type. If the scope registers async
singletons, `loading` is shown while `init()` runs and `errorBuilder` receives anything it throws.

## Who owns the root scope

`AlloyAppScope` does. It builds the graph, publishes it, and disposes it on unmount:

```dart
void main() => runApp(
  AlloyAppScope(
    start: startMyApp,
    loading: const _Splash(),
    errorBuilder: (context, error, retry) => _StartupFailed(error, retry),
    child: const MyApp(),
  ),
);
```

Building the graph *inside* `runApp` rather than before it is the point. `runApp(App(scope: await
start()))` has no way to show a startup failure — the app dies before its first frame. Here the
failure is a screen with a retry. As a bonus, `WidgetsFlutterBinding` is already initialized when
`@AlloyBootstrap` steps run.

`AlloyAppScope.of(context).restart()` tears the graph down and builds a new one; it is the same
call that retries a failed start. The published provider is keyed by the scope, so a restart
rebuilds the subtree — a child scope cannot be reparented, and would otherwise be left pointing at
a root that is gone.

### `disposeOnExitRequest` is off by default

Turning it on disposes the graph when the OS asks the app to quit. It is off because the hook
behind it only fires where an exit is cancelable — Flutter's own docs say "Currently this is only
supported on macOS and Linux" — and is blunt about the rest:

> Do not rely on this function as a place to save critical data, because you will be disappointed.

On iOS and Android the process can be killed with no notification at all. So this is a desktop
nicety, not a guarantee, and it delays quitting by however long teardown takes.

One sharp edge if you do enable it: Flutter asks *every* observer before quitting and does not stop
at the first refusal. If another observer cancels the exit after this one has already disposed, the
app keeps running with no graph and shows `loading` until something calls `restart()`.
