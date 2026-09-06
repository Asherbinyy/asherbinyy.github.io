import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/content/app_origin.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/content/models/career.dart';

const _career = Career(
  roles: [
    CareerRole(
      id: 'ci-company',
      country: 'EG',
      city: 'Mansoura',
      coords: [31.0409, 31.3785],
      start: '2021-10',
      appIds: ['az-courses', 'enjoy'],
    ),
    CareerRole(
      id: 'evri',
      country: 'GB',
      city: 'Manchester',
      coords: [53.4808, -2.2426],
      start: '2025-11',
    ),
  ],
);

ShippedApp _app({String id = 'az-courses', String? country}) => ShippedApp(
  id: id,
  name: 'Fixture',
  platforms: const [AppPlatform.ios],
  store: const {},
  domain: WorkDomain.education,
  country: country,
);

void main() {
  test('resolves the country from the career role that shipped the app', () {
    final origin = AppOrigins.resolve(app: _app(), career: _career);

    expect(origin?.country, 'EG');
    expect(origin?.latitude, 31.0409);
    expect(origin?.longitude, 31.3785);
  });

  test('an explicit country on the application wins', () {
    final origin = AppOrigins.resolve(
      app: _app(country: 'GB'),
      career: _career,
    );

    expect(origin?.country, 'GB');
    expect(origin?.latitude, 53.4808);
  });

  test('an explicit country with no matching station has no coordinates', () {
    final origin = AppOrigins.resolve(
      app: _app(country: 'QA'),
      career: _career,
    );

    expect(origin?.country, 'QA');
    expect(origin?.latitude, isNull);
    expect(origin?.longitude, isNull);
  });

  test('an empty country string falls through to the career lookup', () {
    final origin = AppOrigins.resolve(
      app: _app(country: ''),
      career: _career,
    );

    expect(origin?.country, 'EG');
  });

  test('returns null when nothing records where the app was built', () {
    final origin = AppOrigins.resolve(
      app: _app(id: 'mokaf'),
      career: _career,
    );

    expect(origin, isNull);
  });

  test('an incomplete coordinate pair is treated as absent', () {
    const career = Career(
      roles: [
        CareerRole(
          id: 'partial',
          country: 'SA',
          city: 'Riyadh',
          coords: [24.7136],
          start: '2023-08',
          appIds: ['wasset'],
        ),
      ],
    );

    final origin = AppOrigins.resolve(
      app: _app(id: 'wasset'),
      career: career,
    );

    expect(origin?.country, 'SA');
    expect(origin?.latitude, isNull);
  });
}
