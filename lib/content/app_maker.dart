import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/content/models/career.dart';

/// Who an application was built at or for, as the content records it.
sealed class AppMaker {
  const AppMaker();
}

/// Built at a company, or for a client.
final class MadeAt extends AppMaker {
  /// [name] as the content spells it; [country] as an ISO code, if known.
  const MadeAt(this.name, {this.country, this.isFreelance = false});

  /// The company or client.
  final String name;

  /// Where they are.
  final String? country;

  /// Whether this is the freelance stop rather than a company: its name is a
  /// word the page translates, not a proper noun it prints as written.
  final bool isFreelance;
}

/// The owner's own project.
final class MadeForSelf extends AppMaker {
  /// There is only one of him.
  const MadeForSelf();
}

/// Resolves an application's maker without inferring one.
///
/// Three honest sources, in order: the career stop that lists the app in its
/// `appIds` (the company, and the country it is in); the app's own `client`
/// (for work done directly for a company with no stop of its own); and an
/// engagement of `personal`. Anything else is null and the card says nothing.
abstract final class AppMakers {
  /// The maker of [app] according to [career], or null when unrecorded.
  static AppMaker? resolve({required ShippedApp app, required Career career}) {
    for (final role in career.roles) {
      if (!role.appIds.contains(app.id)) continue;
      final company = role.company;
      if (company == null) continue;
      final isFreelance = role.id == 'freelance';
      // Freelance has no office of its own: the country worth naming is
      // the client's.
      return MadeAt(
        company,
        country: isFreelance ? app.country : role.country,
        isFreelance: isFreelance,
      );
    }
    if (app.client case final client? when client.isNotEmpty) {
      return MadeAt(client, country: app.country);
    }
    if (app.engagement == Engagement.personal) return const MadeForSelf();
    return null;
  }
}
