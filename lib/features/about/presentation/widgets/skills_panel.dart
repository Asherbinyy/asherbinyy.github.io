import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';

/// What the owner can do, in three tiers that do not look alike.
///
/// The previous version drew all three groups as identical grey pills, which
/// told a reader that five years of Flutter and a fortnight of LangChain were
/// the same kind of claim. They are not, and the owner was explicit that he is
/// *learning* the second group — so the page has to show both that he is
/// working in this area and that he is not overstating it.
///
/// The hierarchy is doing that job:
///
/// - **Skills** carry a gold rule. Gold is the pigment this site reserves for
///   the person and for what is live, so it marks the claims five years of
///   work stand behind.
/// - **Currently learning** is outlined rather than filled, in dimmer ink. It
///   reads as real and deliberate, and visibly not the same assertion.
/// - **Tools** is one line of small text. A list of editors is context, not a
///   qualification, and giving it equal weight was part of what made the
///   original look like a form.
///
/// Each group opens and closes on a click, which is what the owner asked for.
/// The first is open on arrival: a page whose every group is shut is a page
/// that shows a visitor nothing.
class SkillsPanel extends StatelessWidget {
  /// Established skills stay separate from topics the owner is learning.
  const SkillsPanel({required this.profile, super.key});

  /// Shared profile content; no separate About inventory.
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (profile.skills.isNotEmpty)
          _Group(
            label: context.l10n.profileSkills,
            values: profile.skills,
            emphasis: _Emphasis.established,
            isOpenAtRest: true,
          ),
        if (profile.learning.isNotEmpty) ...[
          SizedBox(height: tokens.space24),
          _Group(
            label: context.l10n.profileLearning,
            values: profile.learning,
            emphasis: _Emphasis.exploring,
          ),
        ],
        if (profile.tools.isNotEmpty) ...[
          SizedBox(height: tokens.space24),
          _Group(
            label: context.l10n.profileTools,
            values: profile.tools,
            emphasis: _Emphasis.aside,
          ),
        ],
      ],
    );
  }
}

/// How strongly a group is being claimed.
enum _Emphasis {
  /// Work the owner has been paid to do.
  established,

  /// Work the owner is teaching himself, said plainly.
  exploring,

  /// The editors and clients he works in. Context, not a qualification.
  aside,
}

class _Group extends StatefulWidget {
  const _Group({
    required this.label,
    required this.values,
    required this.emphasis,
    this.isOpenAtRest = false,
  });

  final String label;
  final List<String> values;
  final _Emphasis emphasis;

  /// Whether this group is already open when the page arrives.
  final bool isOpenAtRest;

  @override
  State<_Group> createState() => _GroupState();
}

class _GroupState extends State<_Group> {
  late bool _isOpen = widget.isOpenAtRest;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isAside = widget.emphasis == _Emphasis.aside;

    return Semantics(
      container: true,
      button: true,
      expanded: _isOpen,
      // The whole group read aloud, open or shut: a reader using a screen
      // reader should not have to open a disclosure to find out what is in it.
      label: '${widget.label}: ${widget.values.join(', ')}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _GroupLabel(
              label: widget.label,
              emphasis: widget.emphasis,
              count: widget.values.length,
              isOpen: _isOpen,
              onTap: () => setState(() => _isOpen = !_isOpen),
            ),
            // Height and opacity together. Height alone slides a fully drawn
            // block up behind the heading, which reads as the page jumping
            // rather than as a group closing.
            AnimatedSize(
              duration: ReducedMotion.duration(context, Motion.standard),
              curve: MotionCurves.emphasized,
              alignment: AlignmentDirectional.topStart,
              child: AnimatedOpacity(
                opacity: _isOpen ? 1 : 0,
                duration: ReducedMotion.duration(context, Motion.quick),
                child: _isOpen
                    ? Padding(
                        padding: EdgeInsets.only(top: tokens.space12),
                        child: isAside
                            ? Text(
                                widget.values.join(', '),
                                style: context.type.meta.copyWith(
                                  color: tokens.textMuted,
                                ),
                              )
                            : Wrap(
                                spacing: tokens.space8,
                                runSpacing: tokens.space8,
                                children: [
                                  for (final value in widget.values)
                                    _Chip(
                                      value: value,
                                      emphasis: widget.emphasis,
                                    ),
                                ],
                              ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The heading, with the short gold rule the rest of the site uses to mark
/// something as the owner's own. It is also the control that opens the group.
class _GroupLabel extends StatefulWidget {
  const _GroupLabel({
    required this.label,
    required this.emphasis,
    required this.count,
    required this.isOpen,
    required this.onTap,
  });

  final String label;
  final _Emphasis emphasis;
  final int count;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  State<_GroupLabel> createState() => _GroupLabelState();
}

class _GroupLabelState extends State<_GroupLabel> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final leading = switch (widget.emphasis) {
      _Emphasis.established => tokens.beacon,
      _Emphasis.exploring => tokens.instrumentDim,
      _Emphasis.aside => tokens.instrumentDim,
    };

    return ListenableBuilder(
      listenable: _states,
      builder: (context, _) {
        final isLit =
            _states.value.contains(WidgetState.hovered) ||
            _states.value.contains(WidgetState.focused);

        return FocusRing(
          isFocused: _states.value.contains(WidgetState.focused),
          child: InkWell(
            onTap: widget.onTap,
            statesController: _states,
            borderRadius: BorderRadius.circular(tokens.controlRadius),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.space4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The rule grows when the group is open: the same mark the
                  // site already uses, carrying the state instead of a
                  // borrowed chevron.
                  AnimatedContainer(
                    duration: ReducedMotion.duration(context, Motion.quick),
                    curve: MotionCurves.emphasized,
                    width: widget.isOpen ? tokens.space32 : tokens.space16,
                    height: tokens.hairlineWidth * 2,
                    color: leading,
                  ),
                  SizedBox(width: tokens.space8),
                  Text(
                    widget.label,
                    style: context.type.telemetryS.copyWith(
                      color: isLit ? tokens.textPrimary : tokens.textMuted,
                    ),
                  ),
                  SizedBox(width: tokens.space8),
                  Text(
                    '${widget.count}',
                    style: context.type.telemetryS.copyWith(
                      color: tokens.instrumentDim,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.value, required this.emphasis});

  final String value;
  final _Emphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final established = emphasis == _Emphasis.established;

    return DecoratedBox(
      decoration: BoxDecoration(
        // Filled where the claim is backed by work, outlined where it is not.
        color: established ? tokens.surfaceRaised : null,
        border: Border.all(
          color: established ? tokens.hairline : tokens.instrumentDim,
          width: tokens.hairlineWidth,
        ),
        borderRadius: BorderRadius.circular(Tokens.controlRadius),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.space12,
          vertical: established ? tokens.space8 : tokens.space4,
        ),
        child: Text(
          value,
          style: established
              ? context.type.body.copyWith(color: tokens.textPrimary)
              : context.type.bodyS.copyWith(color: tokens.textSecondary),
        ),
      ),
    );
  }
}
