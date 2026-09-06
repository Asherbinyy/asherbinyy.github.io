import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/core/analytics/events.dart';
import 'package:nocturne/core/analytics/interactions.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/static_route.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';

/// Opens the static CV, and records that it was opened.
///
/// One widget rather than the same button written at each call site, because
/// the CV open is the single most valuable signal the console reports and a
/// second copy of this button would eventually be the one that forgot to
/// record. The label reads "Read" rather than "Download" because
/// `profile.cvFile` is absent, so this opens the HTML CV rather than fetching
/// a PDF, and `01-DESIGN-SYSTEM.md` §9 requires a label to name its outcome.
class CvButton extends ConsumerWidget {
  /// [route] is the page the viewer opened the CV from.
  const CvButton({required this.route, super.key});

  /// The originating route, recorded with the event.
  final AppRoute route;

  @override
  Widget build(BuildContext context, WidgetRef ref) => BeaconButton(
    label: context.l10n.heroReadTheCv,
    onPressed: () {
      ref.recordInteraction(
        AnalyticsEvent.cvOpened,
        route: route.path,
        inputMode: context.platform.inputMode,
      );
      openStaticRoute(AppRoute.cv.path);
    },
  );
}
