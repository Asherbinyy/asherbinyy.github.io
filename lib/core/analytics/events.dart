/// The events this site can record, and nothing else.
///
/// A closed set rather than free-form strings: `06-ANALYTICS-AND-PRIVACY.md`
/// The privacy contract lists exactly what consent may capture. An enum makes
/// adding a thing outside that list a code change somebody has to justify.
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
  themeChanged('theme_changed'),

  /// How far down a route the viewer read, reported once per route.
  ///
  /// The privacy contract lists scroll depth. It is reported as a quartile
  /// rather than a pixel offset, and once on leaving rather than continuously,
  /// because the useful question is "did they reach the work" and a stream of
  /// offsets would be closer to session replay, which section 2 bans outright.
  scrollDepth('scroll_depth'),

  /// How long the viewer stayed on a route, reported on leaving it.
  ///
  /// Section 4's "time per section". Sections on this site are routes.
  sectionDwell('section_dwell'),

  /// An error the viewer actually saw.
  ///
  /// Section 4 permits error reports. No message, stack or input is carried —
  /// only that one happened, on which route — because anything more could hold
  /// content the viewer typed.
  errorReported('error_reported'),

  /// A public link was activated, with its source and destination.
  outboundClick('outbound_click'),

  /// A gallery was opened.
  mediaOpened('media_opened'),

  /// The visitor asked to hear the name recording.
  namePlayed('name_played'),

  /// A climb started.
  gameStarted('game_started'),

  /// A climb reached its result screen.
  gameFinished('game_finished');

  const AnalyticsEvent(this.name);

  /// Wire name. Stable, because the Worker aggregates on it.
  final String name;
}

/// One thing worth counting, with no viewer identity attached.
///
/// There is deliberately no field for anything in section 2's never-collected
/// list: no demographic, no referrer path, no IP. The Worker resolves coarse
/// country server-side and discards the address in the same invocation, so the
/// client never sees or sends one.
///
/// `sessionId` is the one identifier: random, scoped
/// to a browser tab, held in `sessionStorage`, never written to `localStorage`
/// and never linked across visits. It is null for every route-view beacon.
///
/// `value` carries the one number an event needs — a scroll quartile, seconds
/// on a route — and is null for events that are simply counted.
typedef AnalyticsBeacon = ({
  AnalyticsEvent event,
  String route,
  String deviceClass,
  String? referrerHost,
  String? campaign,
  String? sessionId,
  int? value,
  String? target,
  String? destination,
});

/// Builds a beacon, so adding a field does not touch every call site.
///
/// Optional fields default to absent, which is also the route-view shape:
/// no session identifier and no value.
AnalyticsBeacon beacon({
  required AnalyticsEvent event,
  required String route,
  required String deviceClass,
  String? referrerHost,
  String? campaign,
  String? sessionId,
  int? value,
  String? target,
  String? destination,
}) => (
  event: event,
  route: route,
  deviceClass: deviceClass,
  referrerHost: referrerHost,
  campaign: campaign,
  sessionId: sessionId,
  value: value,
  target: target,
  destination: destination,
);
