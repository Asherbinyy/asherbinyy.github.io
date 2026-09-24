import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/generated/app_localizations.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/widgets/even_grid.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/app_maker.dart';
import 'package:nocturne/content/app_origin.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/content/work_domain_label.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';
import 'package:nocturne/core/widgets/loading/carrier_empty_state.dart';
import 'package:nocturne/core/widgets/loading/skeleton_text.dart';
import 'package:nocturne/core/widgets/loading/sweep_scope.dart';
import 'package:nocturne/core/widgets/reveal_on_scroll.dart';
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

  /// The key on one filter control, named for the view it selects.
  ///
  /// Two of the three share a word with a heading further down the page --
  /// "Writing" is both a filter and a section -- so anything looking for a
  /// control by its text finds two candidates and picks the wrong one.
  static Key filterKey(String option) => ValueKey('work-filter-$option');

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

/// What the page is currently showing.
enum _Shown {
  /// Applications and writing, in that order.
  everything,

  /// The applications only.
  apps,

  /// The writing only.
  writing;

  String label(AppLocalizations l10n) => switch (this) {
    _Shown.everything => l10n.workFilterAll,
    _Shown.apps => l10n.workFilterApps,
    _Shown.writing => l10n.workFilterWriting,
  };
}

class _Ledger extends StatefulWidget {
  const _Ledger({required this.apps, required this.career});

  final List<ShippedApp> apps;
  final Career career;

  @override
  State<_Ledger> createState() => _LedgerState();
}

class _LedgerState extends State<_Ledger> {
  _Shown _shown = _Shown.everything;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final showsApps = _shown != _Shown.writing;
    final showsWriting = _shown != _Shown.apps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // A name rather than a count. It read "13 shipped applications",
        // which is a statistic rather than a title, and the same statistic
        // every other page was already carrying. The standfirst underneath
        // had gone the same way -- "Fourteen apps, shipped and running" is
        // the count again, one line lower -- so it says what the page holds
        // instead of how much of it there is.
        Text(l10n.workHeading, style: context.type.displayM),
        SizedBox(height: tokens.space8),
        Text(
          l10n.workSubheading,
          style: context.type.bodyL.copyWith(color: tokens.textSecondary),
        ),
        SizedBox(height: tokens.space32),
        _FilterBar(
          shown: _shown,
          onChanged: (value) => setState(() => _shown = value),
        ),
        if (showsApps) ...[
          SizedBox(height: tokens.space32),
          _SectionHeading(text: l10n.workApps),
          SizedBox(height: tokens.space24),
          _Grid(apps: widget.apps, career: widget.career),
        ],
        // The writing, on the same page. It had a tab of its own, which made
        // the site ask a visitor to decide between "work" and "writing"
        // before they knew what either held. Both are things he has made, so
        // both are here; `/writing` still resolves for anything already
        // linking to it.
        if (showsWriting) ...[
          SizedBox(
            height: showsApps ? context.platform.sectionGap : tokens.space32,
          ),
          _SectionHeading(text: l10n.aboutWriting),
          SizedBox(height: tokens.space24),
          const WritingList(),
        ],
      ],
    );
  }
}

/// A section's name, with the site's own rule beside it.
///
/// The applications had no heading at all -- they simply began under the
/// standfirst -- while the writing below them did, so the page read as one
/// titled section preceded by some loose cards.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: tokens.space24,
          height: tokens.hairlineWidth * 2,
          child: ColoredBox(color: tokens.beacon),
        ),
        SizedBox(width: tokens.space12),
        Text(text, style: context.type.heading),
      ],
    );
  }
}

/// Show everything, the applications, or the writing.
///
/// A segmented row rather than a dropdown: there are three options, they are
/// short, and a select on a page like this is a control borrowed from a form.
/// It sits to the trailing edge, where the owner asked for it, and wraps under
/// itself on a phone rather than scrolling off.
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.shown, required this.onChanged});

  final _Shown shown;
  final ValueChanged<_Shown> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Wrap(
        spacing: tokens.space8,
        runSpacing: tokens.space8,
        children: [
          for (final option in _Shown.values)
            _FilterChip(
              // Keyed because two of these share a word with a heading further
              // down the page -- "Writing" is both a filter and a section --
              // so finding one by its text is ambiguous for a test and for
              // anything else that goes looking.
              key: WorkScreen.filterKey(option.name),
              label: option.label(context.l10n),
              isSelected: option == shown,
              onPressed: () => onChanged(option),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.label,
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) {
          final isLit =
              widget.isSelected ||
              _states.value.contains(WidgetState.hovered) ||
              _states.value.contains(WidgetState.focused);
          return FocusRing(
            isFocused: _states.value.contains(WidgetState.focused),
            child: InkWell(
              onTap: widget.onPressed,
              statesController: _states,
              borderRadius: BorderRadius.circular(tokens.controlRadius),
              hoverColor: Colors.transparent,
              mouseCursor: context.platform.isPointer
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: AnimatedContainer(
                duration: ReducedMotion.duration(context, Motion.quick),
                constraints: BoxConstraints(
                  minHeight: context.platform.minimumTarget,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.space16,
                  vertical: tokens.space8,
                ),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? tokens.beacon.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(tokens.controlRadius),
                  border: Border.all(
                    color: isLit ? tokens.beacon : tokens.hairline,
                    width: tokens.hairlineWidth,
                  ),
                ),
                // `Align` with a width factor, not `alignment:` on the
                // container. A Container given an alignment expands to fill
                // whatever it is offered, which turned three chips in a Wrap
                // into three full-width bars stacked down the page. This
                // centres the word vertically inside the tap target while the
                // chip stays exactly as wide as its own label.
                child: Align(
                  widthFactor: 1,
                  child: ExcludeSemantics(
                    child: Text(
                      widget.label,
                      style: context.type.telemetryS.copyWith(
                        color: isLit ? tokens.beacon : tokens.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
      stretch: true,
      // In order: each row full before the next begins.
      balance: false,
      runSpacing: tokens.space48,
      children: [
        for (final (index, app) in apps.indexed)
          // Each card rises in as the reader reaches it, a beat after the one
          // before it along the row.
          RevealOnScroll(
            style: RevealStyle.rise,
            delay: Tokens.workStagger * (index % 3),
            child: WorkCard(
              app: app,
              domainLabel: app.domain.label(l10n),
              origin: AppOrigins.resolve(app: app, career: career),
              maker: AppMakers.resolve(app: app, career: career),
            ),
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
