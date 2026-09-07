import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every figure the site publishes has a row in `docs/14-PROVENANCE.md`.
///
/// The owner's first instruction of milestone 4 was that the site appeared to
/// be inventing numbers. It mostly was not — every figure traced to his CV —
/// but nothing in the repository could demonstrate that, and "trust the
/// worklog" is not a demonstration.
///
/// So `AGENTS.md` §3 now requires a provenance row before a number ships, and
/// this is what makes that requirement real rather than aspirational. It walks
/// the content, pulls out every number a reader will actually see, and fails
/// if the ledger does not mention it.
///
/// It is deliberately a shallow check: it asserts a figure is *accounted for*,
/// not that the accounting is honest. No test can do the second thing. What it
/// prevents is the specific failure that happened — a number appearing on the
/// site with nothing anywhere saying where it came from.
void main() {
  late String ledger;

  setUpAll(() {
    ledger = File('docs/14-PROVENANCE.md').readAsStringSync();
  });

  test('the ledger exists and names its sources', () {
    expect(ledger, contains('main resume.pdf'));
    expect(ledger, contains('LinkedIn'));
  });

  test('every published figure is accounted for', () {
    final unaccounted = <String>[];

    for (final path in [
      'assets/content/profile.json',
      'assets/content/apps.json',
      'assets/content/career.json',
      'assets/content/education.json',
    ]) {
      final decoded = jsonDecode(File(path).readAsStringSync());
      final figures = <String>{};
      _collectFigures(decoded, figures);

      for (final figure in figures) {
        if (!ledger.contains(figure)) {
          unaccounted.add('$path: $figure');
        }
      }
    }

    expect(
      unaccounted,
      isEmpty,
      reason:
          'these figures appear on the site with no row in '
          'docs/14-PROVENANCE.md:\n  ${unaccounted.join('\n  ')}',
    );
  });
}

/// Pulls the figures a reader sees out of a content document.
///
/// Only English copy and explicit stat values are scanned. Dates, coordinates,
/// marks and identifiers are excluded: a start date is checked by the parser's
/// chronology rules, a coordinate by its range check, and a mark comes from a
/// transcript rather than from a claim about impact. What is left is the class
/// of number that reads as an achievement — "25+", "15,000+", "50%", "16+" —
/// which is exactly the class the owner was right to be suspicious of.
void _collectFigures(Object? node, Set<String> found, {String key = ''}) {
  if (node is Map<String, dynamic>) {
    for (final entry in node.entries) {
      _collectFigures(entry.value, found, key: entry.key);
    }
    return;
  }
  if (node is List) {
    for (final item in node) {
      _collectFigures(item, found, key: key);
    }
    return;
  }
  if (node is String) {
    const scanned = {'en', 'value', 'metric', 'role', 'summary', 'positioning'};
    if (!scanned.contains(key)) return;
    for (final match in _figure.allMatches(node)) {
      found.add(match.group(0)!);
    }
  }
}

/// A quantity a reader would take as a claim: a number carrying `+`, `%`, or a
/// thousands separator. A bare year or a small count is not one.
final RegExp _figure = RegExp(r'\b\d[\d,]*(?:\+|%|(?=,\d{3}))');
