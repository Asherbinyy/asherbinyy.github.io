import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/widgets/even_grid.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/app_origin.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/content/work_domain_label.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/loading/carrier_empty_state.dart';
import 'package:nocturne/core/widgets/loading/skeleton_text.dart';
import 'package:nocturne/core/widgets/loading/sweep_scope.dart';
import 'package:nocturne/features/work/presentation/widgets/work_card.dart';
import 'package:nocturne/features/writing/presentation/widgets/writing_list.dart';

/// Every shipped application, as a grid of visual cards.
///
/// The screen spec originally specified a ledger and argued against cards, on
/// the grounds that they would be "twelve identical rounded rectangles" and
/// would bury the store links. The owner asked for a visual, interactive
/// treatment, and both halves of that objection are answerable: the artwork is
/// seeded per application so no two cards match, and the store links stay as
/// their own separately focusable controls. The doc records the change.
///
/// This is still the strongest evidence on the site and it should be
/// impossible to miss.
class WorkScreen extends ConsumerWidget {
  /// Reads the application ledger from the content layer.
  const WorkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(appsProvider);
    final career = switch (ref.watch(careerProvider).valueOrNull) {
      ContentReady(:final data) => data,
      _ => const Career(roles: []),
    };

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: context.platform.gutter,
        end: context.platform.gutter,
        top: context.tokens.space48,
        bottom: context.tokens.space64,
      ),
      child: switch (apps) {
        AsyncData(value: ContentReady(:final data)) => _Ledger(
          apps: data.apps,
          career: career,
        ),
        AsyncData() || AsyncError() => const _Unavailable(),
        _ => const _Loading(),
      },
    );
  }
}

class _Ledger extends StatelessWidget {
  const _Ledger({required this.apps, required this.career});

  final List<ShippedApp> apps;
  final Career career;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // A name rather than a count. It read "13 shipped applications",
        // which is a statistic rather than a title, and the same statistic
        // every other page was already carrying.
        Text(l10n.workHeading, style: context.type.displayM),
        SizedBox(height: tokens.space8),
        Text(
          l10n.workSubheading,
          style: context.type.bodyL.copyWith(color: tokens.textSecondary),
        ),
        SizedBox(height: tokens.space32),
        _Grid(apps: apps, career: career),
        // The writing, on the same page. It had a tab of its own, which made
        // the site ask a visitor to decide between "work" and "writing"
        // before they knew what either held. Both are things he has made, so
        // both are here; `/writing` still resolves for anything already
        // linking to it.
        SizedBox(height: tokens.space96),
        Text(l10n.aboutWriting, style: context.type.heading),
        SizedBox(height: tokens.space24),
        const WritingList(),
      ],
    );
  }
}

/// The ledger, in rows that share a height.
///
/// This was a `Wrap`, which aligns a run to its tallest item and leaves every
/// shorter card sitting in a hole. The roles these cards carry run from 35 to
/// 184 characters, so a row of three could differ by six lines and the store
/// links -- the only thing on the card anyone clicks -- landed at a different
/// height on every one.
///
/// Rows are built by hand rather than with a grid widget because the answer is
/// not a fixed column count: the card has a declared width, so the number that
/// fits is whatever the surface allows, and the last row is short rather than
/// stretched.
class _Grid extends StatelessWidget {
  const _Grid({required this.apps, required this.career});

  final List<ShippedApp> apps;
  final Career career;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    // One grid for the whole site. This used to lay its own rows out with a
    // fixed-width card and `MainAxisSize.min`, which put every leftover pixel
    // on the right-hand side -- on a phone that is a 280px card in a 295px
    // column, and the Treasury visibly sat left of centre. Cards now share the
    // width they are given, and a short last row is balanced rather than
    // ragged.
    return EvenGrid(
      minTileWidth: WorkCard.width,
      spacing: tokens.space32,
      runSpacing: tokens.space48,
      children: [
        for (final app in apps)
          WorkCard(
            app: app,
            domainLabel: app.domain.label(l10n),
            origin: AppOrigins.resolve(app: app, career: career),
          ),
      ],
    );
  }
}

/// Skeleton rows matching the ledger's geometry.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => SweepScope(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SkeletonText(lines: 1, style: context.type.displayM),
        SizedBox(height: context.tokens.space32),
        SkeletonText(lines: 8, style: context.type.heading),
      ],
    ),
  );
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) =>
      CarrierEmptyState(direction: context.l10n.heroContentUnavailable);
}
