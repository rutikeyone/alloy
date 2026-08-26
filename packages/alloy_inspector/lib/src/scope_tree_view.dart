import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_inspector/src/registration_detail_sheet.dart';
import 'package:alloy_inspector/src/registration_view.dart';
import 'package:flutter/material.dart';

/// The live scope tree, with what each scope registers.
///
/// Walks the scope objects rather than the event stream. An event carries an
/// `AlloyScopeRef`, which is a name, a depth and a parent name — two
/// same-named siblings are indistinguishable there, and so are a scope that
/// was disposed and one pushed later under the same name. As a label that is
/// fine; as the identity of a node it is not.
class ScopeTreeView extends StatelessWidget {
  /// Shows the tree rooted at [root].
  const ScopeTreeView({required this.root, super.key});

  /// The scope to render, along with everything under it.
  final AlloyScope root;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('scope-tree'),
    padding: const EdgeInsets.only(bottom: 24),
    children: [..._nodes(context, root)],
  );

  Iterable<Widget> _nodes(BuildContext context, AlloyScope scope) sync* {
    yield _ScopeNode(scope: scope);
    for (final child in scope.children) {
      yield* _nodes(context, child);
    }
  }
}

class _ScopeNode extends StatelessWidget {
  const _ScopeNode({required this.scope});

  final AlloyScope scope;

  @override
  Widget build(BuildContext context) {
    final registrations = RegistrationView.of(scope);
    final own = registrations.where((r) => !r.isInherited).length;

    return Padding(
      padding: EdgeInsets.only(left: scope.depth * 16.0),
      child: ExpansionTile(
        key: Key('scope-${scope.name}-${scope.depth}'),
        initiallyExpanded: scope.depth == 0,
        title: Text(scope.name),
        subtitle: Text(
          '${scope.state.name} · $own registration(s) · '
          '${scope.children.length} child(ren)',
        ),
        children: [
          for (final registration in registrations)
            _RegistrationTile(scope: scope, registration: registration),
        ],
      ),
    );
  }
}

class _RegistrationTile extends StatelessWidget {
  const _RegistrationTile({required this.scope, required this.registration});

  final AlloyScope scope;
  final RegistrationView registration;

  @override
  Widget build(BuildContext context) {
    final kind = registration.kind?.name ?? 'gone';
    final where = registration.isInherited
        ? 'inherited from "${registration.owner.name}"'
        : 'registered here';

    return ListTile(
      key: Key('registration-${registration.key}'),
      dense: true,
      title: Text('${registration.key}'),
      subtitle: Text('$kind · $where'),
      trailing: registration.isInherited
          ? const Icon(Icons.subdirectory_arrow_right, size: 16)
          : null,
      onTap: () => showModalBottomSheet<void>(
        context: context,
        builder: (_) =>
            RegistrationDetailSheet(scope: scope, registration: registration),
      ),
    );
  }
}
