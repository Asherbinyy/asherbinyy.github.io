/// Paths transcribed from the project brief, section 4.
enum AppRoute {
  /// The front door.
  ///
  /// Named for what a visitor calls it. It was `station`, from the radio
  /// metaphor the site used to run on, and no one arriving here would have
  /// guessed that meant "home".
  home('/'),

  /// Where the work happened, and when.
  ///
  /// Was `signal`, at `/signal`, which said nothing about a career map.
  journey('/journey'),

  /// Shipped applications.
  work('/work'),

  /// Individual case study.
  caseStudy('/work/:slug'),

  /// Articles.
  writing('/writing'),

  /// Background and contact.
  about('/about'),

  /// Everything that is not work: the interests, and the climb.
  courtyard('/courtyard'),

  /// Dashboard placeholder; no dashboard or data exists yet.
  console('/console'),

  /// Reserved for the static HTML CV in task 1.4.
  cv('/cv'),

  /// Reserved for the static HTML recruiter view in task 1.4.
  brief('/brief'),

  /// Session-scoped campaign entry; redirects to the front door.
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
