import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/app.dart';
import 'package:nocturne/app/bootstrap.dart';
import 'package:nocturne/core/platform/browser_navigation.dart';
import 'package:nocturne/core/platform/shared_preference_store.dart';

/// Loads the viewer's stored preferences before the first frame, so the app
/// never paints one theme and then flips to another.
///
/// Persistent device storage holds only the choices in `PreferenceKey`.
/// Acquisition uses one non-identifying, tab-scoped functional marker; campaign
/// attribution uses the owner-defined entry slug for that tab. Neither is an
/// analytics identifier, and no cross-session viewer identifier is stored.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureBrowserNavigation();
  final preferences = await SharedPreferenceStore.load();
  runApp(
    ProviderScope(
      overrides: productionOverrides(preferences: preferences),
      child: const NocturneApp(),
    ),
  );
}
