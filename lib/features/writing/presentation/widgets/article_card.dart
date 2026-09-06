import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';
import 'package:nocturne/core/widgets/loading/station_card.dart';
import 'package:nocturne/features/writing/domain/article.dart';

/// One published article, as a visual card that opens Medium.
///
/// The artwork is the same procedural constellation the work grid uses, seeded
/// from the article's own URL — so every article has a distinct mark, drawn in
/// the site's vocabulary, with no image asset to commission or ship.
///
/// Unlike a work card, the whole surface is the link: an article has exactly
/// one destination, so splitting the card into a decorative half and an
/// actionable one would invent a distinction the content does not have.
class ArticleCard extends StatefulWidget {
  /// Renders [article] and links out to it.
  const ArticleCard({required this.article, super.key});

  /// The article this card stands for.
  final Article article;

  /// Declared, never inferred; matches the work grid so the two pages align.
  static const double width = 280;

  /// Taller than a work card: a title is longer than an application name.
  static const double artHeight = 180;

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  /// A stable seed per article: the URL's last meaningful segment.
  ///
  /// Medium slugs end in a hash, so this is distinct per article and stable
  /// across feed refreshes — the same article always draws the same mark.
  String get _seed {
    final segments = widget.article.url.pathSegments.where(
      (segment) => segment.isNotEmpty,
    );
    return segments.isEmpty ? widget.article.url.host : segments.last;
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
        builder: (context, _) => FocusRing(
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
            child: ExcludeSemantics(
              child: SizedBox(
                width: ArticleCard.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StationCard(
                      seedId: _seed,
                      name: widget.article.title,
                      width: ArticleCard.width,
                      height: ArticleCard.artHeight,
                    ),
                    SizedBox(height: tokens.space8),
                    Text(
                      _meta(),
                      style: type.telemetryS.copyWith(color: tokens.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Date and tags on one telemetry line.
  ///
  /// The date is rendered ISO rather than as a localised month name: the type
  /// scale puts tabular figures on every numeric style, an ISO date reads the
  /// same in both text directions, and inventing an Arabic month vocabulary
  /// would be exactly the kind of content `AGENTS.md` §3 forbids.
  String _meta() {
    final published = widget.article.published;
    final date = published == null
        ? null
        : '${published.year.toString().padLeft(4, '0')}-'
              '${published.month.toString().padLeft(2, '0')}-'
              '${published.day.toString().padLeft(2, '0')}';
    final tags = widget.article.tags.take(2).join(' · ');

    return [if (date != null) date, if (tags.isNotEmpty) tags].join('   ');
  }
}
