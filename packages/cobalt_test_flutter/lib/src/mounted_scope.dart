import 'package:cobalt_flutter/cobalt_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The root of the graph a mounted application owns.
///
/// Written because reaching it by hand is easy to get wrong in two ways this
/// repository got wrong four separate times. The first is where to read from:
/// the provider is published *inside* `MaterialApp`, below its builder, so a
/// context taken from the `MaterialApp` itself sits above it and finds
/// nothing. The second is which scope you get: a screen that owns a scope
/// publishes its own provider, so the nearest one is the screen's rather than
/// the graph's — hence `root`.
///
/// Reads the published widget rather than looking one up from a context,
/// because `CobaltScopeProvider.of` searches *above* the element it is given
/// and would skip the very provider that was found. It takes the innermost and
/// climbs, rather than trusting the first one found to be the outermost —
/// which makes the answer independent of where in the tree you happened to
/// look from.
///
/// Call it after [settle]: nothing is published until `init()` finishes.
CobaltScope mountedRootScope(WidgetTester tester) => tester
    .widgetList<CobaltScopeProvider>(find.byType(CobaltScopeProvider))
    .last
    .scope
    .root;
