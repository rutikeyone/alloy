import 'package:flutter/widgets.dart';
import 'package:graph_events/app/audit_log.dart';
import 'package:graph_events/app/graph_events_app.dart';
import 'package:talker/talker.dart';

void main() => runApp(GraphEventsApp(talker: Talker(), audit: AuditLog()));
