import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/education.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';

/// Education as a compact table: institution, award, dates, status.
///
/// Modules are listed with marks, highest first, so the strongest result reads
/// first — the screen spec is explicit that `Business Data Insights &
/// Analytics — 94` should be the line a skimming reader lands on.
///
/// Only modules at or above [publishableMark] are shown. See that constant for
/// why the filter lives here rather than in the content.
class EducationTable extends StatelessWidget {
  /// Renders every supplied entry in content order.
  const EducationTable({required this.education, super.key});

  /// The mark at or above which a module is published.
  ///
  /// The owner asked on 2026-09-07 for the table to carry his strongest
  /// results rather than a full transcript, and chose 80 as the line. It is a
  /// defensible one: 70 is the distinction threshold, so 80 and above is
  /// comfortably clear of it, and it is not a number reverse-engineered to
  /// flatter a particular set.
  ///
  /// **The filter is presentation, not content.** `education.json` keeps every
  /// mark the owner supplied, because that file is the record and trimming it
  /// would destroy data to achieve a layout. The static `/cv` route renders
  /// from the same content and is free to publish the full transcript, which
  /// is the right split: an ATS reads everything, a skimming human reads the
  /// best four.
  static const double publishableMark = 80;

  /// Identifies the transcript list, as distinct from the evidence row.
  static const Key modulesKey = ValueKey('education-modules');

  /// Qualifications as the owner recorded them.
  final Education education;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [for (final entry in education.entries) _Entry(entry: entry)],
  );
}

class _Entry extends StatelessWidget {
  const _Entry({required this.entry});

  final EducationEntry entry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;

    // Highest first, on a copy — sorting the model's list in place would
    // mutate content the repository caches and hands to every other reader.
    final modules =
        entry.modules
            .where((module) => module.mark >= EducationTable.publishableMark)
            .toList()
          ..sort((a, b) => b.mark.compareTo(a.mark));

    // Only the published modules can contribute an artefact: showing evidence
    // for a mark the page is not printing would raise the obvious question.
    final artefacts = modules
        .where((module) => module.evidence != null)
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.award.resolve(context.channel),
            style: type.body.copyWith(color: tokens.textPrimary),
          ),
          SizedBox(height: tokens.space4),
          Text(
            '${entry.institution.resolve(context.channel)}   '
            '${entry.start} — ${entry.end}',
            style: type.telemetryS.copyWith(color: tokens.textMuted),
          ),
          if (entry.status case final status?) ...[
            SizedBox(height: tokens.space8),
            Text(
              status.resolve(context.channel),
              style: type.telemetryS.copyWith(color: tokens.beacon),
            ),
          ],
          if (modules.isNotEmpty) ...[
            SizedBox(height: tokens.space16),
            // Keyed so a test can tell the transcript apart from the evidence
            // row beneath it. Both print marks -- deliberately, since a card
            // gathered away from the transcript has to say what it is evidence
            // for -- and without this the two are indistinguishable to a
            // finder searching the whole table for "94".
            Column(
              key: EducationTable.modulesKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [for (final module in modules) _Module(module: module)],
            ),
          ],
          // The artefacts sit together, side by side, rather than one under
          // whichever module it belongs to. Stacked under their rows they
          // pushed the marks apart and read as a column of unrelated pictures;
          // gathered here they read as what they are -- the evidence behind
          // the transcript above them -- and two of them fit one desktop row.
          if (artefacts.isNotEmpty) ...[
            SizedBox(height: tokens.space24),
            Wrap(
              spacing: tokens.space16,
              runSpacing: tokens.space16,
              children: [
                for (final module in artefacts)
                  _EvidenceCard(
                    evidence: module.evidence!,
                    module: module.name.resolve(context.channel),
                    mark: module.mark,
                  ),
              ],
            ),
          ],
          if (entry.highlights.isNotEmpty) ...[
            SizedBox(height: tokens.space24),
            Wrap(
              spacing: tokens.space16,
              runSpacing: tokens.space16,
              children: [
                for (final highlight in entry.highlights)
                  _HighlightCard(text: highlight.resolve(context.channel)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One module and its mark, on a hairline row with the mark right-aligned.
class _Module extends StatelessWidget {
  const _Module({required this.module});

  final EducationModule module;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  module.name.resolve(context.channel),
                  style: type.bodyS.copyWith(color: tokens.textSecondary),
                ),
              ),
              SizedBox(width: tokens.space16),
              Text(
                // Marks are whole numbers in the supplied content; the type
                // scale puts tabular figures on numeric styles so the column
                // aligns.
                module.mark.toStringAsFixed(0),
                style: type.telemetry.copyWith(color: tokens.instrument),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The artefact behind a mark, as a card that opens full size.
///
/// A mark is a number a reader has to take on trust; the coursework behind it
/// is what turns it into evidence. This is `14-PROVENANCE.md`'s argument
/// applied to the transcript — and the reason only two modules carry one is
/// that only two artefacts were supplied, not that the rest were filtered.
///
/// It carries its module and mark, because gathered into a row away from the
/// transcript it would otherwise be a picture with no stated relationship to
/// anything above it.
class _EvidenceCard extends StatefulWidget {
  const _EvidenceCard({
    required this.evidence,
    required this.module,
    required this.mark,
  });

  final Evidence evidence;
  final String module;
  final double mark;

  /// Declared, never inferred. Two fit a desktop row beside each other.
  static const double width = 260;

  /// A 16:10 plate. Tall enough to tell a dashboard from a poster, small
  /// enough that a transcript does not become a gallery.
  static const double height = 162;

  @override
  State<_EvidenceCard> createState() => _EvidenceCardState();
}

class _EvidenceCardState extends State<_EvidenceCard> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  void _open() {
    final caption = widget.evidence.caption.resolve(context.channel);
    unawaited(
      showDialog<void>(
        context: context,
        // The artefact is the point, so it gets the viewport rather than a
        // polite little box in the middle of it.
        builder: (context) =>
            _EvidenceDialog(src: widget.evidence.src, caption: caption),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final caption = widget.evidence.caption.resolve(context.channel);

    return ListenableBuilder(
      listenable: _states,
      builder: (context, _) => Semantics(
        button: true,
        label: context.l10n.aboutEvidenceOpen(caption),
        child: FocusRing(
          isFocused: _states.value.contains(WidgetState.focused),
          child: InkWell(
            onTap: _open,
            statesController: _states,
            hoverColor: Colors.transparent,
            mouseCursor: context.platform.isPointer
                ? SystemMouseCursors.click
                : MouseCursor.defer,
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _states.value.contains(WidgetState.hovered)
                            ? tokens.beacon
                            : tokens.hairline,
                        width: tokens.hairlineWidth,
                      ),
                    ),
                    child: Image.asset(
                      widget.evidence.src,
                      width: _EvidenceCard.width,
                      height: _EvidenceCard.height,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      // A missing artefact leaves the mark standing alone
                      // rather than a broken-image glyph beside it.
                      errorBuilder: (context, error, stack) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                  SizedBox(height: tokens.space8),
                  SizedBox(
                    width: _EvidenceCard.width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // The module and its mark, so a card gathered away
                        // from the transcript still says what it is evidence
                        // for. The mark leads in gold: it is the claim, and
                        // the picture beneath it is the proof.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              widget.mark.toStringAsFixed(0),
                              style: context.type.telemetry.copyWith(
                                color: tokens.beacon,
                              ),
                            ),
                            SizedBox(width: tokens.space8),
                            Expanded(
                              child: Text(
                                widget.module,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.type.bodyS.copyWith(
                                  color: tokens.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: tokens.space4),
                        Text(
                          caption,
                          style: context.type.telemetryS.copyWith(
                            color: tokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The artefact at full size, over a dimmed page.
class _EvidenceDialog extends StatelessWidget {
  const _EvidenceDialog({required this.src, required this.caption});

  final String src;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Dialog(
      backgroundColor: tokens.surface,
      insetPadding: EdgeInsets.all(tokens.space24),
      child: Padding(
        padding: EdgeInsets.all(tokens.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              // A poster is taller than any viewport, so it scrolls rather
              // than shrinking to illegibility.
              child: SingleChildScrollView(
                child: Image.asset(src, fit: BoxFit.contain),
              ),
            ),
            SizedBox(height: tokens.space12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    caption,
                    style: context.type.bodyS.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
                SizedBox(width: tokens.space16),
                BeaconButton(
                  label: context.l10n.aboutEvidenceClose,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One thing the owner did that a transcript cannot show.
///
/// The dissertation and the strategy simulation were plain paragraphs stacked
/// under the marks, which is where the owner said the page stopped being worth
/// looking at. They are the two most interesting facts in this section and
/// they were the least visible things in it.
///
/// A card, not a link: neither has anywhere to go yet. The dissertation is
/// unpublished by the owner's instruction, and inventing a destination for a
/// panel that looks clickable would be worse than a panel that plainly is not.
class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.text});

  final String text;

  /// Declared, never inferred. Matches the evidence row so the two align.
  static const double width = 260;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return InstrumentPanel(
      fill: tokens.surface,
      padding: EdgeInsets.all(tokens.space16),
      child: SizedBox(
        width: _HighlightCard.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // The same short gold rule the hero and the transmission panel
            // use, so a card here reads as part of the site rather than as a
            // component borrowed from somewhere else.
            SizedBox(
              width: tokens.space32,
              height: tokens.hairlineWidth * 2,
              child: ColoredBox(color: tokens.beacon),
            ),
            SizedBox(height: tokens.space12),
            Text(
              text,
              style: context.type.bodyS.copyWith(color: tokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
