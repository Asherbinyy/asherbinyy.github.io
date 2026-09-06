import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/features/writing/data/writing_providers.dart';
import 'package:nocturne/features/writing/domain/article.dart';
import 'package:nocturne/features/writing/presentation/widgets/article_row.dart';

import '../../support/chrome_harness.dart';
import '../../support/station_harness.dart';

List<Override> withArticles(List<Article> articles) => [
  articlesProvider.overrideWith((ref) async => articles),
];

final Article anArticle = (
  title: 'Shipping Flutter to the web',
  url: Uri.parse('https://sherbini.medium.com/shipping-flutter'),
  published: DateTime.utc(2026, 9, 5),
  tags: const ['flutter', 'web'],
);

void main() {
  group('the writing index', () {
    testWidgets('renders a row for every article the feed returns', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.writing,
        overrides: withArticles([
          anArticle,
          (
            title: 'A second post',
            url: Uri.parse('https://sherbini.medium.com/second'),
            published: DateTime.utc(2026, 8),
            tags: const [],
          ),
        ]),
      );

      expect(find.byType(ArticleRow), findsNWidgets(2));
      expect(find.text('Shipping Flutter to the web'), findsOneWidget);
    });

    testWidgets('shows the date and tags on the telemetry line', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.writing,
        overrides: withArticles([anArticle]),
      );

      // ISO rather than a localised month name: it reads the same in both
      // directions and invents no Arabic month vocabulary.
      expect(find.text('2026-09-05   flutter · web'), findsOneWidget);
    });

    testWidgets('hides the list entirely when the feed yields nothing', (
      tester,
    ) async {
      // 03-ARCHITECTURE.md section 5: writing is not core content, so a failure
      // hides the section rather than showing an error.
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.writing,
        overrides: withArticles(const []),
      );

      expect(find.byType(ArticleRow), findsNothing);
    });

    testWidgets('never renders an error for a failed feed', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.writing,
        overrides: [
          articlesProvider.overrideWith(
            (ref) async => throw Exception('relay down'),
          ),
        ],
      );

      expect(find.byType(ArticleRow), findsNothing);
      expect(find.textContaining('rror'), findsNothing);
    });

    testWidgets('exposes each row as a link for a screen reader', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.writing,
        overrides: withArticles([anArticle]),
      );

      final semantics = tester.getSemantics(find.byType(ArticleRow));

      expect(semantics.label, contains('Shipping Flutter to the web'));
    });
  });
}
