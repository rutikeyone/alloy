import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/bootstrap/boot_log.dart';
import 'package:notes_app/features/environments/domain/api_client.dart';

class EnvironmentsScreen extends StatelessWidget {
  const EnvironmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final environment = context.alloy<AlloyEnvironment>();
    final scope = context.alloyScope;
    final api = scope.isRegistered<ApiClient>()
        ? context.alloy<ApiClient>()
        : null;
    final armed = BootLog.steps.contains('report-crashes');

    return Scaffold(
      appBar: AppBar(title: const Text('Environments')),
      body: ListView(
        children: [
          ListTile(
            key: const Key('active-environment'),
            title: const Text('active environment'),
            subtitle: Text(environment.name),
          ),
          const Divider(),
          ListTile(
            key: const Key('api-client'),
            title: const Text('get<ApiClient>()'),
            subtitle: Text(
              api?.describe ??
                  'nothing registered — no implementation claims '
                      '"${environment.name}"',
            ),
          ),
          ListTile(
            key: const Key('crash-reporting'),
            title: const Text('report-crashes bootstrap step'),
            subtitle: Text(armed ? 'ran' : 'skipped in this environment'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Both implementations are annotated with the same exposeAs. '
              'Only the one naming this environment is registered, so nothing '
              'downstream knows which it got. Pick an environment nobody '
              'claims and the type is simply absent — get<ApiClient>() would '
              'throw rather than hand back the wrong class.',
            ),
          ),
        ],
      ),
    );
  }
}
