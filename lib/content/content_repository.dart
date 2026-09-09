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

/// Fetches a published override for one content file.
///
/// Returns null when there is nothing published for it, which is the ordinary
/// case rather than an error: the owner overrides the documents he has edited
/// and the rest stay as shipped.
typedef RemoteReader = Future<String?> Function(String file);

/// Loads content, preferring what the owner has published over what shipped.
///
/// `15-ADMIN-AND-MEDIA.md` §7.1. The bundle is not a cache of the remote, it
/// is the floor: every remote read is timed out and every failure of any kind
/// ends with the shipped document being used instead, so the site renders the
/// same with the service dead. That is the milestone's first non-negotiable,
/// and it is why the remote path has no error state a visitor can reach.
class ContentRepository {
  /// Injects bundle access so failure and caching can be tested without I/O.
  ///
  /// [remote] is optional because the app runs without it: no relay configured,
  /// or a build that deliberately has none, is a site that reads its bundle.
  ContentRepository(this._read, {this.remote, Duration? timeout})
    : _timeout = timeout ?? const Duration(seconds: 2);

  final AssetReader _read;

  /// Where published overrides come from, or null to read only the bundle.
  final RemoteReader? remote;

  /// How long a published document has to arrive before the bundle is used.
  ///
  /// Two seconds, from the milestone's non-negotiables. Long enough that a slow
  /// connection still gets the owner's latest, short enough that nobody waits
  /// for a service that is down.
  final Duration _timeout;

  final Map<String, Future<String>> _cache = {};
  final Map<String, Future<String?>> _published = {};

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
    final published = await _remoteSection(file, parse);
    if (published != null) return ContentReady(published);

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

  /// The published document for [file], or null to use the shipped one.
  ///
  /// Every failure returns null, deliberately and without distinction: the
  /// service being down, the request timing out, and the document being
  /// malformed all mean the same thing to a visitor, which is that they read
  /// the bundle. A malformed override falls back to the shipped content rather
  /// than to the minimum profile, because the shipped content is good and
  /// degrading past it would be a worse site than not publishing at all.
  Future<T?> _remoteSection<T>(
    String file,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final fetch = remote;
    if (fetch == null) return null;
    // Started outside the try so the cache holds one in-flight request per
    // file even when this call is the one that fails.
    final pending = _published.putIfAbsent(
      file,
      () async => fetch(file).timeout(_timeout),
    );
    try {
      final source = await pending;
      if (source == null) return null;
      // Bound before returning: T is generic, so a bare `return _decode(...)`
      // reads to the analyser as possibly returning a future out of a try,
      // where the catch below would not cover it.
      final parsed = _decode(source, parse);
      return parsed;
    } on Object {
      return null;
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
