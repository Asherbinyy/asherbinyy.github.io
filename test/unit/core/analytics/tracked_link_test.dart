import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/core/analytics/tracked_link.dart';

void main() {
  test('public destinations remove queries and fragments', () {
    expect(
      analyticsDestination(
        Uri.parse('https://example.com/path?email=private#section'),
      ),
      'https://example.com/path',
    );
  });

  test('Google Play keeps only its public application id', () {
    expect(
      analyticsDestination(
        Uri.parse(
          'https://play.google.com/store/apps/details?id=uk.example.app&ref=x',
        ),
      ),
      'https://play.google.com/store/apps/details?id=uk.example.app',
    );
  });

  test('contact destinations never contain the address or number', () {
    expect(
      analyticsDestination(Uri.parse('mailto:private@example.com')),
      'email',
    );
    expect(analyticsDestination(Uri.parse('tel:+441234567890')), 'phone');
  });

  test('credentials and unsupported schemes are not reportable', () {
    expect(
      analyticsDestination(Uri.parse('https://user:pass@example.com/path')),
      isNull,
    );
    expect(analyticsDestination(Uri.parse('data:text/plain,secret')), isNull);
  });
}
