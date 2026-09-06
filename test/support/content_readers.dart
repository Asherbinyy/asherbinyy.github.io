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
