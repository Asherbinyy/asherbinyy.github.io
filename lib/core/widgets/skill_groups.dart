import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/motion/settling_size.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';

/// The owner's skills under titles, as Home, About and the brief show them.
///
/// He asked for them this way: "Mobile", in gold, and pressing it opens every
/// skill that belongs under it. So each title is a control -- gold, because
/// that is what a control is here -- and the one that is open is filled. The
/// skills themselves are plain chips as wide as their own words, inside one
/// card as wide as the page, which is the alignment he meant: the card lines
/// up with the sections around it; the chips do not have to line up with each
/// other.
///
/// One group is open at a time, and the first is open on arrival, so the
/// panel never arrives showing nothing. Pressing the open title again closes
/// it -- the owner asked for the titles to toggle. The titles sit in two
/// lines, each as wide as its words, rather than one long run that left a
/// single title on a line of its own. The tools he works in are the last
/// title rather than a separate list.
class SkillGroups extends StatefulWidget {
  /// Draws [profile]'s groups, falling back to its flat skills.
  const SkillGroups({required this.profile, required this.locale, super.key});

  /// Where the skills and tools come from.
  final Profile profile;

  /// Which language the titles are read in.
  final AppLocale locale;

  @override
  State<SkillGroups> createState() => _SkillGroupsState();
}

/// One title and what is under it, resolved for the current language.
typedef _Group = ({String title, List<String> skills});

class _SkillGroupsState extends State<SkillGroups> {
  int? _open = 0;

  List<_Group> _groups(BuildContext context) {
    final profile = widget.profile;
    final l10n = context.l10n;
    final groups = <_Group>[
      for (final group in profile.skillGroups)
        if (group.skills.isNotEmpty)
          (title: group.title.resolve(widget.locale), skills: group.skills),
    ];
    // A profile written before groups existed still has its flat list.
    if (groups.isEmpty && profile.skills.isNotEmpty) {
      groups.add((title: l10n.profileSkills, skills: profile.skills));
    }
    if (profile.tools.isNotEmpty) {
      groups.add((title: l10n.profileTools, skills: profile.tools));
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final groups = _groups(context);
    if (groups.isEmpty) return const SizedBox.shrink();
    final open = _open?.clamp(0, groups.length - 1);
    final total = widget.profile.skillGroups.isNotEmpty
        ? widget.profile.skillGroups.fold<int>(
            0,
            (sum, group) => sum + group.skills.length,
          )
        : widget.profile.skills.length;

    final titles = [
      for (final (index, group) in groups.indexed)
        _Title(
          title: group.title,
          count: group.skills.length,
          isOpen: index == open,
          onTap: () => setState(() => _open = index == open ? null : index),
        ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.controlRadius),
        border: Border.all(color: tokens.hairline, width: tokens.hairlineWidth),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          context.platform.viewport == ViewportClass.compact
              ? tokens.space16
              : tokens.space24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: tokens.space16,
                  height: tokens.hairlineWidth * 2,
                  child: ColoredBox(color: tokens.beacon),
                ),
                SizedBox(width: tokens.space8),
                Flexible(
                  child: Text(
                    context.l10n.profileSkills,
                    style: type.telemetryS.copyWith(color: tokens.textMuted),
                  ),
                ),
                SizedBox(width: tokens.space8),
                Text(
                  '$total',
                  style: type.telemetryS.copyWith(color: tokens.instrumentDim),
                ),
              ],
            ),
            SizedBox(height: tokens.space16),
            // Two even rows: every title the same width, split as evenly as
            // the count allows, so no title is stranded on a line alone.
            // On a phone two even rows become ten stacked ones, so there the
            // titles are one row you swipe along.
            if (context.platform.viewport == ViewportClass.compact)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final (index, title) in titles.indexed) ...[
                      if (index > 0) SizedBox(width: tokens.space8),
                      title,
                    ],
                  ],
                ),
              )
            else
              // Two lines, each title as wide as its own words -- the owner
              // asked for the titles organised in two rows, and not boxed to
              // one fixed width.
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (index, line) in [
                    titles.take((titles.length / 2).ceil()).toList(),
                    titles.skip((titles.length / 2).ceil()).toList(),
                  ].indexed) ...[
                    if (index > 0) SizedBox(height: tokens.space8),
                    Wrap(
                      spacing: tokens.space8,
                      runSpacing: tokens.space8,
                      children: line,
                    ),
                  ],
                ],
              ),
            SettlingSize(
              duration: Motion.standard,
              child: AnimatedSwitcher(
                duration: ReducedMotion.duration(context, Motion.standard),
                switchInCurve: MotionCurves.emphasized,
                switchOutCurve: MotionCurves.exit,
                layoutBuilder: (current, previous) =>
                    Stack(children: [...previous, ?current]),
                child: open == null
                    ? const SizedBox(width: double.infinity)
                    : Column(
                        key: ValueKey(groups[open].title),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: tokens.space16),
                          SizedBox(
                            height: tokens.hairlineWidth,
                            width: double.infinity,
                            child: ColoredBox(color: tokens.hairline),
                          ),
                          SizedBox(height: tokens.space16),
                          _Skills(skills: groups[open].skills),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A title: the control that opens its skills.
class _Title extends StatefulWidget {
  const _Title({
    required this.title,
    required this.count,
    required this.isOpen,
    required this.onTap,
  });

  final String title;
  final int count;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  State<_Title> createState() => _TitleState();
}

class _TitleState extends State<_Title> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    return Semantics(
      button: true,
      selected: widget.isOpen,
      label: context.l10n.skillsGroupLabel(widget.title, widget.count),
      excludeSemantics: true,
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) {
          final isLit =
              _states.value.contains(WidgetState.hovered) ||
              _states.value.contains(WidgetState.focused);
          final ink = widget.isOpen
              ? tokens.void_
              : isLit
              ? tokens.beaconGlow
              : tokens.beacon;
          return FocusRing(
            isFocused: _states.value.contains(WidgetState.focused),
            child: InkWell(
              onTap: widget.onTap,
              statesController: _states,
              borderRadius: BorderRadius.circular(tokens.controlRadius),
              hoverColor: Colors.transparent,
              mouseCursor: context.platform.isPointer
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: AnimatedContainer(
                duration: ReducedMotion.duration(context, Motion.quick),
                curve: MotionCurves.emphasized,
                constraints: BoxConstraints(
                  minHeight: context.platform.minimumTarget,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.space12,
                  vertical: tokens.space8,
                ),
                decoration: BoxDecoration(
                  color: widget.isOpen ? tokens.beacon : Colors.transparent,
                  borderRadius: BorderRadius.circular(tokens.controlRadius),
                  border: Border.all(
                    color: widget.isOpen || isLit
                        ? tokens.beacon
                        : tokens.beaconDim,
                    width: tokens.hairlineWidth,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.title,
                        style: type.bodyS.copyWith(color: ink),
                      ),
                    ),
                    SizedBox(width: tokens.space8),
                    Text(
                      '${widget.count}',
                      style: type.telemetryS.copyWith(
                        color: widget.isOpen
                            ? tokens.void_.withValues(
                                alpha: Tokens.skillsCountAlpha,
                              )
                            : tokens.instrumentDim,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The skills under the open title, arriving one after another.
class _Skills extends StatefulWidget {
  const _Skills({required this.skills});

  final List<String> skills;

  @override
  State<_Skills> createState() => _SkillsState();
}

class _SkillsState extends State<_Skills> with SingleTickerProviderStateMixin {
  late final AnimationController _arrive = AnimationController(
    vsync: this,
    duration: Tokens.skillsArrive,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ReducedMotion.of(context)) {
      _arrive.value = 1;
    } else if (!_arrive.isAnimating && _arrive.value == 0) {
      _arrive.forward();
    }
  }

  @override
  void dispose() {
    _arrive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final count = widget.skills.length;
    return Wrap(
      spacing: tokens.space8,
      runSpacing: tokens.space8,
      children: [
        for (final (index, skill) in widget.skills.indexed)
          _Staggered(
            animation: _arrive,
            // Each chip's share of the arrival starts a little after the one
            // before it, so the row reads as filling in rather than blinking.
            interval: Interval(
              (index / (count + Tokens.skillsStaggerTail)).clamp(0.0, 1.0),
              ((index + Tokens.skillsStaggerTail) /
                      (count + Tokens.skillsStaggerTail))
                  .clamp(0.0, 1.0),
              curve: MotionCurves.emphasized,
            ),
            child: _Chip(label: skill),
          ),
      ],
    );
  }
}

/// A chip that rises into place on its share of [animation].
class _Staggered extends StatelessWidget {
  const _Staggered({
    required this.animation,
    required this.interval,
    required this.child,
  });

  final Animation<double> animation;
  final Interval interval;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final t = interval.transform(animation.value);
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * Tokens.skillsRise),
          child: child,
        ),
      );
    },
    child: child,
  );
}

/// One skill, as wide as its name.
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
