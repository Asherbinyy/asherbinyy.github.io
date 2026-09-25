import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nocturne/core/analytics/tracked_link.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';
import 'package:nocturne/core/widgets/loading/station_card.dart';
import 'package:nocturne/core/widgets/loading/three_stage_image.dart';
import 'package:nocturne/features/writing/data/writing_providers.dart';
import 'package:nocturne/features/writing/domain/article.dart';

/// One published article, as a visual card that opens Medium.
///
/// The artwork is the article's own cover, relayed through this origin so the
/// browser never asks Medium for it. Where the feed carries no cover, or the
/// image cannot be fetched, it falls back to the procedural constellation the
/// work grid uses, seeded from the article's own URL — so every article has a
/// distinct mark either way and the layout never shifts between the two.
///
/// Unlike a work card, the whole surface is the link: an article has exactly
/// one destination, so splitting the card into a decorative half and an
/// actionable one would invent a distinction the content does not have.
class ArticleCard extends ConsumerStatefulWidget {
  /// Renders [article] and links out to it.
  const ArticleCard({required this.article, super.key});

  /// The article this card stands for.
  final Article article;

  /// The narrowest a card may be, and the width its artwork is proportioned
  /// against. The card itself fills its grid tile: the article grid stretches
  /// to the full width of the page so its edges line up with every other
  /// section, where a row of fixed 280px cards stopped short of them.
  static const double width = 280;

  /// The artwork's height at [width]; it scales with the card, so a wider
  /// card gets a bigger cover rather than a more tightly cropped one.
  static const double artHeight = 180;

  @override
  ConsumerState<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends ConsumerState<ArticleCard> {
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
              launchTrackedUrl(
                context,
                widget.article.url,
                target: 'article:${widget.article.url.host}',
              ),
            ),
            statesController: _states,
            hoverColor: Colors.transparent,
            mouseCursor: context.platform.isPointer
                ? SystemMouseCursors.click
                : MouseCursor.defer,
            child: ExcludeSemantics(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rounded and clipped. A cover photograph with square
                    // corners reads as a screenshot dropped on the page; the
                    // radius is what makes it a card.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Tokens.cardRadius),
                      child: _Art(article: widget.article, seed: _seed),
                    ),
                    SizedBox(height: tokens.space12),
                    // The title. It was never drawn: the card showed a cover,
                    // a date and two tags, and the headline existed only in
                    // the screen-reader label. This class's own comment says
                    // it is taller than a work card because "a title is longer
                    // than an application name", so the space was reserved for
                    // a thing that was never put in it.
                    Text(
                      widget.article.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: type.heading.copyWith(color: tokens.textPrimary),
                    ),
                    SizedBox(height: tokens.space8),
                    Text(
                      _meta(),
                      style: type.telemetryS.copyWith(color: tokens.textMuted),
                    ),
                    SizedBox(height: tokens.space8),
                    // Says where it goes. A card that is entirely a link
                    // should admit it, and the arrow is the only part that
                    // moves on hover.
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.writingReadOn,
                          style: type.telemetryS.copyWith(color: tokens.beacon),
                        ),
                        SizedBox(width: tokens.space4),
                        Icon(
                          Icons.arrow_outward,
                          size: type.telemetryS.fontSize,
                          color: tokens.beacon,
                        ),
                      ],
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

  /// The cover where one resolves, the procedural mark where it does not.
  ///
  /// Both render at exactly [ArticleCard.artHeight], so which one appears is
  /// invisible to the layout and a slow image never moves the row beneath it.

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

/// The card's artwork: the relayed cover, or the procedural mark.
class _Art extends ConsumerWidget {
  const _Art({required this.article, required this.seed});

  final Article article;
  final String seed;

  // The tile's width, and the cover's proportions held at that width. An
  // AspectRatio rather than a LayoutBuilder: the grid asks every tile for its
  // intrinsic height to square its rows, and a LayoutBuilder cannot answer.
  @override
  Widget build(BuildContext context, WidgetRef ref) => AspectRatio(
    aspectRatio: ArticleCard.width / ArticleCard.artHeight,
    child: _filled(ref),
  );

  /// The artwork at whatever size the ratio above grants.
  Widget _filled(WidgetRef ref) {
    const width = double.infinity;
    const height = double.infinity;
    final mark = StationCard(
      seedId: seed,
      // Deliberately unlabelled. The card prints the title below the artwork
      // now, and the mark drawing it too was how the headline came to appear
      // twice on any article whose cover did not resolve.
      name: '',
      width: width,
      height: height,
    );

    final proxied = ref.watch(coverProxyProvider)(article.cover);
    final bundled = ref
        .watch(bundledWritingCoversProvider)
        .valueOrNull?[articleCoverKey(article.url)];
    if (bundled != null) {
      return ThreeStageImage(
        image: AssetImage(bundled),
        width: width,
        height: height,
        fallback: mark,
      );
    }
    if (proxied == null) return mark;

    return ThreeStageImage(
      image: NetworkImage(proxied.toString()),
      width: width,
      height: height,
      fallback: mark,
      semanticLabel: article.title,
    );
  }
}
