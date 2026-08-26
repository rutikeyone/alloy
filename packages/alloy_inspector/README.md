# alloy_inspector

The live scope tree, what [Alloy](https://pub.dev/packages/alloy) built and with what lifetime, and
everything the graph reported — on a screen inside your app, with nothing attached from outside.

```yaml
dev_dependencies:
  alloy_inspector: ^0.1.0
```

## Wiring

The log has to be installed when the graph is built. Observers are fixed when a scope is
constructed and handed down to its children, so an inspector cannot start listening to a graph that
is already running:

```dart
final log = AlloyInspectorLog();

final scope = await AlloyApplication.start(
  root: const AppScope(),
  observers: [log],
);
```

Then push the screen from wherever your debug menu lives:

```dart
Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => AlloyInspectorScreen(log: log)),
);
```

It reads the scope above it and climbs to the root, so it shows the whole graph wherever it opens.

## Three views, and why they read different things

**Tree** walks the live scopes. It is not rebuilt from events, because an event carries an
`AlloyScopeRef` — a name, a depth and a parent name — and two same-named siblings are
indistinguishable there, as are a scope that was disposed and one pushed later under the same name.
Good enough to label a log row, not to identify a node.

Each scope lists what it registers with its lifetime, read through `debugKindOf`, and separately
what it inherits, with the scope that owns it. That owner is the fact that decides what an override
actually affects: a factory runs on the scope that owns *its* registration, not the one you asked
from.

**Built** comes from creation events, and has to. A scope's registrations are what was *declared* —
a lazy singleton nobody resolved looks there exactly like one that is built — so only an event
proves an object exists.

**Log** is everything, filterable by event kind.

## Two things it will not do

**It never builds anything to show you.** Resolving a registration creates it for real: the object
starts existing, the scope takes ownership, and a creation event appears. An inspector that resolved
rows in order to display them would change the graph it is there to observe. Tapping a row shows
facts; building is a separate action that says what it costs.

**An eager singleton never appears under Built.** It is constructed by whoever called
`registerSingleton` and handed over already made, so the scope has nothing to report constructing.
It appears in the tree, with its lifetime, and never in the built list.

## The notification is deferred, on purpose

Observer callbacks are synchronous and arrive in the middle of the work they describe — including a
teardown running while the widget tree builds, where notifying immediately throws
`setState() called during build`. `AlloyInspectorLog` defers to the next turn, and drops a
notification that comes due after it has been disposed.
