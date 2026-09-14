import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/profile.dart';

/// Supplied skills as plain content, using the existing typography.
class ProfileSkills extends StatelessWidget {
  /// Separates established skills, learning and tools without a new surface.
  const ProfileSkills({required this.profile, super.key});

  /// Shared owner-supplied content.
  final Profile profile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (profile.skills.isNotEmpty)
        _Line(label: context.l10n.profileSkills, values: profile.skills),
      if (profile.learning.isNotEmpty)
        _Line(label: context.l10n.profileLearning, values: profile.learning),
      if (profile.tools.isNotEmpty)
        _Line(label: context.l10n.profileTools, values: profile.tools),
    ],
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.values});
  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Tokens.space12),
    child: Text(
      '$label: ${values.join(', ')}',
      style: context.type.body.copyWith(color: context.tokens.textSecondary),
    ),
  );
}
