import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/app.dart';
import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/core/platform/browser_navigation.dart';
import 'package:nocturne/core/platform/shared_preference_store.dart';

/// Loads the viewer's stored preferences before the first frame, so the app
/// never paints one theme and then flips to another.
///
/// The only thing read from or written to the device is the set of choices in
/// `PreferenceKey` — theme, language and Recruiter Mode. No analytics
/// identifier is stored here or anywhere else before consent.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureBrowserNavigation();
  final preferences = await SharedPreferenceStore.load();
  runApp(
    ProviderScope(
      overrides: [preferenceStoreProvider.overrideWithValue(preferences)],
      child: const NocturneApp(),
    ),
  );
}
