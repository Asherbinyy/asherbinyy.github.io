import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/app_route.dart';

/// An empty themed route, deliberately containing no invented display copy.
class PlaceholderScreen extends ConsumerWidget {
  /// Carries identity for route verification without rendering it as content.
  const PlaceholderScreen({required this.route, super.key});

  /// Route represented by this placeholder.
  final AppRoute route;

  @override
  Widget build(BuildContext context, WidgetRef ref) => const Scaffold();
}
