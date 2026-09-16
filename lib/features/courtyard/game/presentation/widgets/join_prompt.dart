import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/features/courtyard/game/domain/leaderboard.dart';
import 'package:nocturne/features/courtyard/game/presentation/game_control.dart';

/// The one question this feature asks, asked once.
///
/// Two answers, neither of them a default and neither of them buried. Joining
/// says what becomes public before it happens rather than after; playing on is
/// a button of the same size, not a dismissal in grey text.
///
/// "Once" is the whole design. A modal that reappears every time somebody
/// presses Play is not a consent prompt, it is a toll gate, so the answer is
/// remembered when the visitor says it may be — and when they say it may not,
/// the honest consequence is being asked again, which they chose.
class JoinPrompt extends StatefulWidget {
  /// Creates the prompt.
  const JoinPrompt({required this.onChosen, super.key});

  /// Called with the visitor's answer. The sheet closes itself first.
  final void Function(Participation) onChosen;

  /// Opens it over the climb, returning the answer or null if it was dismissed.
  static Future<Participation?> show(BuildContext context) =>
      showDialog<Participation>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(context.tokens.space16),
          child: JoinPrompt(
            onChosen: (choice) => Navigator.of(context).pop(choice),
          ),
        ),
      );

  @override
  State<JoinPrompt> createState() => _JoinPromptState();
}

class _JoinPromptState extends State<JoinPrompt> {
  final TextEditingController _name = TextEditingController();
  final FocusNode _nameFocus = FocusNode(debugLabel: 'ascent-nickname');
  bool _remember = true;
  bool _showError = false;

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  /// The same rule the Worker applies, so a name is refused here rather than
  /// after a climb has already been played and submitted.
  bool get _isNameUsable {
    final trimmed = _name.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (trimmed.length < 2 || trimmed.length > 16) return false;
    if (RegExp(r':\/\/|www\.', caseSensitive: false).hasMatch(trimmed)) {
      return false;
    }
    return true;
  }

  void _join() {
    if (!_isNameUsable) {
      setState(() => _showError = true);
      _nameFocus.requestFocus();
      return;
    }
    widget.onChosen(
      Joined.fresh(
        nickname: _name.text.replaceAll(RegExp(r'\s+'), ' ').trim(),
        // Joining is itself the choice to be on the board, so a run that
        // qualifies goes up without a second prompt after every climb. Leaving
        // and renaming are one tap away in the results.
        submitsAutomatically: true,
        remembered: _remember,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(
            color: tokens.hairlineStrong,
            width: tokens.hairlineWidth,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(tokens.space24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.ascentJoinTitle,
                  style: type.heading.copyWith(color: tokens.textPrimary),
                ),
                SizedBox(height: tokens.space12),
                Text(
                  l10n.ascentJoinBody,
                  style: type.body.copyWith(color: tokens.textSecondary),
                ),
                SizedBox(height: tokens.space8),
                Text(
                  l10n.ascentBoardBrowser,
                  style: type.telemetryS.copyWith(color: tokens.textMuted),
                ),
                SizedBox(height: tokens.space24),
                TextField(
                  controller: _name,
                  focusNode: _nameFocus,
                  maxLength: 16,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_showError) setState(() => _showError = false);
                  },
                  onSubmitted: (_) => _join(),
                  decoration: InputDecoration(
                    labelText: l10n.ascentJoinName,
                    errorText: _showError ? l10n.ascentJoinNameError : null,
                    counterText: '',
                  ),
                ),
                SizedBox(height: tokens.space8),
                InkWell(
                  onTap: () => setState(() => _remember = !_remember),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: tokens.space4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _remember,
                          onChanged: (value) =>
                              setState(() => _remember = value ?? false),
                        ),
                        Expanded(
                          child: Text(
                            l10n.ascentJoinRemember,
                            style: type.body.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: tokens.space24),
                Wrap(
                  spacing: tokens.space8,
                  runSpacing: tokens.space8,
                  children: [
                    GameControl(
                      label: l10n.ascentJoinGo,
                      isPrimary: true,
                      onPressed: _join,
                    ),
                    GameControl(
                      label: l10n.ascentJoinLocal,
                      onPressed: () => widget.onChosen(
                        PlayingLocally(remembered: _remember),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
