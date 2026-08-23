import 'package:alloy/src/graph/alloy_cycle_error.dart';

/// Returns the nodes [node] must wait for.
typedef AlloyDependenciesOf<T> = Iterable<T> Function(T node);

/// Sorts [nodes] into dependency levels.
///
/// Everything in one level is independent of everything else in it, so a level
/// can run in parallel; each level depends only on the ones before it. This is
/// the shape both the runtime and the generator need — a flat order would lose
/// the information that two branches can start together.
///
/// Dependencies outside [nodes] are ignored, so a graph can reference things
/// supplied elsewhere. A cycle throws `AlloyCycleError` naming the path, found
/// by walking the nodes that never drained.
List<List<T>> layeredTopologicalSort<T extends Object>(
  Iterable<T> nodes,
  AlloyDependenciesOf<T> dependenciesOf, {
  required String Function(T node) labelOf,
}) {
  final ordered = nodes.toList(growable: false);
  final known = ordered.toSet();

  final pending = <T, int>{};
  final dependents = <T, List<T>>{};

  for (final node in ordered) {
    final edges = dependenciesOf(node).where(known.contains).toSet();
    pending[node] = edges.length;
    for (final edge in edges) {
      dependents.putIfAbsent(edge, () => <T>[]).add(node);
    }
  }

  final levels = <List<T>>[];
  var remaining = ordered.length;
  var frontier = [
    for (final node in ordered)
      if (pending[node] == 0) node,
  ];

  while (frontier.isNotEmpty) {
    levels.add(frontier);
    remaining -= frontier.length;

    final next = <T>[];
    for (final node in ordered) {
      if (pending[node] == 0) continue;
      var count = pending[node]!;
      for (final settled in frontier) {
        if (dependents[settled]?.contains(node) ?? false) count--;
      }
      pending[node] = count;
      if (count == 0) next.add(node);
    }
    frontier = next;
  }

  if (remaining > 0) {
    final stuck = [
      for (final node in ordered)
        if (pending[node]! > 0) node,
    ];
    throw AlloyCycleError(
      _extractCycle(stuck, dependenciesOf, labelOf, stuck.toSet()),
    );
  }

  return levels;
}

List<String> _extractCycle<T extends Object>(
  List<T> stuck,
  AlloyDependenciesOf<T> dependenciesOf,
  String Function(T node) labelOf,
  Set<T> scope,
) {
  final path = <T>[];
  final onPath = <T>{};

  List<T>? walk(T node) {
    if (onPath.contains(node)) {
      return [...path.sublist(path.indexOf(node)), node];
    }
    path.add(node);
    onPath.add(node);
    for (final dep in dependenciesOf(node).where(scope.contains)) {
      final found = walk(dep);
      if (found != null) return found;
    }
    path.removeLast();
    onPath.remove(node);
    return null;
  }

  for (final node in stuck) {
    final found = walk(node);
    if (found != null) return [for (final n in found) labelOf(n)];
  }
  return [for (final n in stuck) labelOf(n)];
}
