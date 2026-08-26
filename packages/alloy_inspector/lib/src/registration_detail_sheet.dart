import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_inspector/src/registration_view.dart';
import 'package:flutter/material.dart';

/// What is known about one registration, and the one thing you can do to it.
///
/// Everything shown is metadata — reading it does not touch the graph.
/// Building is offered separately and says what it costs, because resolving a
/// lazy singleton that nobody had asked for creates it for real: the object
/// starts existing, the scope takes ownership of it, and a creation event
/// appears in the log. An inspector that resolved rows to display them would
/// change the thing it is there to observe.
class RegistrationDetailSheet extends StatefulWidget {
  /// Describes [registration] as seen from [scope].
  const RegistrationDetailSheet({
    required this.scope,
    required this.registration,
    super.key,
  });

  /// The scope the registration was listed under.
  final AlloyScope scope;

  /// The registration to describe.
  final RegistrationView registration;

  @override
  State<RegistrationDetailSheet> createState() =>
      _RegistrationDetailSheetState();
}

class _RegistrationDetailSheetState extends State<RegistrationDetailSheet> {
  String? _built;
  String? _failed;

  @override
  Widget build(BuildContext context) {
    final registration = widget.registration;

    return SafeArea(
      child: ListView(
        key: const Key('registration-detail'),
        shrinkWrap: true,
        children: [
          ListTile(
            title: Text('${registration.key}'),
            subtitle: Text(registration.kind?.name ?? 'no longer registered'),
          ),
          const Divider(height: 1),
          _Fact(label: 'Owned by', value: registration.owner.name),
          _Fact(
            label: 'Reached',
            value: registration.isInherited
                ? 'inherited from an ancestor'
                : 'registered in this scope',
          ),
          _Fact(
            label: 'Torn down with the scope',
            value: switch (registration.kind) {
              AlloyRegistrationKind.singleton ||
              AlloyRegistrationKind.lazySingleton ||
              AlloyRegistrationKind.asyncSingleton => 'yes',
              AlloyRegistrationKind.transient ||
              AlloyRegistrationKind.parameterized => 'no, the caller owns it',
              null => 'unknown',
            },
          ),
          if (_built case final value?)
            _Fact(key: const Key('built-value'), label: 'Built', value: value),
          if (_failed case final error?)
            _Fact(
              key: const Key('build-failed'),
              label: 'Failed',
              value: error,
            ),
          const Divider(height: 1),
          if (registration.isBuildable)
            ListTile(
              key: const Key('build-it'),
              title: const Text('Build it now'),
              subtitle: const Text(
                'Creates the instance for real and logs it — this changes the '
                'graph you are looking at',
              ),
              trailing: const Icon(Icons.play_arrow),
              onTap: _build,
            )
          else
            const ListTile(
              key: Key('not-buildable'),
              dense: true,
              title: Text('Takes a parameter, so it cannot be built from here'),
            ),
        ],
      ),
    );
  }

  void _build() {
    try {
      final instance = widget.scope.debugResolve(widget.registration.key);
      setState(() => _built = '${instance.runtimeType}');
    } on Object catch (error) {
      setState(() => _failed = '$error');
    }
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) =>
      ListTile(dense: true, title: Text(label), subtitle: Text(value));
}
