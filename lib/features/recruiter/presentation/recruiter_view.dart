import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/locale_controller.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/content/models/education.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/loading/carrier_empty_state.dart';

/// Recruiter Mode: the whole site collapsed into one quiet page.
///
/// `00-PROJECT-BRIEF.md` section 5 calls this the highest-leverage feature on
/// the site: it demonstrates the judgement to know when not to be flashy, and
/// removes the risk that a conservative reviewer bounces off the main
/// experience. One screen, no map, no trace, no motion.
///
/// It renders the same content as the static `/brief` page — the featured
/// applications, education and contact — from the same JSON, so the two cannot
/// drift.
class RecruiterView extends ConsumerWidget {
  /// Reads identity, applications and education from the content layer.
  const RecruiterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final profile = switch (ref.watch(profileProvider).valueOrNull) {
      ContentReady(:final data) => data,
      ContentFallback(:final profile) => profile,
      _ => null,
    };
    if (profile == null) {
      return Padding(
        padding: EdgeInsets.all(context.tokens.space48),
        child: CarrierEmptyState(
          direction: context.l10n.heroContentUnavailable,
        ),
      );
    }

    final featured = switch (ref.watch(appsProvider).valueOrNull) {
      ContentReady(:final data) =>
        data.apps.where((app) => app.featured).toList(),
      _ => const <ShippedApp>[],
    };
    final entries = switch (ref.watch(educationProvider).valueOrNull) {
      ContentReady(:final data) => data.entries,
      _ => const <EducationEntry>[],
    };

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: context.platform.gutter,
        end: context.platform.gutter,
        top: context.tokens.space48,
        bottom: context.tokens.space64,
      ),
      child: _Brief(
        profile: profile,
        featured: featured,
        entries: entries,
        locale: locale,
      ),
    );
  }
}

class _Brief extends StatelessWidget {
  const _Brief({
    required this.profile,
    required this.featured,
    required this.entries,
    required this.locale,
  });

  final Profile profile;
  final List<ShippedApp> featured;
  final List<EducationEntry> entries;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;
    final status = profile.status;
    final location = profile.location;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(profile.name.resolve(locale), style: type.displayL),
        SizedBox(height: tokens.space8),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: type.measureFor(type.bodyL)),
          child: Text(
            profile.positioning.resolve(locale),
            style: type.bodyL.copyWith(color: tokens.textSecondary),
          ),
        ),
        if (location != null) Text(location.resolve(locale), style: type.meta),
        if (status != null) ...[
          SizedBox(height: tokens.space8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
            child: Text(status.resolve(locale), style: type.body),
          ),
        ],
        SizedBox(height: tokens.space32),
        if (featured.isNotEmpty)
          _Row(
            label: l10n.recruiterShipped,
            child: Wrap(
              spacing: tokens.space16,
              runSpacing: tokens.space8,
              children: [
                for (final app in featured) Text(app.name, style: type.body),
              ],
            ),
          ),
        for (final entry in entries)
          _Row(
            label: l10n.recruiterEducation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.institution, style: type.body),
                Text(
                  entry.award,
                  style: type.bodyS.copyWith(color: tokens.textSecondary),
                ),
              ],
            ),
          ),
        _Row(
          label: l10n.recruiterContact,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(profile.contact.email, style: type.telemetry),
              for (final link in <Uri?>[
                profile.contact.linkedin,
                profile.contact.github,
              ])
                if (link != null) Text(link.host, style: type.telemetryS),
            ],
          ),
        ),
      ],
    );
  }
}

/// One labelled row of the brief: label in the leading column, value beside it.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: tokens.space128,
            child: Text(label, style: context.type.meta),
          ),
          SizedBox(width: tokens.space16),
          Expanded(child: child),
        ],
      ),
    );
  }
}
