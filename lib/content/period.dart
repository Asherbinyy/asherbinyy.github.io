import 'package:nocturne/app/l10n/generated/app_localizations.dart';

/// Formats a span of time from the content schema.
///
/// One place, because three surfaces print the same range and each had its
/// own copy. Two things were wrong with those copies and both are fixed here.
///
/// They joined the dates with an em dash, which the owner asked be removed
/// from everything the site presents. A word carries the same meaning and
/// reads aloud correctly, which a dash never did.
///
/// They also rendered an open-ended period as a dangling separator: a role
/// with no end date printed "2025-08 to" and then stopped, because the
/// fallback was an empty string. An ongoing period now says so.
String formatPeriod(AppLocalizations l10n, String start, String? end) =>
    l10n.periodRange(start, end ?? l10n.periodPresent);
