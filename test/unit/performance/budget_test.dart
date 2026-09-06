@Tags(['performance'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Roadmap 3.2: the budgets in `03-ARCHITECTURE.md` §5, measured rather than
/// asserted in prose.
///
/// Only the budgets that can be measured from build artifacts live here. Frame
/// costs for the trace and the map need a real browser profile and are tracked
/// separately in `docs/11-OPEN-ISSUES.md`.
void main() {
  final root = Directory.current.path;

  group('bundled fonts', () {
    final faces = Directory('$root/assets/fonts')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('-subset.ttf'));

    test('every shipped face is a subset, never a full family', () {
      // A full IBM Plex Sans Arabic is roughly 500KB on its own; shipping one
      // by accident is the failure mode this catches.
      for (final face in faces) {
        expect(
          face.lengthSync(),
          lessThan(220 * 1024),
          reason: '${face.path} looks unsubset',
        );
      }
    });

    test('the Latin faces stay inside their share of the budget', () {
      final latin = faces
          .where((f) => !f.path.contains('Arabic'))
          .fold(0, (total, f) => total + f.lengthSync());

      expect(latin, lessThanOrEqualTo(280 * 1024));
    });

    test('total weight does not creep back up', () {
      final total = faces.fold(0, (sum, f) => sum + f.lengthSync());

      // **This is a regression guard, not the budget.** §5 sets 480KB and the
      // bundle is about 556KB: three Arabic weights cannot fit beside seven
      // Latin faces at that figure. Dropping the presentation-form and
      // extended blocks took 794KB to 556KB, and closing the rest means either
      // shipping two Arabic weights instead of three or revising the budget —
      // a typography decision, recorded as open issue 3.12 rather than made
      // here. This bound stops the saving being quietly undone in the
      // meantime.
      expect(total, lessThanOrEqualTo(580 * 1024));
    });
  });

  group('images', () {
    test('no bundled image exceeds 180KB', () {
      final images = Directory('$root/web')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith('.png') ||
                f.path.endsWith('.webp') ||
                f.path.endsWith('.jpg'),
          );

      for (final image in images) {
        expect(
          image.lengthSync(),
          lessThanOrEqualTo(180 * 1024),
          reason: image.path,
        );
      }
    });
  });
}
