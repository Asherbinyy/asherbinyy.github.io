import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/core/platform/preference_store.dart';

/// The provider overrides the real application runs with.
///
/// Extracted from `main.dart` so it can be tested. It was not, and the cost of
/// that was the whole site: `assetReaderProvider` defaults to a reader that
/// fails every read — deliberately, so a test that forgets to inject one
/// exercises the fallback path rather than silently reading the real bundle —
/// and `main.dart` never installed the real one. Every content read failed in
/// production while every test passed, because tests inject their own reader
/// and never touch this path.
///
/// Anything added here must be reachable from a test, or it is untested by
/// construction.
List<Override> productionOverrides({required PreferenceStore preferences}) => [
  preferenceStoreProvider.overrideWithValue(preferences),
  // The one line whose absence emptied every page on the site.
  assetReaderProvider.overrideWithValue(rootBundle.loadString),
];
