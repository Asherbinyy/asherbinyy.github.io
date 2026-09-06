/// One counter row as the Worker stores it.
///
/// Dimensions are positional because that is how the Worker's key is built:
/// `date | event | route | country | deviceClass | referrerHost | campaign`.
/// The unique-visitor row is the one exception and carries only `date` and the
/// literal `unique_visitor`, which is why every accessor here is bounds-checked
/// rather than indexing blind.
typedef CounterRow = ({List<String> dimensions, int count});

/// One running total, keyed `date | event | route`.
typedef TotalRow = ({List<String> dimensions, int total});

/// A campaign's performance, which is the operationally useful part.
typedef CampaignRow = ({
  String campaign,
  int views,
  int cvOpens,
  String lastSeen,
});

/// Everything `/console` displays, derived from counter rows.
///
/// Pure data in, pure data out: the whole dashboard is testable without a
/// network, a browser or a widget. That matters more here than elsewhere
/// because this is the page that has to be *right* — a portfolio that shows
/// wrong numbers about itself is worse than one that shows none.
class ConsoleSummary {
  /// Derives the summary for the [days] ending at [today].
  factory ConsoleSummary.from({
    required List<CounterRow> counters,
    required List<TotalRow> totals,
    required DateTime today,
    int days = 30,
  }) {
    final since = _iso(today.subtract(Duration(days: days - 1)));
    final until = _iso(today);
    bool inWindow(String date) =>
        date.compareTo(since) >= 0 && date.compareTo(until) <= 0;

    var views = 0;
    var uniqueVisitors = 0;
    var cvOpens = 0;
    var dwellEvents = 0;
    final daily = <String, int>{};
    final campaigns = <String, ({int views, int cvOpens, String lastSeen})>{};

    for (final row in counters) {
      if (row.dimensions.isEmpty || !inWindow(row.dimensions.first)) continue;
      final date = row.dimensions.first;
      final event = row.dimensions.length > 1 ? row.dimensions[1] : '';

      if (event == 'unique_visitor') {
        uniqueVisitors += row.count;
        continue;
      }
      if (event == 'route_view') {
        views += row.count;
        daily[date] = (daily[date] ?? 0) + row.count;
      }
      if (event == 'cv_opened') cvOpens += row.count;
      if (event == 'section_dwell') dwellEvents += row.count;

      final campaign = row.dimensions.length > 6 ? row.dimensions[6] : '-';
      if (campaign != '-' && campaign.isNotEmpty) {
        final existing = campaigns[campaign];
        campaigns[campaign] = (
          views:
              (existing?.views ?? 0) + (event == 'route_view' ? row.count : 0),
          cvOpens:
              (existing?.cvOpens ?? 0) + (event == 'cv_opened' ? row.count : 0),
          lastSeen: existing == null || date.compareTo(existing.lastSeen) > 0
              ? date
              : existing.lastSeen,
        );
      }
    }

    var dwellSeconds = 0;
    for (final row in totals) {
      if (row.dimensions.isEmpty || !inWindow(row.dimensions.first)) continue;
      final event = row.dimensions.length > 1 ? row.dimensions[1] : '';
      if (event == 'section_dwell') dwellSeconds += row.total;
    }

    final ranked =
        campaigns.entries
            .map(
              (e) => (
                campaign: e.key,
                views: e.value.views,
                cvOpens: e.value.cvOpens,
                lastSeen: e.value.lastSeen,
              ),
            )
            .toList()
          ..sort((a, b) => b.views.compareTo(a.views));

    return ConsoleSummary._(
      views: views,
      uniqueVisitors: uniqueVisitors,
      cvOpens: cvOpens,
      // A mean rather than a true median: the Worker stores a running total
      // and a count, never per-visit rows, so a median is not recoverable —
      // and recovering one would mean keeping the rows that make it possible.
      meanDwellSeconds: dwellEvents == 0 ? 0 : dwellSeconds ~/ dwellEvents,
      daily: [
        for (var i = 0; i < days; i++)
          daily[_iso(today.subtract(Duration(days: days - 1 - i)))] ?? 0,
      ],
      campaigns: List.unmodifiable(ranked),
    );
  }

  const ConsoleSummary._({
    required this.views,
    required this.uniqueVisitors,
    required this.cvOpens,
    required this.meanDwellSeconds,
    required this.daily,
    required this.campaigns,
  });

  /// Total route views in the window.
  final int views;

  /// Distinct daily visitor hashes, summed across days.
  ///
  /// Section 3's identifier is unlinkable across days by design, so this is
  /// "unique visitors per day, added up" — not people. The label says so.
  final int uniqueVisitors;

  /// Times the CV was opened.
  final int cvOpens;

  /// Mean seconds on a route, across dwell events.
  final int meanDwellSeconds;

  /// Views per day, oldest first, one entry per day in the window.
  final List<int> daily;

  /// Campaigns, most-viewed first.
  final List<CampaignRow> campaigns;

  /// Whether anything at all was collected in the window.
  bool get isEmpty => views == 0 && uniqueVisitors == 0 && cvOpens == 0;

  static String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
