import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flow_router/features/workspace/domain/tab_marker.dart';
import 'package:flutter/material.dart';

class TabScreen extends StatelessWidget {
  const TabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final marker = context.alloy<TabMarker>();

    return ListView(
      children: [
        ListTile(
          key: Key('tab-${marker.label}'),
          title: const Text('get<TabMarker>()'),
          subtitle: Text('${marker.label} · scope ${context.alloyScope.name}'),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Switch tabs and come back: nothing is rebuilt. A branch is kept '
            'alive, not kept visible, so its scope lives until the whole '
            'workspace closes.',
          ),
        ),
      ],
    );
  }
}
