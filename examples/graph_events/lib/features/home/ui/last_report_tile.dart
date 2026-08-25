import 'package:flutter/material.dart';
import 'package:graph_events/app/report_log.dart';

/// Shows the most recent failure Alloy reported, with the trail behind it.
///
/// This is what a crash reporter receives. The exception alone would say the
/// teardown threw; the breadcrumbs say which scope had been pushed and what it
/// had built by then, which is the part that makes it actionable.
class LastReportTile extends StatelessWidget {
  const LastReportTile({required this.log, super.key});

  final ReportLog log;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: log,
    builder: (context, _) {
      final report = log.reports.firstOrNull;
      if (report == null) {
        return const ListTile(
          key: Key('no-report'),
          title: Text('No failures reported'),
          subtitle: Text('close the session that will not close'),
        );
      }

      return ExpansionTile(
        key: const Key('last-report'),
        title: Text(report.failure.message),
        subtitle: Text(
          '${report.failure.kind.name} · '
          '${report.breadcrumbs.length} breadcrumb(s)',
        ),
        children: [
          for (final crumb in report.breadcrumbs.reversed)
            ListTile(
              dense: true,
              title: Text(crumb.message),
              subtitle: Text(crumb.kind.name),
            ),
        ],
      );
    },
  );
}
