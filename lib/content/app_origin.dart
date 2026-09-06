import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/content/models/career.dart';

/// Where an application was built, with coordinates when the content has them.
typedef AppOrigin = ({String country, double? latitude, double? longitude});

/// Resolves an application's origin without inferring one.
///
/// Section 11 wants a country on the station card, but `apps.json` need not
/// carry one. Two honest sources, in order of authority:
///
/// 1. an explicit `country` on the application — set it and it wins;
/// 2. the career role that lists the application in its `appIds`, which also
///    supplies real coordinates for the beacon node.
///
/// Anything else resolves to null and the card simply omits the country. The
/// storefront in a store URL is deliberately not consulted: it says where an
/// app is listed, not where the work was done, and putting that on the site
/// would be a claim the owner never made.
abstract final class AppOrigins {
  /// Resolves the origin of [app] against [career], or null when unrecorded.
  static AppOrigin? resolve({required ShippedApp app, required Career career}) {
    final declared = app.country;
    if (declared != null && declared.isNotEmpty) {
      final match = _roleForCountry(career, declared);
      return (country: declared, latitude: match?.$1, longitude: match?.$2);
    }

    for (final role in career.roles) {
      if (!role.appIds.contains(app.id)) continue;
      final coords = _coordsOf(role);
      return (
        country: role.country,
        latitude: coords?.$1,
        longitude: coords?.$2,
      );
    }
    return null;
  }

  static (double, double)? _roleForCountry(Career career, String country) {
    for (final role in career.roles) {
      if (role.country != country) continue;
      final coords = _coordsOf(role);
      if (coords != null) return coords;
    }
    return null;
  }

  /// `coords` is `[lat, lon]` per the content schema; a shorter list is not a
  /// coordinate and is treated as absent rather than half-read.
  static (double, double)? _coordsOf(CareerRole role) =>
      role.coords.length < 2 ? null : (role.coords[0], role.coords[1]);
}
