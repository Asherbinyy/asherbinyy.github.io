import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';

/// What he works in, in a panel that says so.
///
/// This was three lines of "Skills: a, b, c" run together as prose — plain
/// text nobody would look at, and the same inventory About prints a page
/// later. Then it was a bare row of chips with a link off the page, which
/// left a row of boxes floating under the buttons with nothing saying what
/// they were.
///
/// It is a titled panel now, and the rest of the skills open underneath rather
/// than sending anybody anywhere: a reader who wants to know what he works in
/// is asking a small question and should not have to change page to have it
/// answered.
class ProfileSkills extends StatefulWidget {
  /// Shows [profile]'s skills, a few at a time.
  const ProfileSkills({required this.profile, super.key});

  /// Shared owner-supplied content.
  final Profile profile;

  /// How many fit on one line before the eye stops reading them.
  static const int shown = 6;

  @override
  State<ProfileSkills> createState() => _ProfileSkillsState();
}

class _ProfileSkillsState extends State<ProfileSkills> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final skills = widget.profile.skills;
    if (skills.isEmpty) return const SizedBox.shrink();

    final tokens = context.tokens;
    final visible = _isOpen ? skills : skills.take(ProfileSkills.shown);
    final rest = skills.length - ProfileSkills.shown;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.controlRadius),
        border: Border.all(color: tokens.hairline, width: tokens.hairlineWidth),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: tokens.space16,
                  height: tokens.hairlineWidth * 2,
                  child: ColoredBox(color: tokens.beacon),
                ),
                SizedBox(width: tokens.space8),
                Text(
                  context.l10n.profileSkills,
                  style: context.type.telemetryS.copyWith(
                    color: tokens.textMuted,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.space16),
            // Height animated, so the extra rows arrive rather than appearing.
            AnimatedSize(
              duration: ReducedMotion.duration(context, Motion.standard),
              curve: MotionCurves.emphasized,
              alignment: AlignmentDirectional.topStart,
              child: Wrap(
                spacing: tokens.space8,
                runSpacing: tokens.space8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final skill in visible) _Chip(label: skill),
                  if (rest > 0)
                    _More(
                      label: _isOpen
                          ? context.l10n.profileSkillsLess
                          : context.l10n.profileSkillsMore(rest),
                      isOpen: _isOpen,
                      onTap: () => setState(() => _isOpen = !_isOpen),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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

/// The chip that opens the rest, and closes them again.
class _More extends StatefulWidget {
  const _More({required this.label, required this.isOpen, required this.onTap});

  final String label;
  final bool isOpen;
  final VoidCallback onTap;

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
      button: true,
      expanded: widget.isOpen,
      label: widget.label,
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) {
          final isLit = _states.value.contains(WidgetState.hovered);
          return FocusRing(
            isFocused: _states.value.contains(WidgetState.focused),
            child: InkWell(
              onTap: widget.onTap,
              statesController: _states,
              borderRadius: BorderRadius.circular(tokens.controlRadius),
              mouseCursor: context.platform.isPointer
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: AnimatedContainer(
                duration: ReducedMotion.duration(context, Motion.quick),
                curve: MotionCurves.emphasized,
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.space12,
                  vertical: tokens.space8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(tokens.controlRadius),
                  border: Border.all(
                    color: isLit ? tokens.beacon : tokens.hairlineStrong,
                    width: tokens.hairlineWidth,
                  ),
                ),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: context.type.bodyS.copyWith(
                          color: isLit ? tokens.beaconGlow : tokens.beacon,
                        ),
                      ),
                      SizedBox(width: tokens.space8),
                      AnimatedRotation(
                        turns: widget.isOpen ? 0.5 : 0,
                        duration: ReducedMotion.duration(
                          context,
                          Motion.standard,
                        ),
                        curve: MotionCurves.emphasized,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: Tokens.contactIconSize,
                          color: isLit ? tokens.beaconGlow : tokens.beacon,
                        ),
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
