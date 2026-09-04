import 'package:flutter/material.dart';
import 'package:graph_events/app/report_log.dart';
import 'package:graph_events/l10n/graph_events_l10n.dart';

/// Shows the most recent failure Cobalt reported, with the trail behind it.
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
      final l10n = GraphEventsL10n.of(context);
      final report = log.reports.firstOrNull;
      if (report == null) {
        return ListTile(
          key: const Key('no-report'),
          title: Text(l10n.noFailures),
          subtitle: Text(l10n.noFailuresDetail),
        );
      }

      return ExpansionTile(
        key: const Key('last-report'),
        title: Text(report.failure.message),
        subtitle: Text(
          l10n.reportSummary(
            report.failure.kind.name,
            report.breadcrumbs.length,
          ),
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
