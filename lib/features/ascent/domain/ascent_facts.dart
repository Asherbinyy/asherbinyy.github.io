import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/content/models/career.dart';

/// One thing the climb uncovers, and where it lives on the site.
typedef AscentFact = ({String title, String detail, String route});

/// Builds the climb's rewards from the site's own content.
///
/// `13-GAME-DESIGN.md`: every altitude band uncovers a real fact, read from
/// `assets/content/` rather than written for the game. That is what stops this
/// being a distraction with a portfolio bolted on, and it is why nothing here
/// can drift from what the rest of the site says.
///
/// Every fact also carries the route it came from, because the content must
/// stay reachable without playing. A game that hides someone's experience
/// behind hand-eye coordination is an accessibility failure dressed up as a
/// feature.
abstract final class AscentFacts {
  /// Facts in the order the climb reveals them.
  static List<AscentFact> from({
    required List<CareerRole> roles,
    required List<ShippedApp> apps,
    required AppLocale locale,
  }) {
    final facts = <AscentFact>[];

    for (final role in roles) {
      final company = role.company;
      if (company == null) continue;
      final title = role.title?.resolve(locale);
      facts.add((
        title: company,
        detail: [
          if (title != null) title,
          '${role.city}, ${role.country}',
          '${role.start} to ${role.end ?? ''}'.trim(),
        ].join(' · '),
        route: '/signal',
      ));
    }

    for (final app in apps) {
      final role = app.role?.resolve(locale);
      if (role == null) continue;
      facts.add((title: app.name, detail: role, route: '/work'));
    }

    return facts;
  }
}
