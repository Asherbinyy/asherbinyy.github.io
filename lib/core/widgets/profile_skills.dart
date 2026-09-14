import 'package:material_ui/material_ui.dart';

import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';

/// What he works in, at a glance, with the rest a click away.
///
/// This was three lines of "Skills: a, b, c" run together as prose. The owner
/// called it plain text nobody would look at, and he was right: a
/// comma-separated list of thirteen things is a paragraph pretending to be
/// data, and it repeated About word for word a page later.
///
/// What is here now is the first few as chips and a way through to the rest.
/// Home says enough to place him and hands the detail to the page whose job
/// that is, rather than printing the same inventory twice.
class ProfileSkills extends StatelessWidget {
  /// Shows a sample of [profile]'s skills and links to the full set.
  const ProfileSkills({required this.profile, super.key});

  /// Shared owner-supplied content.
  final Profile profile;

  /// How many fit on one line before the eye stops reading them.
  static const int shown = 6;

  @override
  Widget build(BuildContext context) {
    if (profile.skills.isEmpty) return const SizedBox.shrink();
    final tokens = context.tokens;
    final sample = profile.skills.take(shown).toList();
    final rest = profile.skills.length - sample.length;

    return Wrap(
      spacing: tokens.space8,
      runSpacing: tokens.space8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final skill in sample) _Chip(label: skill),
        _More(
          label: rest > 0
              ? context.l10n.profileSkillsMore(rest)
              : context.l10n.profileSkillsAll,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(Tokens.controlRadius),
        border: Border.all(color: tokens.hairline, width: tokens.hairlineWidth),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.space12,
          vertical: tokens.space8,
        ),
        child: Text(
          label,
          style: context.type.bodyS.copyWith(color: tokens.textPrimary),
        ),
      ),
    );
  }
}

/// The way through to the full set, on About.
class _More extends StatefulWidget {
  const _More({required this.label});

  final String label;

  @override
  State<_More> createState() => _MoreState();
}

class _MoreState extends State<_More> {
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
      link: true,
      label: widget.label,
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) {
          final isLit = _states.value.contains(WidgetState.hovered);
          return FocusRing(
            isFocused: _states.value.contains(WidgetState.focused),
            child: InkWell(
              onTap: () => context.goNamed(AppRoute.about.name),
              statesController: _states,
              borderRadius: BorderRadius.circular(tokens.controlRadius),
              mouseCursor: context.platform.isPointer
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.space12,
                  vertical: tokens.space8,
                ),
                child: ExcludeSemantics(
                  child: AnimatedDefaultTextStyle(
                    duration: ReducedMotion.duration(context, Motion.quick),
                    curve: MotionCurves.emphasized,
                    style: context.type.bodyS.copyWith(
                      color: isLit ? tokens.beaconGlow : tokens.beacon,
                    ),
                    child: Text(widget.label),
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
