import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/material.dart';
import 'package:testing_patterns/src/greeter.dart';

/// Resolves from the nearest scope, so a widget test can shadow what it gets
/// without the widget knowing.
class GreetingScreen extends StatelessWidget {
  const GreetingScreen({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FutureBuilder<String>(
        future: context.alloy<Greeter>().greet(name),
        builder: (context, snapshot) =>
            Text(snapshot.data ?? 'loading', key: const Key('greeting')),
      ),
    ),
  );
}
