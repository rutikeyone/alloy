import 'package:cobalt_flutter/cobalt_flutter.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/bootstrap/boot_log.dart';
import 'package:notes_app/features/environments/domain/api_client.dart';
import 'package:notes_app/l10n/notes_app_l10n.dart';

class EnvironmentsScreen extends StatelessWidget {
  const EnvironmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = NotesL10n.of(context);
    final environment = context.cobalt<CobaltEnvironment>();
    final scope = context.cobaltScope;
    final api = scope.isRegistered<ApiClient>()
        ? context.cobalt<ApiClient>()
        : null;
    final armed = BootLog.steps.contains('report-crashes');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.environments)),
      body: ListView(
        children: [
          ListTile(
            key: const Key('active-environment'),
            title: Text(l10n.activeEnvironment),
            subtitle: Text(environment.name),
          ),
          const Divider(),
          ListTile(
            key: const Key('api-client'),
            title: const Text('get<ApiClient>()'),
            subtitle: Text(
              api == null
                  ? l10n.nothingRegistered(environment.name)
                  : l10n.apiClientLine(
                      api.implementation,
                      api.endpoint ?? l10n.noNetwork,
                    ),
            ),
          ),
          ListTile(
            key: const Key('crash-reporting'),
            title: Text(l10n.crashReportingStep),
            subtitle: Text(armed ? l10n.stepRan : l10n.stepSkipped),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.environmentsExplained),
          ),
        ],
      ),
    );
  }
}
