// ignore_for_file: avoid_print
/// Tests for tool/generate_static.dart.
///
/// These tests run the generator against the real bundled content and validate
/// that the output contains the required structural and semantic elements.
/// Runs with `fvm flutter test` like any other test.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';

/// A token as the six-digit uppercase hex the generator writes.
///
/// The static pages hand-write their palette as CSS custom properties, because
/// they are deliberately outside Flutter. That makes them the one surface that
/// can silently fall out of step with `tokens.dart` -- and it did, when the
/// Kemet and Deshret palettes shipped and these pages kept the milestone-1
/// colours. Deriving the expectation from the token means the next palette
/// change fails here instead of shipping two different sites.
String _hex(Color colour) {
  final rgb = colour.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

void main() {
  late String cvHtml;
  late String briefHtml;
  late String robotsTxt;
  late String sitemapXml;

  setUpAll(() {
    // Run the generator under the pinned SDK rather than whatever `dart`
    // happens to be on PATH, which would defeat .fvmrc. `flutter test` sets
    // FLUTTER_ROOT to the SDK actually in use, so its bundled Dart is the
    // right one both locally under FVM and in CI, which has no FVM.
    final result = Process.runSync(_dartExecutable(), [
      'run',
      'tool/generate_static.dart',
    ], workingDirectory: _projectRoot());
    if (result.exitCode != 0) {
      fail(
        'Generator failed with exit code ${result.exitCode}:\n'
        '${result.stderr}',
      );
    }

    final root = _projectRoot();
    cvHtml = File('$root/web/cv/index.html').readAsStringSync();
    briefHtml = File('$root/web/brief/index.html').readAsStringSync();
    robotsTxt = File('$root/web/robots.txt').readAsStringSync();
    sitemapXml = File('$root/web/sitemap.xml').readAsStringSync();
  });

  group('CV page', () {
    test('is valid HTML5 with lang and dir', () {
      expect(cvHtml, contains('<!DOCTYPE html>'));
      expect(cvHtml, contains('<html lang="en" dir="ltr">'));
    });

    test('has proper meta tags', () {
      expect(cvHtml, contains('<meta charset="UTF-8">'));
      expect(cvHtml, contains('name="viewport"'));
      // One theme-color per scheme, so browser chrome matches the page.
      expect(
        cvHtml,
        contains(
          'name="theme-color" media="(prefers-color-scheme: dark)" '
          'content="${_hex(nocturneTokens.void_)}"',
        ),
      );
      expect(
        cvHtml,
        contains(
          'name="theme-color" media="(prefers-color-scheme: light)" '
          'content="${_hex(daybreakTokens.void_)}"',
        ),
      );
      expect(cvHtml, contains('name="description"'));
    });

    test('has correct title', () {
      expect(cvHtml, contains('<title>Ahmed Elsherbini — CV</title>'));
    });

    test('has canonical URL', () {
      expect(cvHtml, contains('href="https://asherbinyy.github.io/cv/"'));
    });

    test('has Open Graph tags', () {
      expect(cvHtml, contains('og:type'));
      expect(cvHtml, contains('og:title'));
      expect(cvHtml, contains('og:description'));
      expect(cvHtml, contains('og:url'));
      expect(cvHtml, contains('og:image'));
    });

    test('has Twitter Card tags', () {
      expect(cvHtml, contains('twitter:card'));
      expect(cvHtml, contains('twitter:title'));
    });

    test('has JSON-LD Person schema', () {
      expect(cvHtml, contains('application/ld+json'));
      // Extract and parse JSON-LD to verify structure.
      final ldStart = cvHtml.indexOf('application/ld+json');
      final jsonStart = cvHtml.indexOf('{', ldStart);
      final jsonEnd = cvHtml.indexOf('</script>', jsonStart);
      final jsonStr = cvHtml.substring(jsonStart, jsonEnd);
      final schema = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(schema['@context'], 'https://schema.org');
      expect(schema['@type'], 'Person');
      expect(schema['name'], 'Ahmed Elsherbini');
      expect(schema['jobTitle'], 'Mobile Engineer');
      expect(schema['sameAs'], isA<List<dynamic>>());
      expect(schema['alumniOf'], isA<List<dynamic>>());
      expect(schema['knowsAbout'], isA<List<dynamic>>());
    });

    test('has single h1 with name', () {
      expect(cvHtml, contains('<h1>Ahmed Elsherbini</h1>'));
      // Only one h1.
      expect(RegExp('<h1>').allMatches(cvHtml).length, 1);
    });

    test('has semantic sections', () {
      expect(cvHtml, contains('<header>'));
      expect(cvHtml, contains('<main>'));
      expect(cvHtml, contains('<footer>'));
      expect(cvHtml, contains('<section>'));
      expect(cvHtml, contains('<article'));
    });

    test('has positioning text', () {
      // Read from the content rather than pinned to a sentence. The line is
      // the owner's own copy and he rewrites it; a literal here just breaks
      // every time he does, which is what it did.
      final profile = jsonDecode(
        File('${_projectRoot()}/assets/content/profile.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final positioning =
          (profile['positioning'] as Map<String, dynamic>)['en'] as String;
      expect(positioning, isNotEmpty);
      expect(cvHtml, contains(positioning));
    });

    test('has status text', () {
      // The CV records the award as confirmed, so the status line no longer
      // hedges. It still comes from profile.json rather than being written
      // here, so a later change to the content flows through.
      expect(cvHtml, contains('Distinction'));
      expect(cvHtml, isNot(contains('predicted Distinction')));
    });

    test('has experience section with career roles', () {
      expect(cvHtml, contains('Experience'));
      expect(cvHtml, contains('CI Company'));
      expect(cvHtml, contains('MiNextStep'));
    });

    test('career roles are in reverse chronological order', () {
      // The most recent role should appear before the earliest.
      final evriIndex = cvHtml.indexOf('evri');
      final ciIndex = cvHtml.indexOf('CI Company');
      expect(evriIndex, lessThan(ciIndex));
    });

    test('has shipped applications section with all apps', () {
      expect(cvHtml, contains('Shipped applications'));
      expect(cvHtml, contains('Tripster'));
      expect(cvHtml, contains('AZ Courses'));
      expect(cvHtml, contains('Mokaf'));
      expect(cvHtml, contains('Enjoy'));
      expect(cvHtml, contains('Malboos'));
      expect(cvHtml, contains('Tiara Beauty'));
      expect(cvHtml, contains('Tekrar'));
      expect(cvHtml, contains('Wasset'));
      expect(cvHtml, contains('Snunu'));
      expect(cvHtml, contains('Mostaqbaly'));
      expect(cvHtml, contains('AZ Exams'));
    });

    test('has working store links without escaped slashes', () {
      expect(cvHtml, contains('href="https://apps.apple.com/'));
      // Must NOT have &#47; in URLs.
      expect(cvHtml, isNot(contains('&#47;')));
    });

    test('has metrics where available', () {
      expect(cvHtml, contains('15,000+ downloads'));
    });

    test('has education section', () {
      expect(cvHtml, contains('Education'));
      expect(cvHtml, contains('University of Salford'));
      expect(cvHtml, contains('Mansoura University'));
    });

    test('has module marks', () {
      expect(cvHtml, contains('Business Data Insights'));
      expect(cvHtml, contains('94%'));
    });

    test('has skills section', () {
      expect(cvHtml, contains('Skills'));
      expect(cvHtml, contains('Flutter'));
      expect(cvHtml, contains('Dart'));
      expect(cvHtml, contains('Swift'));
    });

    test('has contact section', () {
      expect(cvHtml, contains('Contact'));
      expect(cvHtml, contains('ahmed.elsherbini.tech@gmail.com'));
      expect(cvHtml, contains('LinkedIn'));
      expect(cvHtml, contains('GitHub'));
    });

    test('has inline CSS with design tokens', () {
      expect(cvHtml, contains('<style>'));
      expect(cvHtml, contains('--void:${_hex(nocturneTokens.void_)}'));
      expect(cvHtml, contains('--beacon:${_hex(nocturneTokens.beacon)}'));
      // The light block too: it drifted unnoticed once already.
      expect(cvHtml, contains('--void:${_hex(daybreakTokens.void_)}'));
      expect(cvHtml, contains('--beacon:${_hex(daybreakTokens.beacon)}'));
    });

    test('has no JavaScript', () {
      // The page must render with JS disabled.
      expect(cvHtml, isNot(contains('<script src=')));
      // Only the JSON-LD script tag should be present.
      expect(RegExp('<script').allMatches(cvHtml).length, 1);
    });

    test('has favicon link', () {
      expect(cvHtml, contains('href="/favicon.png"'));
    });
  });

  group('Brief page', () {
    test('is valid HTML5 with lang and dir', () {
      expect(briefHtml, contains('<!DOCTYPE html>'));
      expect(briefHtml, contains('<html lang="en" dir="ltr">'));
    });

    test('has correct title', () {
      expect(briefHtml, contains('<title>Ahmed Elsherbini — Brief</title>'));
    });

    test('has only featured apps (6 maximum)', () {
      // Read from the ledger rather than listed here: which six are featured
      // is an editorial choice the owner makes in JSON, and a hand-written
      // copy of it turns his edit into a failing build for no reason.
      final apps =
          (jsonDecode(
                File('${_projectRoot()}/assets/content/apps.json')
                    .readAsStringSync(),
              ) as Map<String, dynamic>)['apps']
              as List<dynamic>;

      final featured = apps
          .cast<Map<String, dynamic>>()
          .where((a) => a['featured'] == true)
          .toList();
      expect(featured, hasLength(lessThanOrEqualTo(6)));

      for (final app in featured) {
        expect(briefHtml, contains(app['name']), reason: '${app['id']}');
      }
      for (final app in apps.cast<Map<String, dynamic>>()) {
        if (app['featured'] == true) continue;
        expect(
          briefHtml,
          isNot(contains(app['name'])),
          reason: '${app['id']} is not featured',
        );
      }
    });

    test('has education summary', () {
      expect(briefHtml, contains('University of Salford'));
      expect(briefHtml, contains('Mansoura University'));
    });

    test('has contact section', () {
      expect(briefHtml, contains('Contact'));
      expect(briefHtml, contains('ahmed.elsherbini.tech@gmail.com'));
    });

    test('has link to full portfolio', () {
      expect(briefHtml, contains('View full portfolio'));
      expect(briefHtml, contains('https://asherbinyy.github.io/'));
    });

    test('has no JavaScript', () {
      expect(briefHtml, isNot(contains('<script')));
    });
  });

  group('privacy of the indexable pages', () {
    test('neither page publishes a telephone number', () {
      // These exist to be crawled, and an indexed tel: link is harvested by
      // scrapers. Email and the profile links carry contact instead.
      expect(cvHtml, isNot(contains('tel:')));
      expect(briefHtml, isNot(contains('tel:')));
      expect(cvHtml, isNot(contains('+447741204235')));
      expect(briefHtml, isNot(contains('+447741204235')));
    });

    test('email and the profile links still reach the owner', () {
      expect(cvHtml, contains('mailto:'));
      expect(cvHtml, contains('linkedin.com'));
      expect(briefHtml, contains('mailto:'));
    });
  });

  group('robots.txt', () {
    test('allows all crawlers', () {
      expect(robotsTxt, contains('User-agent: *'));
      expect(robotsTxt, contains('Allow: /'));
    });

    test('includes sitemap reference', () {
      expect(
        robotsTxt,
        contains('Sitemap: https://asherbinyy.github.io/sitemap.xml'),
      );
    });
  });

  group('sitemap.xml', () {
    test('is well-formed XML', () {
      expect(sitemapXml, contains('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(
        sitemapXml,
        contains('xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"'),
      );
    });

    test('includes all public routes', () {
      expect(sitemapXml, contains('https://asherbinyy.github.io/'));
      expect(sitemapXml, contains('https://asherbinyy.github.io/cv/'));
      expect(sitemapXml, contains('https://asherbinyy.github.io/brief/'));
      // No trailing slash on application routes: AppRoute declares '/work',
      // and go_router resolves '/work/' to its error route, so advertising the
      // slashed form would point search engines at the error page.
      expect(sitemapXml, contains('<loc>https://asherbinyy.github.io/signal<'));
      expect(sitemapXml, contains('<loc>https://asherbinyy.github.io/work<'));
      expect(sitemapXml, isNot(contains('/work/</loc>')));
      // The two static pages are directories that Pages serves as such.
      expect(sitemapXml, contains('<loc>https://asherbinyy.github.io/cv/<'));
      expect(sitemapXml, contains('<loc>https://asherbinyy.github.io/about<'));
      expect(
        sitemapXml,
        contains('<loc>https://asherbinyy.github.io/writing<'),
      );
      expect(
        sitemapXml,
        contains('<loc>https://asherbinyy.github.io/privacy<'),
      );
    });

    test('does not include non-public routes', () {
      expect(sitemapXml, isNot(contains('/console')));
    });

    test('has lastmod dates', () {
      expect(sitemapXml, contains('<lastmod>'));
    });

    test('has priority values', () {
      expect(sitemapXml, contains('<priority>1.0</priority>'));
      expect(sitemapXml, contains('<priority>0.9</priority>'));
      expect(sitemapXml, contains('<priority>0.7</priority>'));
    });
  });

  group("both static pages follow the reader's theme", () {
    // The app follows a stored choice; these pages have nowhere to store one
    // and no JavaScript to read it, so they follow the operating system.
    for (final page in [('cv', () => cvHtml), ('brief', () => briefHtml)]) {
      test('${page.$1} declares both schemes', () {
        expect(page.$2(), contains('color-scheme:dark light'));
        expect(page.$2(), contains('@media(prefers-color-scheme:light)'));
      });

      test('${page.$1} carries the Deshret palette for light', () {
        expect(page.$2(), contains('--beacon:${_hex(daybreakTokens.beacon)}'));
        expect(
          page.$2(),
          contains('--text-muted:${_hex(daybreakTokens.textMuted)}'),
        );
      });

      test('${page.$1} carries the Kemet palette', () {
        expect(
          page.$2(),
          contains('--text-muted:${_hex(nocturneTokens.textMuted)}'),
        );
      });

      test('${page.$1} carries no superseded palette value', () {
        // Two generations of dead values. The milestone-1 drafts that failed
        // AA (#57687B measured 3.53:1, #7E5720 likewise), and the whole
        // milestone-1-to-3 amber palette these pages kept for one commit
        // after tokens.dart moved to Kemet. Both classes of mistake are the
        // same mistake -- a hand-written copy of a value that has an owner --
        // so they are guarded together.
        for (final dead in [
          '#57687B',
          '#7E5720',
          '#05070A',
          '#F1EDE4',
          '#F2A83B',
          '#95570B',
          '#C6D2E0',
          '#70849A',
        ]) {
          expect(
            page.$2(),
            isNot(contains(dead)),
            reason: '$dead is a superseded palette value',
          );
        }
      });
    }
  });
}

/// Locates the project root by walking up to find pubspec.yaml.
String _projectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 10; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir.path;
    dir = dir.parent;
  }
  return Directory.current.path;
}

/// The Dart binary belonging to the SDK running this test.
String _dartExecutable() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null || root.isEmpty) return 'dart';
  final bundled = File('$root/bin/cache/dart-sdk/bin/dart');
  return bundled.existsSync() ? bundled.path : 'dart';
}
