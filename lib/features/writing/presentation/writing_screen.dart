import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/features/writing/data/writing_providers.dart';
import 'package:nocturne/features/writing/presentation/widgets/writing_list.dart';

/// `/writing` — what has been published, linking out to Medium.
///
/// The brief keeps writing on Medium rather than building a blog engine, so
/// this page is an index, not a reader.
class WritingScreen extends ConsumerWidget {
  /// Reads the relayed feed.
  const WritingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final hasArticles = switch (ref.watch(articlesProvider)) {
      AsyncData(:final value) => value.isNotEmpty,
      _ => true,
    };

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: context.platform.gutter,
        end: context.platform.gutter,
        top: tokens.space48,
        bottom: tokens.space64,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.writingHeading, style: context.type.displayM),
          SizedBox(height: tokens.space8),
          Text(
            // The subheading names where the writing lives, because every row
            // leaves the site and a viewer should know that before clicking.
            hasArticles ? l10n.writingSubheading : l10n.writingUnavailable,
            style: context.type.bodyL.copyWith(color: tokens.textSecondary),
          ),
          SizedBox(height: tokens.space32),
          const WritingList(),
        ],
      ),
    );
  }
}
