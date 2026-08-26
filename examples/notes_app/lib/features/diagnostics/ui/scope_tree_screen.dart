import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/features/session/session_manager.dart';

class ScopeTreeScreen extends StatefulWidget {
  const ScopeTreeScreen({super.key});

  @override
  State<ScopeTreeScreen> createState() => _ScopeTreeScreenState();
}

class _ScopeTreeScreenState extends State<ScopeTreeScreen> {
  SessionManager? _session;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = context.alloy<SessionManager>();
    if (identical(session, _session)) return;
    _session?.removeListener(_onChanged);
    _session = session;
    session.addListener(_onChanged);
  }

  @override
  void dispose() {
    _session?.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final root = context.alloyScope;

    return Scaffold(
      appBar: AppBar(title: const Text('Scope tree')),
      body: ListView(
        key: const Key('scope-tree'),
        children: [
          for (final line in root.debugDescribeTree().split('\n'))
            ListTile(dense: true, title: Text(line)),
        ],
      ),
    );
  }
}
