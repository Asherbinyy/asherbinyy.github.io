import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/core/painting/sign_paths.dart';
import 'package:nocturne/features/station/presentation/widgets/stop_mark.dart';

CareerRole _role({required String id, StopKind kind = StopKind.role}) =>
    CareerRole(
      id: id,
      country: 'GB',
      city: 'Manchester',
      coords: const [0, 0],
      start: '2020-01',
      kind: kind,
    );

void main() {
  group('the sign beside a career entry', () {
    test('study, employment and freelance are three different signs', () {
      final study = StopMark.signFor(_role(id: 'a', kind: StopKind.study));
      final role = StopMark.signFor(_role(id: 'b'));
      final freelance = StopMark.signFor(_role(id: 'freelance'));

      // The whole point of the mark is that a reader can tell them apart
      // without reading, so two of them sharing a sign is the failure.
      expect({study, role, freelance}, hasLength(3));
    });

    test('study gets the scribe and employment the pillar', () {
      expect(
        StopMark.signFor(_role(id: 'x', kind: StopKind.study)),
        Sign.seated,
      );
      expect(StopMark.signFor(_role(id: 'y')), Sign.djed);
    });

    test('freelance is decided by its id, not its kind', () {
      // The content gives freelance no separate kind: it is a role like the
      // others, with no company and no office.
      expect(StopMark.signFor(_role(id: 'freelance')), Sign.falcon);
    });

    test('every stop in the content gets a sign', () {
      for (final kind in StopKind.values) {
        expect(StopMark.signFor(_role(id: 'z', kind: kind)), isNotNull);
      }
    });
  });
}
