import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/features/console/domain/console_summary.dart';

final DateTime today = DateTime.utc(2026, 9, 30);

CounterRow counter(
  String date,
  String event, {
  String route = '/',
  String campaign = '-',
  int count = 1,
}) => (
  dimensions: [date, event, route, 'GB', 'pointer', '-', campaign],
  count: count,
);

ConsoleSummary summarise({
  List<CounterRow> counters = const [],
  List<TotalRow> totals = const [],
}) => ConsoleSummary.from(counters: counters, totals: totals, today: today);

void main() {
  group('the window', () {
    test('counts only the last thirty days', () {
      final summary = summarise(
        counters: [
          counter('2026-09-30', 'route_view'),
          counter('2026-09-01', 'route_view'),
          // Thirty-one days back, one day outside.
          counter('2026-08-31', 'route_view'),
        ],
      );

      expect(summary.views, 2);
    });

    test('returns one daily entry per day, oldest first', () {
      final summary = summarise(
        counters: [counter('2026-09-30', 'route_view', count: 5)],
      );

      expect(summary.daily, hasLength(30));
      expect(summary.daily.last, 5);
      expect(summary.daily.first, 0);
    });
  });

  group('the tiles', () {
    test('sums views, unique visitors and CV opens separately', () {
      final summary = summarise(
        counters: [
          counter('2026-09-30', 'route_view', count: 12),
          counter('2026-09-29', 'route_view', count: 6),
          (dimensions: ['2026-09-30', 'unique_visitor'], count: 9),
          counter('2026-09-30', 'cv_opened', count: 3),
        ],
      );

      expect(summary.views, 18);
      expect(summary.uniqueVisitors, 9);
      expect(summary.cvOpens, 3);
    });

    test('derives a mean dwell from the total over the count', () {
      final summary = summarise(
        counters: [counter('2026-09-30', 'section_dwell', count: 4)],
        totals: [
          (dimensions: ['2026-09-30', 'section_dwell', '/'], total: 536),
        ],
      );

      // 536 seconds across 4 events is 134 seconds, which reads as 2m14s.
      expect(summary.meanDwellSeconds, 134);
    });

    test('reports zero dwell rather than dividing by nothing', () {
      expect(summarise().meanDwellSeconds, 0);
    });
  });

  group('the campaign table', () {
    test('groups by campaign and ranks by views', () {
      final summary = summarise(
        counters: [
          counter(
            '2026-09-30',
            'route_view',
            campaign: 'bjss-mobile',
            count: 11,
          ),
          counter('2026-09-30', 'route_view', campaign: 'deloitte', count: 18),
          counter('2026-09-28', 'cv_opened', campaign: 'deloitte', count: 3),
        ],
      );

      expect(summary.campaigns.map((c) => c.campaign), [
        'deloitte',
        'bjss-mobile',
      ]);
      expect(summary.campaigns.first.views, 18);
      expect(summary.campaigns.first.cvOpens, 3);
    });

    test('keeps the latest date a campaign was seen', () {
      final summary = summarise(
        counters: [
          counter('2026-09-12', 'route_view', campaign: 'deloitte'),
          counter('2026-09-27', 'route_view', campaign: 'deloitte'),
          counter('2026-09-19', 'cv_opened', campaign: 'deloitte'),
        ],
      );

      expect(summary.campaigns.single.lastSeen, '2026-09-27');
    });

    test('excludes traffic that carried no campaign', () {
      final summary = summarise(
        counters: [counter('2026-09-30', 'route_view', count: 40)],
      );

      expect(summary.campaigns, isEmpty);
      expect(summary.views, 40);
    });
  });

  group('rows that are not the usual shape', () {
    test('survives a row with fewer dimensions than expected', () {
      // The unique-visitor key carries two dimensions, not seven. Indexing
      // blind would throw and take the whole dashboard with it.
      final summary = summarise(
        counters: [
          (dimensions: ['2026-09-30', 'unique_visitor'], count: 4),
          (dimensions: const [], count: 99),
        ],
      );

      expect(summary.uniqueVisitors, 4);
      expect(summary.views, 0);
    });

    test('reports emptiness when nothing was collected', () {
      expect(summarise().isEmpty, isTrue);
    });
  });
}
