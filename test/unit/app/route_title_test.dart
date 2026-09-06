import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/l10n/generated/app_localizations.dart';
import 'package:nocturne/app/l10n/generated/app_localizations_ar.dart';
import 'package:nocturne/app/l10n/generated/app_localizations_en.dart';
import 'package:nocturne/app/route_title.dart';

const _name = 'Ahmed Elsherbini';

String _title(AppRoute route, [AppLocalizations? l10n]) =>
    routeTitle(route: route, l10n: l10n ?? AppLocalizationsEn(), name: _name);

void main() {
  test('the two entry points lead with the name', () {
    // Section 12: name first only on the routes a stranger lands on.
    expect(_title(AppRoute.station), 'Ahmed Elsherbini — Mobile Engineer');
    expect(_title(AppRoute.brief), 'Ahmed Elsherbini — Brief');
  });

  test('every other public route leads with its section', () {
    // So a stack of open tabs is scannable without hovering.
    expect(_title(AppRoute.signal), 'Signal — Ahmed Elsherbini');
    expect(_title(AppRoute.work), 'Work — Ahmed Elsherbini');
    expect(_title(AppRoute.writing), 'Writing — Ahmed Elsherbini');
    expect(_title(AppRoute.about), 'About — Ahmed Elsherbini');
    expect(_title(AppRoute.privacy), 'Privacy — Ahmed Elsherbini');
  });

  test('the console omits the name, not being a public surface', () {
    expect(_title(AppRoute.console), 'Console');
    expect(_title(AppRoute.console), isNot(contains(_name)));
  });

  test('every route resolves to a non-empty title', () {
    for (final route in AppRoute.values) {
      expect(_title(route), isNotEmpty, reason: route.name);
    }
  });

  test('titles follow the active language channel', () {
    final arabic = _title(AppRoute.work, AppLocalizationsAr());

    expect(arabic, isNot(_title(AppRoute.work)));
    expect(arabic, contains(_name));
  });

  test('no two public sections share a title', () {
    final titles = {for (final route in AppRoute.values) _title(route)};

    // The case study borrows the work title until Milestone 2 supplies study
    // names, and a campaign link redirects to the station, so two pairs
    // legitimately collide.
    expect(titles.length, AppRoute.values.length - 2);
  });
}
