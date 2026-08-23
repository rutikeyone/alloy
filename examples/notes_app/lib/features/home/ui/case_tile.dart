import 'package:flutter/material.dart';

class CaseTile extends StatelessWidget {
  const CaseTile({
    required this.title,
    required this.subtitle,
    required this.route,
    super.key,
  });

  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => Navigator.of(context).pushNamed(route),
  );
}
