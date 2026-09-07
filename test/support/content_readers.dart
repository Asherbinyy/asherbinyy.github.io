import 'dart:convert';
import 'dart:io';

import 'package:nocturne/content/content_repository.dart';

/// Reads the real bundled JSON from disk.
///
/// Tests exercise the owner's actual content rather than a fixture, so a change
/// to `assets/content/` that breaks a screen fails here rather than in a
/// browser. [overrides] replaces individual documents to drive failure paths.
AssetReader bundledContent({Map<String, String> overrides = const {}}) =>
    (String path) async {
      final override = overrides[path];
      if (override != null) return override;
      final file = File(path);
      if (!file.existsSync()) {
        throw StateError('Missing bundled asset: $path');
      }
      return file.readAsString();
    };

/// A reader whose every read fails, driving the repository's fallback path.
Future<String> unreadableContent(String path) =>
    Future<String>.error(StateError('unavailable'));

/// A reader returning malformed JSON for everything, the fallback included.
Future<String> corruptContent(String path) async => '{ not json';

/// Encodes an object as the bundle would serve it.
String asAsset(Object value) => jsonEncode(value);

/// The owner's real content, decoded.
///
/// Lets a test assert against what `assets/content/` actually says instead of
/// against a number copied out of it. Copied counts have twice now survived a
/// content change by quietly becoming impossible to fail — an eleven-card
/// assertion that a twelfth app makes wrong, and a featured-slot flag that
/// stopped adding a seventh entry once the ledger reordered.
Map<String, dynamic> bundledJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Every application in the owner's ledger, in source order.
List<Map<String, dynamic>> bundledApps() =>
    (bundledJson('assets/content/apps.json')['apps'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

/// Every stop on the owner's journey, in source order.
List<Map<String, dynamic>> bundledStops() =>
    (bundledJson('assets/content/career.json')['roles'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

/// The store map of one ledger entry.
Map<String, dynamic> storeOf(Map<String, dynamic> app) =>
    app['store'] as Map<String, dynamic>? ?? const {};
