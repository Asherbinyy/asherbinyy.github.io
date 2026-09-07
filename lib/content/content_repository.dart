import 'dart:convert';

import 'package:nocturne/content/content_parser.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/content/models/education.dart';
import 'package:nocturne/content/models/interests.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/content/models/study.dart';

/// Injected asset access keeps models and generation independent of Flutter.
typedef AssetReader = Future<String> Function(String path);

/// Loads only bundled JSON; a cache coalesces concurrent asset reads.
class ContentRepository {
  /// Injects bundle access so failure and caching can be tested without I/O.
  ContentRepository(this._read);
  final AssetReader _read;
  final Map<String, Future<String>> _cache = {};

  /// Loads identity or the minimum fallback.
  Future<ContentResult<Profile>> profile() =>
      _load('profile.json', ContentParser.profile);

  /// Loads chronologically validated career stations.
  Future<ContentResult<Career>> career() =>
      _load('career.json', ContentParser.career);

  /// Loads the shipped application ledger.
  Future<ContentResult<Apps>> apps() => _load('apps.json', ContentParser.apps);

  /// Loads qualifications without inferring completion status.
  Future<ContentResult<Education>> education() =>
      _load('education.json', ContentParser.education);

  /// Loads what the owner does when he is not working.
  Future<ContentResult<Interests>> interests() =>
      _load('interests.json', ContentParser.interests);

  /// Rejects slugs that could escape the studies directory.
  Future<ContentResult<Study>> study(String slug) {
    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(slug)) {
      throw ArgumentError.value(slug, 'slug', 'Invalid study slug');
    }
    return _load('studies/$slug.json', ContentParser.study);
  }

  Future<String> _source(String file) {
    final path = 'assets/content/$file';
    return _cache.putIfAbsent(path, () => _read(path));
  }

  Future<ContentResult<T>> _load<T>(
    String file,
    T Function(Map<String, dynamic>) parse,
  ) async {
    try {
      return ContentReady(_decode(await _source(file), parse));
    } on Object {
      // Includes generated JSON type errors; no content or viewer data is sent.
      try {
        return ContentFallback(
          _decode(await _source('fallback.json'), ContentParser.profile),
        );
      } on Object {
        return const ContentUnavailable();
      }
    }
  }

  T _decode<T>(String source, T Function(Map<String, dynamic>) parse) {
    final Object? json = jsonDecode(source);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Content root must be an object');
    }
    return parse(json);
  }
}
