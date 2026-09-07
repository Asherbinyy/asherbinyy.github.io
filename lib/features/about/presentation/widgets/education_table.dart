import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/education.dart';

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
            for (final module in modules) _Module(module: module),
          ],
          if (entry.highlights.isNotEmpty) ...[
            SizedBox(height: tokens.space16),
            for (final highlight in entry.highlights)
              Padding(
                padding: EdgeInsets.only(bottom: tokens.space8),
                child: Text(
                  highlight.resolve(context.channel),
                  style: type.body.copyWith(color: tokens.textSecondary),
                ),
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
      child: Row(
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
            // Marks are whole numbers in the supplied content; the type scale
            // puts tabular figures on numeric styles so the column aligns.
            module.mark.toStringAsFixed(0),
            style: type.telemetry.copyWith(color: tokens.instrument),
          ),
        ],
      ),
    );
  }
}
