import 'package:nocturne/content/content_media.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';

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

  /// How wide a transcript row is allowed to get.
  ///
  /// A mark belongs beside the module it grades. Left to fill the page, the
  /// two ends of the row stop being read as one line.
  static const double transcriptWidth = 720;

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

class _Entry extends StatefulWidget {
  const _Entry({required this.entry});

  final EducationEntry entry;

  @override
  State<_Entry> createState() => _EntryState();
}

class _EntryState extends State<_Entry> {
  /// Closed on arrival.
  ///
  /// Both entries opened themselves, so the page began with two transcripts
  /// and a run of coursework before the reader had asked for any of it. The
  /// control says "Show coursework & highlights"; it should be telling the
  /// truth when the page loads.
  bool _expanded = false;
  final _states = WidgetStatesController();
  EducationEntry get entry => widget.entry;

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

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

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(Tokens.cardRadius),
          border: Border.all(
            color: tokens.hairline,
            width: tokens.hairlineWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ListenableBuilder(
              listenable: _states,
              builder: (context, _) => FocusRing(
                isFocused: _states.value.contains(WidgetState.focused),
                child: Semantics(
                  button: true,
                  expanded: _expanded,
                  child: InkWell(
                    statesController: _states,
                    borderRadius: BorderRadius.circular(Tokens.cardRadius),
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: EdgeInsets.all(tokens.space24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            color: tokens.textSecondary,
                            size: tokens.space24,
                          ),
                          SizedBox(width: tokens.space16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.institution.resolve(context.channel),
                                  style: type.telemetryS.copyWith(
                                    color: tokens.textMuted,
                                  ),
                                ),
                                SizedBox(height: tokens.space8),
                                Text(
                                  entry.award.resolve(context.channel),
                                  style: type.heading.copyWith(
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                SizedBox(height: tokens.space12),
                                Wrap(
                                  spacing: tokens.space16,
                                  runSpacing: tokens.space8,
                                  children: [
                                    Text(
                                      '${entry.start} — ${entry.end}',
                                      style: type.telemetryS.copyWith(
                                        color: tokens.textMuted,
                                      ),
                                    ),
                                    if (entry.status case final status?)
                                      Text(
                                        status.resolve(context.channel),
                                        style: type.telemetryS.copyWith(
                                          color: tokens.textPrimary,
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: tokens.space12),
                                Text(
                                  _expanded
                                      ? context.l10n.educationHideDetails
                                      : context.l10n.educationShowDetails,
                                  style: type.telemetryS.copyWith(
                                    color: tokens.beacon,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: tokens.space8),
                          AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: ReducedMotion.duration(
                              context,
                              Tokens.quick,
                            ),
                            child: Icon(
                              Icons.expand_more,
                              color: tokens.beacon,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _DetailsReveal(
              child: _expanded
                  ? Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: tokens.space24,
                        end: tokens.space24,
                        bottom: tokens.space24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (modules.isNotEmpty) ...[
                            SizedBox(height: tokens.space24),
                            _SectionLabel(text: context.l10n.educationModules),
                            SizedBox(height: tokens.space4),
                            Text(
                              context.l10n.educationSampleHint,
                              style: context.type.meta.copyWith(
                                color: tokens.textMuted,
                              ),
                            ),
                            SizedBox(height: tokens.space16),
                            // Every module once. The coursework sits in the
                            // row it belongs to rather than in a second list
                            // underneath repeating the same names and marks.
                            //
                            // Held to a readable measure: across a 1440px
                            // page the mark ended up half a metre from the
                            // module it belonged to, which is a table you have
                            // to track with a finger.
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: EducationTable.transcriptWidth,
                              ),
                              child: Column(
                                key: EducationTable.modulesKey,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (final module in modules)
                                    _Module(module: module),
                                ],
                              ),
                            ),
                          ],
                          if (entry.highlights.isNotEmpty) ...[
                            SizedBox(height: tokens.space32),
                            _SectionLabel(text: context.l10n.educationProjects),
                            SizedBox(height: tokens.space16),
                            Wrap(
                              spacing: tokens.space16,
                              runSpacing: tokens.space16,
                              children: [
                                for (final highlight in entry.highlights)
                                  _HighlightCard(
                                    text: highlight.resolve(context.channel),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsReveal extends StatelessWidget {
  const _DetailsReveal({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ReducedMotion.of(context)
      ? child
      : AnimatedSize(
          duration: Tokens.considered,
          alignment: AlignmentDirectional.topStart,
          curve: Curves.easeOutCubic,
          child: child,
        );
}

/// One module and its mark, on a hairline row with the mark right-aligned.
/// The heading above a run of modules or projects.
///
/// The section had neither, so a reader met a column of numbers and a pair of
/// unlabelled cards and had to work out what either was. The owner asked for
/// the two to be named.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: tokens.space16,
          height: tokens.hairlineWidth * 2,
          child: ColoredBox(color: tokens.beacon),
        ),
        SizedBox(width: tokens.space8),
        Text(
          text,
          style: context.type.telemetryS.copyWith(color: tokens.textMuted),
        ),
      ],
    );
  }
}

/// One module: its coursework, its name, its mark.
///
/// The artefacts used to be gathered into a second row below the transcript,
/// which listed every one of them a second time — the same name, the same
/// mark, in a different shape. The owner's note was that he did not need to be
/// told twice. So the sample lives in the row it belongs to, and a module
/// without one keeps its place in the column rather than being quietly
/// promoted or dropped.
class _Module extends StatelessWidget {
  const _Module({required this.module});

  final EducationModule module;

  /// Small enough to read as a mark in a transcript rather than a gallery.
  static const double thumbnail = 56;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final evidence = module.evidence;
    final name = module.name.resolve(context.channel);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.space8),
      child: Row(
        children: [
          SizedBox(
            width: _Module.thumbnail,
            height: _Module.thumbnail,
            child: evidence == null
                ? _NoSample(module: name)
                : _SampleThumbnail(
                    evidence: evidence,
                    module: name,
                    mark: module.mark,
                  ),
          ),
          SizedBox(width: tokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: type.body.copyWith(color: tokens.textPrimary),
                ),
                if (evidence != null) ...[
                  SizedBox(height: tokens.space4),
                  Text(
                    evidence.caption.resolve(context.channel),
                    style: type.meta.copyWith(color: tokens.textMuted),
                  ),
                ],
              ],
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
    );
  }
}

/// The place a coursework sample would sit, for a module that has none.
///
/// A drawn panel rather than a stand-in photograph. Filling the gap with a
/// picture of something else would be claiming an artefact that does not
/// exist, and the owner said he may supply these later.
class _NoSample extends StatelessWidget {
  const _NoSample({required this.module});

  final String module;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      label: '$module. ${context.l10n.educationNoSample}',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.surface,
            border: Border.all(
              color: tokens.hairline,
              width: tokens.hairlineWidth,
            ),
            borderRadius: BorderRadius.circular(Tokens.controlRadius),
          ),
          child: Center(
            child: Icon(
              Icons.description_outlined,
              size: Tokens.space16,
              color: tokens.instrumentDim,
            ),
          ),
        ),
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
/// The coursework behind a mark, at transcript size.
///
/// A mark is a number a reader has to take on trust; the coursework behind it
/// is what turns it into evidence. That is `14-PROVENANCE.md`'s argument
/// applied to a transcript, and it is why only the two modules with a supplied
/// artefact show one — the rest were not filtered, they were never given.
///
/// This used to be a 260px card in a row of its own below the marks, which
/// meant printing every module's name and mark for a second time. At this size
/// it sits in the module's own row and still opens full width.
class _SampleThumbnail extends StatefulWidget {
  const _SampleThumbnail({
    required this.evidence,
    required this.module,
    required this.mark,
  });

  final Evidence evidence;
  final String module;
  final double mark;

  @override
  State<_SampleThumbnail> createState() => _SampleThumbnailState();
}

class _SampleThumbnailState extends State<_SampleThumbnail> {
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
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _states.value.contains(WidgetState.hovered)
                        ? tokens.beacon
                        : tokens.hairline,
                    width: tokens.hairlineWidth,
                  ),
                  borderRadius: BorderRadius.circular(Tokens.controlRadius),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Tokens.controlRadius),
                  child: Image(
                    image: contentImage(context, widget.evidence.src),
                    fit: BoxFit.cover,
                    // A missing file is a missing artefact, not a broken page.
                    errorBuilder: (context, _, _) =>
                        _NoSample(module: widget.module),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
                child: Image(
                  image: contentImage(context, src),
                  fit: BoxFit.contain,
                ),
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
