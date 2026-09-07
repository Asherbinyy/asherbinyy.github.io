import 'package:nocturne/app/l10n/generated/app_localizations.dart';
import 'package:nocturne/content/models/apps.dart';

/// Localised display names for the work domains.
///
/// The domain values in `apps.json` are the owner's data and stay in English
/// there; what a viewer reads comes from ARB, so Arabic ships without editing
/// content. The switch is exhaustive on purpose — adding a domain to the enum
/// must fail to compile here rather than fall through to a default.
extension WorkDomainLabel on WorkDomain {
  /// The viewer-facing name of this domain in the active locale.
  String label(AppLocalizations l10n) => switch (this) {
    WorkDomain.travel => l10n.workDomainTravel,
    WorkDomain.mobility => l10n.workDomainMobility,
    WorkDomain.education => l10n.workDomainEducation,
    WorkDomain.retail => l10n.workDomainRetail,
    WorkDomain.services => l10n.workDomainServices,
    WorkDomain.marketplace => l10n.workDomainMarketplace,
    WorkDomain.consumer => l10n.workDomainConsumer,
    WorkDomain.safety => l10n.workDomainSafety,
  };
}
