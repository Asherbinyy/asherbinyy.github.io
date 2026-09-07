import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/analytics/events.dart';
import 'package:nocturne/core/analytics/interactions.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/static_route.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';

/// Opens the CV, and records that it was opened.
///
/// One widget rather than the same button written at each call site, because
/// the CV open is the single most valuable signal the console reports and a
/// second copy of this button would eventually be the one that forgot to
/// record.
///
/// The label names its outcome, which `01-DESIGN-SYSTEM.md` §9 requires: it
/// reads "Download" only where `profile.cvFile` actually supplies a file, and
/// falls back to "Read" and the static HTML page where it does not. The owner
/// supplied the PDF on 2026-09-07, closing an item open since milestone 1, but
/// the fallback stays — the HTML CV is the indexable surface and it does not
/// stop existing because a PDF now sits beside it.
class CvButton extends ConsumerWidget {
  /// [route] is the page the viewer opened the CV from.
  const CvButton({required this.route, super.key});

  /// The originating route, recorded with the event.
  final AppRoute route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cvFile = switch (ref.watch(profileProvider).valueOrNull) {
      ContentReady<Profile>(:final data) => data.cvFile,
      ContentFallback<Profile>(:final profile) => profile.cvFile,
      _ => null,
    };

    return BeaconButton(
      label: cvFile == null
          ? context.l10n.heroReadTheCv
          : context.l10n.heroDownloadTheCv,
      onPressed: () {
        ref.recordInteraction(
          AnalyticsEvent.cvOpened,
          route: route.path,
          inputMode: context.platform.inputMode,
        );
        // Flutter serves a declared asset under its own `assets/` prefix, so
        // the bundled path is not the URL. Built here rather than stored in
        // content, because it is a fact about the build output and not
        // something the owner should have to know when editing JSON.
        openStaticRoute(cvFile == null ? AppRoute.cv.path : 'assets/$cvFile');
      },
    );
  }
}
