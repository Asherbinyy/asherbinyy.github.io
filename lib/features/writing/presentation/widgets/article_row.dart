import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';
import 'package:nocturne/features/writing/domain/article.dart';

/// One article: a hairline-separated row that opens Medium in a new context.
///
/// The same ledger language as `/work` rather than a card — these are entries
/// in a list of published work, and cards would imply each one is a
/// destination on this site when every one of them leaves it.
class ArticleRow extends StatefulWidget {
  /// Renders [article] and links out to it.
  const ArticleRow({required this.article, super.key});

  /// The article this row stands for.
  final Article article;

  @override
  State<ArticleRow> createState() => _ArticleRowState();
}

class _ArticleRowState extends State<ArticleRow> {
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
      link: true,
      label: context.l10n.writingOpenArticle(widget.article.title),
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) {
          final isHovered = _states.value.contains(WidgetState.hovered);
          return FocusRing(
            isFocused: _states.value.contains(WidgetState.focused),
            child: InkWell(
              onTap: () => unawaited(
                launchUrl(
                  widget.article.url,
                  mode: LaunchMode.externalApplication,
                ),
              ),
              statesController: _states,
              hoverColor: Colors.transparent,
              mouseCursor: context.platform.isPointer
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: Container(
                constraints: BoxConstraints(
                  minHeight: context.platform.minimumTarget,
                ),
                padding: EdgeInsets.symmetric(vertical: tokens.space16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: tokens.hairline)),
                ),
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.article.title,
                        style: type.heading.copyWith(
                          // Amber marks what the viewer can act on, and the
                          // whole row is actionable. Hover lifts it to the
                          // glow the same way the primary button does.
                          color: isHovered ? tokens.beaconGlow : tokens.beacon,
                        ),
                      ),
                      SizedBox(height: tokens.space8),
                      Text(
                        _meta(context),
                        style: type.telemetryS.copyWith(
                          color: tokens.textMuted,
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

  /// Date and tags on one telemetry line.
  ///
  /// The date is rendered ISO rather than as a localised month name: the type
  /// scale puts tabular figures on every numeric style, an ISO date reads the
  /// same in both text directions, and inventing an Arabic month vocabulary
  /// would be exactly the kind of content `AGENTS.md` §3 forbids.
  String _meta(BuildContext context) {
    final published = widget.article.published;
    final date = published == null
        ? null
        : '${published.year.toString().padLeft(4, '0')}-'
              '${published.month.toString().padLeft(2, '0')}-'
              '${published.day.toString().padLeft(2, '0')}';
    final tags = widget.article.tags.take(3).join(' · ');

    return [if (date != null) date, if (tags.isNotEmpty) tags].join('   ');
  }
}
