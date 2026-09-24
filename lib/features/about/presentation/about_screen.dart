import 'package:material_ui/material_ui.dart';

import 'package:nocturne/core/widgets/skill_groups.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:nocturne/app/app_route.dart';
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
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/widgets/loading/carrier_empty_state.dart';
import 'package:nocturne/core/widgets/loading/skeleton_panel.dart';
import 'package:nocturne/core/widgets/loading/skeleton_text.dart';
import 'package:nocturne/core/widgets/loading/sweep_scope.dart';
import 'package:nocturne/features/about/presentation/widgets/contact_links.dart';
import 'package:nocturne/features/about/presentation/widgets/courtyard_door.dart';
import 'package:nocturne/features/about/presentation/widgets/falcon_courier.dart';
import 'package:nocturne/features/about/presentation/widgets/education_table.dart';
import 'package:nocturne/features/about/presentation/widgets/life_flow.dart';
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
              // Two thirds to the words, one third held back. The biography ran
              // the full width of a 1440 monitor, which is a 110-character
              // measure -- far past the point where an eye loses its place
              // returning to the next line -- and it left the skills grid
              // stretched thin to match.
              //
              // The third that was held open for "something that describes
              // him, probably a moving image": the owner asked for it to be his
              // life as a workflow that runs, and it is.
              Expanded(flex: 2, child: identity),
              SizedBox(width: tokens.space32),
              const Expanded(child: LifeFlow()),
            ],
          )
        else ...[
          portrait,
          SizedBox(height: tokens.space24),
          identity,
          SizedBox(height: tokens.space32),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Tokens.lifeFlowMaxWidth,
            ),
            child: const LifeFlow(),
          ),
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
        const CourtyardDoor(),
        SizedBox(height: tokens.space48),
        Text(l10n.aboutContact, style: context.type.heading),
        SizedBox(height: tokens.space16),
        // On a panel the width of the education cards above it, the way Home
        // and Services hold theirs. Loose, the email buttons, the booking row
        // and the social grid each stopped at a different edge.
        SizedBox(
          width: double.infinity,
          child: InstrumentPanel(
            fill: tokens.surface,
            padding: EdgeInsets.all(tokens.space24),
            // The falcon beside the links on a wide screen: the panel was
            // the plainest thing on the page, and the owner asked for a
            // picture on its right.
            child: LayoutBuilder(
              builder: (context, constraints) {
                final links = ContactLinks(
                  contact: profile.contact,
                  links: profile.links,
                );
                if (constraints.maxWidth < Tokens.courierFrom) return links;
                return Row(
                  children: [
                    Expanded(child: links),
                    SizedBox(width: tokens.space32),
                    const FalconCourier(),
                  ],
                );
              },
            ),
          ),
        ),
        SizedBox(height: tokens.space48),
        Text(l10n.aboutWriting, style: context.type.heading),
        SizedBox(height: tokens.space16),
        // Three, not the archive: the spec puts writing at the foot of About
        // as evidence it exists, and `/writing` is where the list lives.
        // The artwork credit used to sit here, under the writing, as a
        // button. The owner asked for it gone from the page and it is: it
        // lives in the footer now, which is where a colophon belongs. It
        // cannot be deleted outright -- the guardian model is CC BY-SA and
        // attribution is a condition of using it, not a decoration.
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
        //
        // The biography where the owner has written one, and the strapline
        // only as a fallback. This page printed `positioning` verbatim, so a
        // visitor who clicked through to read about the person was handed the
        // same sentence the home page opens with.
        Text(
          (profile.biography ?? profile.positioning).resolve(locale),
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
        SizedBox(height: tokens.space24),
        SizedBox(
          width: double.infinity,
          child: SkillGroups(profile: profile, locale: locale),
        ),
        SizedBox(height: tokens.space32),
        // Two ways out of this page, because a page about a person should end
        // in something to do. The column beside the portrait ran out of
        // content half way down the frame and the owner said so.
        Wrap(
          spacing: tokens.space12,
          runSpacing: tokens.space12,
          children: [
            _RouteButton(
              label: context.l10n.aboutViewWork,
              icon: Icons.grid_view_rounded,
              route: AppRoute.work,
              isPrimary: false,
            ),
            _RouteButton(
              label: context.l10n.aboutBookService,
              icon: Icons.handshake_outlined,
              route: AppRoute.services,
              isPrimary: true,
            ),
          ],
        ),
      ],
    );
  }
}

/// One of the two ways on from About.
class _RouteButton extends StatefulWidget {
  const _RouteButton({
    required this.label,
    required this.icon,
    required this.route,
    required this.isPrimary,
  });

  final String label;
  final IconData icon;
  final AppRoute route;

  /// The gold one. Only one of the pair is: section 2 spends amber on the
  /// single thing a page most wants a visitor to do, and here that is asking
  /// for work rather than reading more of it.
  final bool isPrimary;

  @override
  State<_RouteButton> createState() => _RouteButtonState();
}

class _RouteButtonState extends State<_RouteButton> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      label: widget.label,
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) {
          final isLit = _states.value.contains(WidgetState.hovered);
          final fill = widget.isPrimary
              ? (isLit ? tokens.beaconGlow : tokens.beacon)
              : Colors.transparent;
          final ink = widget.isPrimary
              ? tokens.void_
              : (isLit ? tokens.beaconGlow : tokens.beacon);

          return FocusRing(
            isFocused: _states.value.contains(WidgetState.focused),
            child: InkWell(
              onTap: () => context.goNamed(widget.route.name),
              statesController: _states,
              borderRadius: BorderRadius.circular(tokens.controlRadius),
              mouseCursor: context.platform.isPointer
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: AnimatedContainer(
                duration: ReducedMotion.duration(context, Motion.quick),
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.space24,
                  vertical: tokens.space12,
                ),
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(tokens.controlRadius),
                  border: Border.all(
                    color: widget.isPrimary ? fill : tokens.hairlineStrong,
                    width: tokens.hairlineWidth,
                  ),
                ),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.icon,
                        size: Tokens.contactIconSize,
                        color: ink,
                      ),
                      SizedBox(width: tokens.space12),
                      Text(
                        widget.label,
                        style: context.type.body.copyWith(color: ink),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
