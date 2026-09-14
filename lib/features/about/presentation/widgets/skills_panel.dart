import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/profile.dart';

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
          _Tools(label: context.l10n.profileTools, values: profile.tools),
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
}

class _Group extends StatelessWidget {
  const _Group({
    required this.label,
    required this.values,
    required this.emphasis,
  });

  final String label;
  final List<String> values;
  final _Emphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      container: true,
      label: '$label: ${values.join(', ')}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _GroupLabel(label: label, emphasis: emphasis),
            SizedBox(height: tokens.space12),
            Wrap(
              spacing: tokens.space8,
              runSpacing: tokens.space8,
              children: [
                for (final value in values)
                  _Chip(value: value, emphasis: emphasis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The heading, with the short gold rule the rest of the site uses to mark
/// something as the owner's own.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.label, required this.emphasis});

  final String label;
  final _Emphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final leading = switch (emphasis) {
      _Emphasis.established => tokens.beacon,
      _Emphasis.exploring => tokens.instrumentDim,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: tokens.space16,
          height: tokens.hairlineWidth * 2,
          child: ColoredBox(color: leading),
        ),
        SizedBox(width: tokens.space8),
        Text(
          label,
          style: context.type.telemetryS.copyWith(color: tokens.textMuted),
        ),
      ],
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

/// One line. The editors somebody works in are worth saying and not worth a
/// row of boxes.
class _Tools extends StatelessWidget {
  const _Tools({required this.label, required this.values});

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Text(
      '$label: ${values.join(', ')}',
      style: context.type.meta.copyWith(color: tokens.textMuted),
    );
  }
}
