import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/app/app_routes.dart';
import 'package:notes_app/app/app_startup.dart';
import 'package:notes_app/features/diagnostics/ui/scope_tree_screen.dart';
import 'package:notes_app/features/environments/ui/environments_screen.dart';
import 'package:notes_app/features/formatting/ui/formatters_screen.dart';
import 'package:notes_app/features/home/ui/home_screen.dart';
import 'package:notes_app/features/note_detail/ui/note_detail_screen.dart';
import 'package:notes_app/features/notes/ui/notes_screen.dart';
import 'package:notes_app/features/session/ui/session_screen.dart';

/// The app, with [AlloyAppScope] owning the root scope.
///
/// The graph is built inside `runApp` rather than before it, which is what
/// makes the two branches below possible: a splash while it starts, and a
/// screen with a retry when it fails.
class NotesApp extends StatelessWidget {
  const NotesApp({this.environment = notesEnvironment, super.key});

  final AlloyEnvironment environment;

  @override
  Widget build(BuildContext context) => AlloyAppScope(
    start: () => startNotesApp(environment: environment),
    loading: const _Starting(),
    errorBuilder: (context, error, retry) =>
        _StartupFailed(error: error, retry: retry),
    child: MaterialApp(
      title: 'Alloy showcase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      routes: {
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.notes: (_) => const NotesScreen(),
        AppRoutes.noteDetail: (_) => const NoteDetailScreen(),
        AppRoutes.session: (_) => const SessionScreen(),
        AppRoutes.formatters: (_) => const FormattersScreen(),
        AppRoutes.scopeTree: (_) => const ScopeTreeScreen(),
        AppRoutes.environments: (_) => const EnvironmentsScreen(),
      },
    ),
  );
}

class _Starting extends StatelessWidget {
  const _Starting();

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(
      body: Center(child: CircularProgressIndicator(key: Key('app-starting'))),
    ),
  );
}

class _StartupFailed extends StatelessWidget {
  const _StartupFailed({required this.error, required this.retry});

  final Object error;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('The graph could not start'),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('$error', key: const Key('startup-error')),
            ),
            FilledButton(
              key: const Key('startup-retry'),
              onPressed: retry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    ),
  );
}
