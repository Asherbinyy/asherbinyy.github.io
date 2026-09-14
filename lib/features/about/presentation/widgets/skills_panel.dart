import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/profile.dart';

/// The supplied toolkit, grouped without implying proficiency percentages.
class SkillsPanel extends StatelessWidget {
  /// Established skills stay separate from topics the owner is learning.
  const SkillsPanel({required this.profile, super.key});

  /// Shared profile content; no separate About inventory.
  final Profile profile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (profile.skills.isNotEmpty)
        _Group(label: context.l10n.profileSkills, values: profile.skills),
      if (profile.learning.isNotEmpty)
        _Group(label: context.l10n.profileLearning, values: profile.learning),
      if (profile.tools.isNotEmpty)
        _Group(label: context.l10n.profileTools, values: profile.tools),
    ],
  );
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.values});
  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.type.telemetryS.copyWith(color: tokens.textMuted),
          ),
          SizedBox(height: tokens.space8),
          Wrap(
            spacing: tokens.space8,
            runSpacing: tokens.space8,
            children: [
              for (final value in values)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.surfaceRaised,
                    border: Border.all(
                      color: tokens.hairline,
                      width: tokens.hairlineWidth,
                    ),
                    borderRadius: BorderRadius.circular(Tokens.cardRadius),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.space12,
                      vertical: tokens.space8,
                    ),
                    child: Text(
                      value,
                      style: context.type.bodyS.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
