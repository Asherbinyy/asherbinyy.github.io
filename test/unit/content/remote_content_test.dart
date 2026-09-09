import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/content/content_repository.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/content/models/profile.dart';

/// The shipped document, read straight from the bundle.
Future<String> _bundled(String path) => rootBundle.loadString(path);

/// A published profile that differs from the bundle in one readable way.
Future<String> _publishedProfile() async {
  final json = jsonDecode(
    await _bundled('assets/content/profile.json'),
  ) as Map<String, dynamic>;
  final positioning = Map<String, dynamic>.from(
    json['positioning'] as Map<String, dynamic>,
  );
  positioning['en'] = 'Published from the panel.';
  return jsonEncode({...json, 'positioning': positioning});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a published document is preferred over the shipped one', () async {
    final published = await _publishedProfile();
    final repository = ContentRepository(
      _bundled,
      remote: (file) async => file == 'profile.json' ? published : null,
    );

    final result = await repository.profile();
    expect(result, isA<ContentReady<Profile>>());
    expect(
      (result as ContentReady<Profile>).data.positioning.en,
      'Published from the panel.',
    );
  });

  test('a file with nothing published falls through to the bundle', () async {
    // The ordinary case: the owner edits one document and the rest ship as
    // they always did, so null must mean "use the bundle" rather than "fail".
    final repository = ContentRepository(_bundled, remote: (_) async => null);
    expect(await repository.career(), isA<ContentReady<Career>>());
    expect(await repository.apps(), isA<ContentReady<Apps>>());
  });

  group('the site renders with the service dead', () {
    // 15-ADMIN-AND-MEDIA.md section 3, first non-negotiable. Each of these is
    // a different way for the remote half to fail, and every one of them has
    // to be invisible.
    final failures = <String, RemoteReader>{
      'the service throws': (_) async => throw const SocketExceptionStub(),
      'the service returns nothing parseable': (_) async => '{ not json',
      'the service returns a non-object': (_) async => '[1, 2, 3]',
      'the service returns an object the parser rejects': (_) async =>
          jsonEncode({'positioning': 42}),
      'the service returns an empty string': (_) async => '',
    };

    for (final entry in failures.entries) {
      test(entry.key, () async {
        final repository = ContentRepository(_bundled, remote: entry.value);
        final result = await repository.profile();

        // Ready, not fallback: a bad override degrades to the shipped
        // document, which is good content, rather than to the minimum profile.
        expect(result, isA<ContentReady<Profile>>());
        final bundled = jsonDecode(
          await _bundled('assets/content/profile.json'),
        ) as Map<String, dynamic>;
        expect(
          (result as ContentReady<Profile>).data.positioning.en,
          (bundled['positioning'] as Map<String, dynamic>)['en'],
        );
      });
    }

    test('a service that never answers is given up on', () async {
      final repository = ContentRepository(
        _bundled,
        // Never completes. Without a timeout this test hangs, which is the
        // point: a visitor would be looking at a page that never arrives.
        remote: (_) => Completer<String?>().future,
        timeout: const Duration(milliseconds: 40),
      );

      final result = await repository.profile().timeout(
        const Duration(seconds: 5),
      );
      expect(result, isA<ContentReady<Profile>>());
    });
  });

  test('no remote configured reads the bundle and asks nothing', () async {
    final repository = ContentRepository(_bundled);
    expect(repository.remote, isNull);
    expect(await repository.profile(), isA<ContentReady<Profile>>());
  });

  test('one request per file however many sections ask for it', () async {
    // Every screen reads the profile. Refetching per read would multiply the
    // request count by the page, and each one carries the same two-second
    // budget.
    var calls = 0;
    final published = await _publishedProfile();
    final repository = ContentRepository(
      _bundled,
      remote: (file) async {
        calls++;
        return published;
      },
    );

    await Future.wait([
      repository.profile(),
      repository.profile(),
      repository.profile(),
    ]);
    expect(calls, 1);
  });

  test('a study slug that could escape the directory is still refused', () {
    // The remote path must not become a way round the check on the bundled
    // one: the slug is used to build the remote key as well.
    final repository = ContentRepository(_bundled, remote: (_) async => null);
    expect(() => repository.study('../profile'), throwsArgumentError);
    expect(() => repository.study('a/b'), throwsArgumentError);
  });
}

/// Stands in for a network failure without importing dart:io into a web test.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
