import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/material.dart';
import 'package:logging_example/app/app_scope.dart';
import 'package:logging_example/features/home/ui/home_screen.dart';
import 'package:talker/talker.dart';

class LoggingApp extends StatelessWidget {
  const LoggingApp({required this.talker, super.key});

  final Talker talker;

  @override
  Widget build(BuildContext context) => AlloyAppScope(
    start: () => startLoggingExample(talker),
    loading: const MaterialApp(
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
    child: MaterialApp(
      title: 'Alloy observability',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: HomeScreen(talker: talker),
    ),
  );
}
