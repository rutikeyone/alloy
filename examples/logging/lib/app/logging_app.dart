import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_talker/alloy_talker.dart';
import 'package:flutter/material.dart';
import 'package:logging_example/app/app_scope.dart';
import 'package:logging_example/features/home/ui/home_screen.dart';
import 'package:talker/talker.dart';

class LoggingApp extends StatelessWidget {
  const LoggingApp({required this.talker, super.key});

  final Talker talker;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Alloy observability',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
    ),
    builder: AlloyAppScope.builder(
      root: const AppScope(),
      bootstrap: () => [WarmUp()],
      rootName: 'app',
      observers: [AlloyTalkerObserver(talker, verbose: true)],
      loading: const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
    home: HomeScreen(talker: talker),
  );
}
