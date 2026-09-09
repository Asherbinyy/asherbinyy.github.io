import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/locale_controller.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/features/trace/domain/trace_geometry.dart';
import 'package:nocturne/features/trace/presentation/telemetry_trace.dart';
import 'package:nocturne/features/trace/presentation/trace_burst_label.dart';
import 'package:nocturne/features/trace/presentation/trace_anchor_registry.dart';

/// The trace, wired to the career content.
///
/// Keeps the content lookup out of `TelemetryTrace`, which stays a pure
/// presentation of bursts it is handed — so the maths and the painter can be
/// tested without a repository anywhere near them.
class StationTrace extends ConsumerWidget {
  /// [controller] is the page scroll the trace reads.
  const StationTrace({required this.controller, super.key});

  /// The page's scroll controller.
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final roles = switch (ref.watch(careerProvider).valueOrNull) {
      ContentReady(:final data) => data.roles,
      _ => const <CareerRole>[],
    };
    if (roles.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final bursts = TraceGeometry.layout([
      for (final role in roles)
        (
          id: role.id,
          months: TraceGeometry.durationInMonths(
            start: role.start,
            end: role.end,
            now: now,
          ),
          appCount: role.appIds.length,
          traceWeight: role.traceWeight,
        ),
    ]);

    return TelemetryTrace(
      controller: controller,
      bursts: bursts,
      labels: {for (final role in roles) role.id: _labelFor(role, locale)},
      anchorRegistry: ref.watch(traceAnchorRegistryProvider),
    );
  }

  /// A burst's readout, built only from what the content states.
  ///
  /// Company, dates and country, all stated by the content. Nothing is
  /// derived: five of the six roles carry no company, and those fall back to
  /// the city rather than to an invented employer name.
  static TraceLabel _labelFor(CareerRole role, AppLocale locale) {
    final company = role.company;
    final meta = StringBuffer(role.start)
      ..write(' to ')
      ..write(role.end ?? '')
      ..write(' · ')
      ..write(role.country);
    return (id: role.id, title: company ?? role.city, meta: meta.toString());
  }
}
