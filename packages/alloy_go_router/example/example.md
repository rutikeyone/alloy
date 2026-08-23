# alloy_go_router example

A scope whose lifetime is a navigation flow: it is built when the flow opens
and disposed when the user leaves it. Navigating *inside* the flow keeps it.

```dart
import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:go_router/go_router.dart';

// Build the router once. A new AlloyFlowRoute instance is a different flow as
// far as go_router is concerned, because a shell page is keyed by identity.
final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    AlloyFlowRoute(
      name: 'order',
      // The scope is rebuilt when this changes, and only when it changes.
      identity: (state) => state.pathParameters['id'],
      scope: (state) => OrderScope(state.pathParameters['id']!),
      routes: [
        GoRoute(path: '/order/:id', builder: (context, state) => const SummaryScreen()),
        GoRoute(path: '/order/:id/pay', builder: (context, state) => const PaymentScreen()),
      ],
    ),
  ],
);
```

Inside the flow nothing new is needed — `context.alloy<OrderDraft>()` resolves
from the nearest scope, so the flow shadows the root automatically.

For tabs there are `AlloyFlowShellRoute` and `AlloyFlowShellBranch`; note that a
branch is kept **alive**, not **visible**, so switching tabs disposes nothing.
Runnable version:
[`examples/flow_router`](https://github.com/rutikeyone/alloy/tree/main/examples/flow_router).
