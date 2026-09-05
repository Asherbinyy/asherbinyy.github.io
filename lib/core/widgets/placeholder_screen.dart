import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/app_route.dart';

/// An empty themed route body, deliberately containing no invented copy.
///
/// Renders content only — the global chrome supplies the `Scaffold` and the
/// page scroll, so this must neither nest a second scaffold nor try to expand
/// into the scroll view's unbounded height.
class PlaceholderScreen extends ConsumerWidget {
  /// Carries identity for route verification without rendering it as content.
  const PlaceholderScreen({required this.route, super.key});

  /// Route represented by this placeholder.
  final AppRoute route;

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}
