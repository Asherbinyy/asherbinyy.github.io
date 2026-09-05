/// Paths transcribed from the project brief, section 4.
enum AppRoute {
  /// Ground station.
  station('/'),

  /// Propagation map.
  signal('/signal'),

  /// Shipped applications.
  work('/work'),

  /// Individual case study.
  caseStudy('/work/:slug'),

  /// Articles.
  writing('/writing'),

  /// Background and contact.
  about('/about'),

  /// Consent controls, deferred beyond foundation.
  privacy('/privacy'),

  /// Dashboard placeholder; no dashboard or data exists yet.
  console('/console'),

  /// Reserved for the static HTML CV in task 1.4.
  cv('/cv'),

  /// Reserved for the static HTML recruiter view in task 1.4.
  brief('/brief'),

  /// Campaign placeholder; performs no tracking.
  campaign('/r/:campaign');

  const AppRoute(this.path);

  /// Authoritative URL pattern, never a display label.
  final String path;

  /// Whether the global chrome frames this route.
  ///
  /// `02-SCREEN-SPECS.md`: present on every route except `/cv` and `/brief`,
  /// which are static HTML served outside the app entirely.
  bool get hasGlobalChrome => this != AppRoute.cv && this != AppRoute.brief;
}
