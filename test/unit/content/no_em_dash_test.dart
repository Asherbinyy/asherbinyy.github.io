import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The owner asked for em dashes to be removed from everything the site
/// presents, and they kept coming back: first in metadata, then in the tab
/// titles and every date range, each time found by hand.
///
/// This is the instruction written down where it runs. It reads the shipped
/// content and the shipped strings rather than any one screen, so a dash added
/// to a new field or a new language is caught by a test nobody has to remember
/// to update.
void main() {
  const emDash = '—';

  /// Content files are the owner's own prose, in both languages.
  test('no shipped content presents an em dash', () {
    final directory = Directory('assets/content');
    final offenders = <String>[];

    for (final file in directory.listSync().whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      final text = file.readAsStringSync();
      if (text.contains(emDash)) {
        for (final (index, line)
            in const LineSplitter().convert(text).indexed) {
          if (line.contains(emDash)) {
            offenders.add('${file.path}:${index + 1}  ${line.trim()}');
          }
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  /// Interface strings, which the content files do not cover.
  test('no interface string presents an em dash', () {
    final offenders = <String>[];

    for (final name in ['app_en.arb', 'app_ar.arb']) {
      final file = File('lib/app/l10n/$name');
      final strings =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      strings.forEach((key, value) {
        // Metadata blocks describe strings to translators and are never shown.
        if (key.startsWith('@')) return;
        if (value is String && value.contains(emDash)) {
          offenders.add('$name  $key: $value');
        }
      });
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
