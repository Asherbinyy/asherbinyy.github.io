import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/content/content_parser.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/content/models/education.dart';
import 'package:nocturne/content/models/localized_text.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/content/models/study.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, Object?> profile;
  late Map<String, Object?> career;
  late Map<String, Object?> apps;
  late Map<String, Object?> education;

  setUp(() async {
    profile = await _asset('profile');
    career = await _asset('career');
    apps = await _asset('apps');
    education = await _asset('education');
  });

  test(
    'all supplied documents parse and round trip without changing content',
    () {
      final p = ContentParser.profile(profile);
      final c = ContentParser.career(career);
      final a = ContentParser.apps(apps);
      final e = ContentParser.education(education);

      expect(Profile.fromJson(p.toJson()), p);
      expect(Career.fromJson(c.toJson()), c);
      expect(Apps.fromJson(a.toJson()), a);
      expect(Education.fromJson(e.toJson()), e);
      expect(p.name.resolve(AppLocale.arabic), _object(profile['name'])['ar']);
      expect(p.positioning.resolve(AppLocale.arabic), p.positioning.en);
      expect(p.positioning.resolve(AppLocale.english), p.positioning.en);
      expect(() => c.roles.clear(), throwsUnsupportedError);
    },
  );

  test('optional profile references round trip when supplied', () {
    profile['cvFile'] = 'assets/cv/fixture.pdf';
    profile['portrait'] = {
      'src': 'assets/img/fixture.webp',
      'isPlaceholder': true,
    };
    _object(profile['contact'])['calendly'] =
        'https://example.invalid/schedule';
    _object(profile['venture'])['url'] = 'https://example.invalid/venture';
    final parsed = ContentParser.profile(profile);

    expect(ContentParser.profile(parsed.toJson()), parsed);
  });

  test('case study schema round trips without supplying production prose', () {
    const copy = LocalizedText(en: 'Test fixture');
    const study = Study(
      id: 'fixture',
      title: copy,
      context: copy,
      problem: copy,
      approach: copy,
      outcome: copy,
      stack: ['Dart'],
      screens: [StudyScreen(src: 'assets/screens/fixture.webp', caption: copy)],
    );

    expect(ContentParser.study(study.toJson()), study);
  });

  for (final bad in ['', '...', '…']) {
    test('profile rejects missing copy: $bad', () {
      _object(profile['positioning'])['en'] = bad;
      expect(() => ContentParser.profile(profile), throwsFormatException);
    });
  }
  for (final bad in [
    'javascript:alert(1)',
    '/relative',
    'https://user@example.com',
  ]) {
    test('profile rejects unsafe contact link $bad', () {
      _object(profile['contact'])['github'] = bad;
      expect(() => ContentParser.profile(profile), throwsFormatException);
    });
  }
  test('profile rejects invalid contact email', () {
    _object(profile['contact'])['email'] = 'invalid';
    expect(() => ContentParser.profile(profile), throwsFormatException);
  });
  test('profile rejects traversal in local asset references', () {
    profile['cvFile'] = 'assets/../private.pdf';
    expect(() => ContentParser.profile(profile), throwsFormatException);
  });
  for (final bad in [
    <num>[],
    <num>[91, 0],
    <num>[0, 181],
    <num>[0, 0, 0],
  ]) {
    test('career rejects invalid coordinates $bad', () {
      _item(career, 'roles')['coords'] = bad;
      expect(() => ContentParser.career(career), throwsFormatException);
    });
  }
  for (final bad in ['2021-13', '2021-00', '2021', '2021-1']) {
    test('career rejects invalid month $bad', () {
      _item(career, 'roles')['start'] = bad;
      expect(() => ContentParser.career(career), throwsFormatException);
    });
  }
  test('career rejects a period ending before it starts', () {
    // Deliberately absurd rather than "one year before the current first
    // entry". This asserted 2020-01 until milestone 4, which stopped being an
    // invalid end the moment the journey gained a 2015 study stop ahead of the
    // first job -- so a content edit silently turned a real assertion into one
    // that could never fail.
    _item(career, 'roles')['end'] = '1900-01';
    expect(() => ContentParser.career(career), throwsFormatException);
  });
  test('career rejects nonchronological source order', () {
    career['roles'] = _array(career['roles']).reversed.toList();
    expect(() => ContentParser.career(career), throwsFormatException);
  });
  test('career rejects invalid burst weight', () {
    _item(career, 'roles')['traceWeight'] = 1.1;
    expect(() => ContentParser.career(career), throwsFormatException);
  });
  test('apps reject duplicate IDs', () {
    _item(apps, 'apps', 1)['id'] = _item(apps, 'apps')['id'];
    expect(() => ContentParser.apps(apps), throwsFormatException);
  });
  test('apps reject more than six featured entries', () {
    // Feature everything rather than flipping one index. Flagging index 6
    // stopped adding a seventh the moment the ledger's order changed and that
    // slot was already featured, which made the assertion unfailable without
    // making it fail -- the same trap as the chronology test above.
    for (final app in _array(apps['apps'])) {
      _object(app)['featured'] = true;
    }
    expect(() => ContentParser.apps(apps), throwsFormatException);
  });
  test('apps reject a store link for an undeclared platform', () {
    _object(_item(apps, 'apps')['store'])['android'] =
        'https://example.invalid/store';
    expect(() => ContentParser.apps(apps), throwsFormatException);
  });
  test('apps reject duplicate nonempty store links', () {
    final first = _object(_item(apps, 'apps')['store'])['ios'];
    _object(_item(apps, 'apps', 3)['store'])['ios'] = first;

    expect(() => ContentParser.apps(apps), throwsFormatException);
  });
  test('education rejects marks outside the percentage range', () {
    _item(_item(education, 'entries'), 'modules')['mark'] = 101;
    expect(() => ContentParser.education(education), throwsFormatException);
  });
}

Future<Map<String, Object?>> _asset(String name) async {
  final Object? json = jsonDecode(
    await rootBundle.loadString('assets/content/$name.json'),
  );
  return _object(json);
}

Map<String, Object?> _object(Object? value) => switch (value) {
  final Map<String, Object?> object => object,
  _ => throw const FormatException('Expected fixture object'),
};

List<Object?> _array(Object? value) => switch (value) {
  final List<Object?> array => array,
  _ => throw const FormatException('Expected fixture array'),
};

Map<String, Object?> _item(
  Map<String, Object?> object,
  String key, [
  int index = 0,
]) => _object(_array(object[key])[index]);
