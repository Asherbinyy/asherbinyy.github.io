import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every translatable string in the owner's content carries Arabic.
///
/// Arabic was structurally complete from milestone 1 — the ARB channel, the
/// RTL layout and the direction flip all worked — while every `ar` field in
/// `assets/content/` was null. The result read as a language toggle that
/// changed the furniture and left the content in English, which is what the
/// owner meant by "it works only for titles".
///
/// This walks the content documents rather than naming fields, so a string
/// added to content without a translation fails here instead of shipping as a
/// silent English fallback. The fallback itself stays deliberate and tested —
/// see `content_models_test.dart` — it is simply no longer the normal case.
void main() {
  const documents = [
    'assets/content/profile.json',
    'assets/content/fallback.json',
    'assets/content/career.json',
    'assets/content/apps.json',
    'assets/content/education.json',
  ];

  for (final path in documents) {
    test('$path translates every localised string', () {
      final decoded = jsonDecode(File(path).readAsStringSync());
      final untranslated = <String>[];
      _walk(decoded, '', untranslated);

      final listed = untranslated.join('\n  ');
      expect(
        untranslated,
        isEmpty,
        reason: 'these carry English with no Arabic:\n  $listed',
      );
    });
  }
}

/// Collects the path of every `{en, ar}` pair whose `ar` is missing or blank.
///
/// A localised string is recognised by shape — an object with an `en` key —
/// rather than by a list of field names, so extending the schema does not
/// require extending this test.
void _walk(Object? node, String path, List<String> found) {
  if (node is Map<String, dynamic>) {
    if (node.containsKey('en')) {
      final arabic = node['ar'];
      if (arabic == null || (arabic is String && arabic.trim().isEmpty)) {
        found.add('$path: "${node['en']}"');
      }
      return;
    }
    for (final entry in node.entries) {
      _walk(
        entry.value,
        path.isEmpty ? entry.key : '$path.${entry.key}',
        found,
      );
    }
    return;
  }
  if (node is List) {
    for (var i = 0; i < node.length; i++) {
      _walk(node[i], '$path[$i]', found);
    }
  }
}
