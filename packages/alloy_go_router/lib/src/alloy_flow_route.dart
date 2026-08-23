import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_go_router/src/alloy_flow_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Builds the registrations a flow adds, from the route state that opened it.
typedef AlloyFlowScopeBuilder = AlloyScopeBuilder Function(GoRouterState state);

/// Reads what distinguishes one run of a flow from another.
///
/// Usually a path parameter. Returning a different value tears the flow's
/// scope down and builds a new one; returning the same value keeps it.
typedef AlloyFlowIdentity = Object? Function(GoRouterState state);

/// A [ShellRoute] whose subtree owns an Alloy scope.
///
/// The scope is created when the flow is entered, survives every navigation
/// between [routes], and is disposed when navigation leaves the flow. That
/// falls out of how go_router keys a shell's page — by the identity of the
/// [ShellRoute] object — so the widget tree is the only owner and there is no
/// second source of truth about the flow's lifetime.
///
/// ```dart
/// AlloyFlowRoute(
///   name: 'checkout',
///   identity: (state) => state.pathParameters['orderId'],
///   scope: (state) => CheckoutScope(state.pathParameters['orderId']!),
///   routes: [
///     GoRoute(path: '/orders/:orderId/summary', builder: (_, _) => const Summary()),
///     GoRoute(path: '/orders/:orderId/payment', builder: (_, _) => const Payment()),
///   ],
/// )
/// ```
///
/// Inside the flow nothing new applies: `context.alloy<T>()` resolves from the
/// nearest scope, so the flow shadows the root for as long as it is open.
///
/// Being a class rather than a function, a flow can be given a name of its own
/// and reused:
///
/// ```dart
/// class CheckoutFlowRoute extends AlloyFlowRoute {
///   CheckoutFlowRoute()
///     : super(name: 'checkout', scope: ..., routes: [...]);
/// }
/// ```
///
/// Construct it once, with the rest of the route table. A fresh instance is a
/// different flow as far as go_router is concerned, because the shell's page
/// key is the route object's identity.
///
/// Pass [shell] to wrap the flow in shared chrome — it receives the
/// flow-scoped child, so an app bar built there can resolve from the flow.
///
/// A flow whose routes are not one subtree cannot be expressed this way; see
/// this package's README for why that case is deliberately not covered.
class AlloyFlowRoute extends ShellRoute {
  /// Declares a flow that owns a scope.
  AlloyFlowRoute({
    required String name,
    required AlloyFlowScopeBuilder scope,
    required super.routes,
    AlloyFlowIdentity? identity,
    ShellRouteBuilder? shell,
    Widget? loading,
    Widget Function(BuildContext context, Object error)? errorBuilder,
    super.navigatorKey,
    super.observers,
    super.parentNavigatorKey,
    super.redirect,
    super.restorationScopeId,
    super.notifyRootObserver,
  }) : super(
         builder: (context, state, child) => AlloyFlowScope(
           name: name,
           identity: identity?.call(state),
           builder: scope(state),
           loading: loading,
           errorBuilder: errorBuilder,
           child: shell == null ? child : shell(context, state, child),
         ),
       );
}

/// [AlloyFlowRoute] as a function, for route tables written that way.
///
/// Identical in every respect — it builds the same object. Prefer the class:
/// it reads alongside `GoRoute` and `ShellRoute`, and it can be subclassed.
AlloyFlowRoute alloyFlowRoute({
  required String name,
  required AlloyFlowScopeBuilder scope,
  required List<RouteBase> routes,
  AlloyFlowIdentity? identity,
  ShellRouteBuilder? shell,
  Widget? loading,
  Widget Function(BuildContext context, Object error)? errorBuilder,
  GlobalKey<NavigatorState>? navigatorKey,
  List<NavigatorObserver>? observers,
}) => AlloyFlowRoute(
  name: name,
  scope: scope,
  routes: routes,
  identity: identity,
  shell: shell,
  loading: loading,
  errorBuilder: errorBuilder,
  navigatorKey: navigatorKey,
  observers: observers,
);
