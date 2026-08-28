import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flow_scopes/features/workspace/domain/tab_marker.dart';
import 'package:flow_scopes/l10n/flow_scopes_l10n.dart';
import 'package:flutter/material.dart';

class TabScreen extends StatelessWidget {
  const TabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = FlowScopesL10n.of(context);
    final marker = context.alloy<TabMarker>();

    return ListView(
      children: [
        ListTile(
          key: Key('tab-${marker.label}'),
          title: const Text('get<TabMarker>()'),
          subtitle: Text(
            l10n.markerLine(marker.label, context.alloyScope.name),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.tabsExplained),
        ),
      ],
    );
  }
}
