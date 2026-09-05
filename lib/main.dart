import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/app.dart';
import 'package:nocturne/core/platform/browser_navigation.dart';

/// Initializes the web-only foundation without storage or network side effects.
void main() {
  configureBrowserNavigation();
  runApp(const ProviderScope(child: NocturneApp()));
}
