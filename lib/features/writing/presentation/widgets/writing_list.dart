import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/widgets/loading/skeleton_text.dart';
import 'package:nocturne/core/widgets/loading/sweep_scope.dart';
import 'package:nocturne/features/writing/data/writing_providers.dart';
import 'package:nocturne/features/writing/presentation/widgets/article_row.dart';

/// The article list, shared by `/writing` and the foot of `/about`.
///
/// `03-ARCHITECTURE.md` §5: a feed failure hides the section silently rather
/// than showing an error, because writing is not core content. So there is no
/// error state here at all — an empty result and a failed fetch both render
/// nothing, and the repository is what collapses the two.
class WritingList extends ConsumerWidget {
  /// Renders at most [limit] articles, or all of them when null.
  const WritingList({this.limit, super.key});

  /// Cap used by `/about`, which shows a few rather than the whole archive.
  final int? limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(articlesProvider);

    return switch (articles) {
      AsyncData(:final value) when value.isNotEmpty => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final article in value.take(limit ?? value.length))
            ArticleRow(article: article),
        ],
      ),
      // Both an empty feed and a failed one land here. Nothing is rendered,
      // not even a heading, so the section does not exist rather than being
      // present and apologetic.
      AsyncData() || AsyncError() => const SizedBox.shrink(),
      _ => const _Loading(),
    };
  }
}

/// Skeleton rows on the article row's geometry, so nothing shifts on arrival.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => SweepScope(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SkeletonText(lines: 3, style: context.type.heading),
        SizedBox(height: context.tokens.space16),
      ],
    ),
  );
}
