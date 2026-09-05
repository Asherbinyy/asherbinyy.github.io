import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/l10n/generated/app_localizations.dart';
import 'package:nocturne/app/l10n/generated/app_localizations_ar.dart';
import 'package:nocturne/app/l10n/generated/app_localizations_en.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/content/work_domain_label.dart';

void main() {
  test('every documented domain has an English label', () {
    final AppLocalizations l10n = AppLocalizationsEn();

    for (final domain in WorkDomain.values) {
      expect(domain.label(l10n), isNotEmpty);
    }
  });

  test('every documented domain has an Arabic label', () {
    final AppLocalizations l10n = AppLocalizationsAr();

    for (final domain in WorkDomain.values) {
      expect(domain.label(l10n), isNotEmpty);
    }
  });

  test('the Arabic labels are genuinely translated, not English copies', () {
    final AppLocalizations english = AppLocalizationsEn();
    final AppLocalizations arabic = AppLocalizationsAr();

    for (final domain in WorkDomain.values) {
      expect(domain.label(arabic), isNot(domain.label(english)));
    }
  });

  test('each domain resolves to a distinct label', () {
    final AppLocalizations l10n = AppLocalizationsEn();
    final labels = WorkDomain.values.map((d) => d.label(l10n)).toSet();

    expect(labels, hasLength(WorkDomain.values.length));
  });
}
