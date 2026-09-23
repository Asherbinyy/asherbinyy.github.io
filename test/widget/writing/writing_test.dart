import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/core/widgets/even_grid.dart';
import 'package:nocturne/features/writing/data/writing_providers.dart';
import 'package:nocturne/features/writing/domain/article.dart';
import 'package:nocturne/features/writing/presentation/widgets/article_card.dart';

import '../../support/chrome_harness.dart';
import '../../support/station_harness.dart';

List<Override> withArticles(List<Article> articles) => [
  articlesProvider.overrideWith((ref) async => articles),
];

final Article anArticle = (
  title: 'Shipping Flutter to the web',
  url: Uri.parse('https://sherbini.medium.com/shipping-flutter'),
  published: DateTime.utc(2026, 9, 5),
  // No cover: these tests are about the list, and a null cover keeps the card
  // on its procedural mark rather than reaching for a NetworkImage the test
  // environment would have to serve.
  cover: null,
  tags: const ['flutter', 'web'],
);

void main() {
  group('the writing index', () {
    testWidgets('renders a card for every article the feed returns', (
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
            cover: null,
            tags: const <String>[],
          ),
        ]),
      );

      expect(find.byType(ArticleCard), findsNWidgets(2));
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

      expect(find.byType(ArticleCard), findsNothing);
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

      expect(find.byType(ArticleCard), findsNothing);
      expect(find.textContaining('rror'), findsNothing);
    });

    testWidgets('exposes each card as a link for a screen reader', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.writing,
        overrides: withArticles([anArticle]),
      );

      final semantics = tester.getSemantics(find.byType(ArticleCard));

      expect(semantics.label, contains('Shipping Flutter to the web'));
    });
  });

  testWidgets('the article grid runs the full width of the page', (
    tester,
  ) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.large,
      initialRoute: AppRoute.writing,
      overrides: withArticles([
        for (var i = 0; i < 3; i++)
          (
            title: 'Post $i',
            url: Uri.parse('https://sherbini.medium.com/post-$i'),
            published: DateTime.utc(2026, 9, i + 1),
            cover: null,
            tags: const <String>[],
          ),
      ]),
    );

    // The owner's note: the articles did not fill the width the projects
    // did. Three fixed 280px cards stopped well short of the right edge; the
    // grid stretches its tiles now, so the row ends where every section does.
    final grid = tester.getRect(find.byType(EvenGrid));
    final cards = [
      for (final element in find.byType(ArticleCard).evaluate())
        tester.getRect(find.byWidget(element.widget)),
    ]..sort((a, b) => a.left.compareTo(b.left));
    expect(cards, hasLength(3));
    expect(cards.first.left, closeTo(grid.left, 1));
    expect(cards.last.right, closeTo(grid.right, 1));
    expect(cards.first.width, greaterThan(ArticleCard.width));
  });
}
