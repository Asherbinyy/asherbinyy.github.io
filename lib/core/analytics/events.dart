/// The events this site can record, and nothing else.
///
/// A closed set rather than free-form strings: `06-ANALYTICS-AND-PRIVACY.md`
/// section 4 lists exactly what Tier 1 may capture, and an enum makes adding a
/// thing outside that list a code change somebody has to justify.
enum AnalyticsEvent {
  /// A route was viewed.
  routeView('route_view'),

  /// A map node was opened.
  mapNodeOpened('map_node_opened'),

  /// A case study was opened.
  caseStudyOpened('case_study_opened'),

  /// The CV was downloaded or opened.
  cvOpened('cv_opened'),

  /// The language was changed.
  languageChanged('language_changed'),

  /// The theme was changed.
  themeChanged('theme_changed');

  const AnalyticsEvent(this.name);

  /// Wire name. Stable, because the Worker aggregates on it.
  final String name;
}

/// One thing worth counting, with no viewer identity attached.
///
/// There is deliberately no field for anything in section 2's never-collected
/// list: no identifier, no demographic, no referrer path, no IP. The Worker
/// resolves coarse country server-side and discards the address in the same
/// invocation, so the client never sees or sends one.
typedef AnalyticsBeacon = ({
  AnalyticsEvent event,
  String route,
  String deviceClass,
  String? referrerHost,
  String? campaign,
});
