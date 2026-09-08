import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/locale_controller.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/education.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/widgets/loading/carrier_empty_state.dart';
import 'package:nocturne/core/widgets/loading/skeleton_panel.dart';
import 'package:nocturne/core/widgets/loading/skeleton_text.dart';
import 'package:nocturne/core/widgets/loading/sweep_scope.dart';
import 'package:nocturne/features/about/presentation/widgets/contact_links.dart';
import 'package:nocturne/features/about/presentation/widgets/education_table.dart';
import 'package:nocturne/features/about/presentation/widgets/portrait_frame.dart';
import 'package:nocturne/features/writing/presentation/widgets/writing_list.dart';

/// `/about` — background, education and contact.
///
/// The screen spec asks for a portrait left and biography right. No biography
/// prose exists in `assets/content/`, and `AGENTS.md` §3 forbids writing one,
/// so the right column carries the identity the content does supply —
/// positioning, status and location — and the biography arrives without a code
/// change when the owner writes it.
class AboutScreen extends ConsumerWidget {
  /// Reads profile and education from the content layer.
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final profile = ref.watch(profileProvider);
    final education = ref.watch(educationProvider);

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: context.platform.gutter,
        end: context.platform.gutter,
        top: tokens.space48,
        bottom: tokens.space64,
      ),
      child: switch (profile) {
        AsyncData(value: ContentReady(data: final data)) => _About(
          profile: data,
          locale: ref.watch(localeControllerProvider),
          education: switch (education.valueOrNull) {
            ContentReady(data: final entries) => entries,
            _ => const Education(entries: []),
          },
        ),
        AsyncData() || AsyncError() => const _Unavailable(),
        _ => const _Loading(),
      },
    );
  }
}

class _About extends StatelessWidget {
  const _About({
    required this.profile,
    required this.education,
    required this.locale,
  });

  final Profile profile;
  final Education education;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    // The spec's two columns need room. Below the rail breakpoint the portrait
    // stacks above the text rather than shrinking to a thumbnail beside it.
    final isTwoColumn =
        context.platform.viewport.index >= ViewportClass.expanded.index;

    final identity = _Identity(profile: profile, locale: locale);
    const portrait = PortraitFrame();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.aboutHeading, style: context.type.displayM),
        SizedBox(height: tokens.space32),
        if (isTwoColumn)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              portrait,
              SizedBox(width: tokens.space32),
              Expanded(child: identity),
            ],
          )
        else ...[
          portrait,
          SizedBox(height: tokens.space24),
          identity,
        ],
        SizedBox(height: tokens.space48),
        Text(l10n.aboutEducation, style: context.type.heading),
        SizedBox(height: tokens.space16),
        EducationTable(education: education),
        SizedBox(height: tokens.space48),
        // The interests themselves moved to `/courtyard`, where they have
        // room to be interactive rather than a row of tiles at the foot of a
        // CV page. What stays here is the door to them: someone who has read
        // this far has the evidence and is deciding whether they want to work
        // with him, and that is the question the courtyard answers.
        const _CourtyardDoor(),
        SizedBox(height: tokens.space48),
        Text(l10n.aboutContact, style: context.type.heading),
        SizedBox(height: tokens.space16),
        ContactLinks(contact: profile.contact),
        SizedBox(height: tokens.space48),
        Text(l10n.aboutWriting, style: context.type.heading),
        SizedBox(height: tokens.space16),
        // Three, not the archive: the spec puts writing at the foot of About
        // as evidence it exists, and `/writing` is where the list lives.
        const WritingList(limit: 3),
      ],
    );
  }
}

/// Positioning, status and location — the biography the content actually has.
class _Identity extends StatelessWidget {
  const _Identity({required this.profile, required this.locale});

  final Profile profile;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final status = profile.status?.resolve(locale);
    final location = profile.location?.resolve(locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // No instrument metaphor in prose about the person, per the spec.
        Text(
          profile.positioning.resolve(locale),
          style: type.bodyL.copyWith(color: tokens.textPrimary),
        ),
        if (status != null) ...[
          SizedBox(height: tokens.space16),
          Text(status, style: type.body.copyWith(color: tokens.textSecondary)),
        ],
        if (location != null) ...[
          SizedBox(height: tokens.space8),
          Text(
            location,
            style: type.telemetryS.copyWith(color: tokens.textMuted),
          ),
        ],
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => SweepScope(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SkeletonText(lines: 1, style: context.type.displayM),
        SizedBox(height: context.tokens.space32),
        const SkeletonPanel(
          width: PortraitFrame.width,
          height: PortraitFrame.height,
        ),
        SizedBox(height: context.tokens.space32),
        SkeletonText(lines: 6, style: context.type.body),
      ],
    ),
  );
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) =>
      CarrierEmptyState(direction: context.l10n.heroContentUnavailable);
}

/// The way through to `/courtyard` from the foot of the credentials.
class _CourtyardDoor extends StatelessWidget {
  const _CourtyardDoor();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;

    return InstrumentPanel(
      fill: tokens.surface,
      padding: EdgeInsets.all(tokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.courtyardHeading, style: type.heading),
          SizedBox(height: tokens.space8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
            child: Text(
              l10n.courtyardIntro,
              style: type.body.copyWith(color: tokens.textSecondary),
            ),
          ),
          SizedBox(height: tokens.space16),
          BeaconButton(
            label: l10n.aboutOffDuty,
            onPressed: () => context.goNamed(AppRoute.courtyard.name),
          ),
        ],
      ),
    );
  }
}
