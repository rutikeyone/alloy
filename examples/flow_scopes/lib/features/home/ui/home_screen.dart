import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flow_scopes/app/app_routes.dart';
import 'package:flow_scopes/core/event_log.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final log = context.alloy<EventLog>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alloy · flow scopes'),
        actions: [
          IconButton(
            key: const Key('open-scope-tree'),
            tooltip: 'what is alive right now',
            icon: const Icon(Icons.account_tree),
            onPressed: () => context.go(AppRoutes.scopeTree),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: log,
        builder: (context, _) => ListView(
          children: [
            const ListTile(
              title: Text('Open a flow'),
              subtitle: Text(
                'the scope is created on entry and disposed on exit',
              ),
            ),
            for (final orderId in const ['1', '2'])
              ListTile(
                key: Key('open-order-$orderId'),
                title: Text('Order $orderId'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.summary(orderId)),
              ),
            ListTile(
              key: const Key('open-workspace'),
              title: const Text('Workspace (tabs)'),
              subtitle: const Text('a shell scope plus a scope per tab'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.workspaceFeed),
            ),
            const Divider(),
            const ListTile(title: Text('Event log')),
            if (log.entries.isEmpty)
              const ListTile(
                dense: true,
                title: Text('nothing yet', key: Key('log-empty')),
              ),
            for (final entry in log.entries)
              ListTile(dense: true, title: Text(entry, key: Key('log-$entry'))),
          ],
        ),
      ),
    );
  }
}
