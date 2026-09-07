import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/widgets/loading/carrier_empty_state.dart';
import 'package:nocturne/core/widgets/loading/carrier_loader.dart';
import 'package:nocturne/core/widgets/loading/skeleton_text.dart';
import 'package:nocturne/core/widgets/loading/station_card.dart';
import 'package:nocturne/core/widgets/loading/three_stage_image.dart';

import '../../support/loading_harness.dart';

/// A one-pixel PNG, the smallest thing that decodes successfully.
final Uint8List _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAE'
  'hQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// Bytes that are not an image, so the provider fails rather than decodes.
final Uint8List _corrupt = Uint8List.fromList(List.filled(8, 0));

/// Drives [provider] to a resolved or failed state on the real event loop.
///
/// `pumpAndSettle` runs the test clock, which does not advance image decoding,
/// so waiting on the provider directly is the only way to make these
/// assertions independent of decode timing.
Future<void> _settleImage(
  WidgetTester tester,
  ImageProvider<Object> provider,
) async {
  await tester.runAsync(() {
    final completer = Completer<void>();
    void finish() {
      if (!completer.isCompleted) completer.complete();
    }

    provider
        .resolve(ImageConfiguration.empty)
        .addListener(
          ImageStreamListener((_, _) => finish(), onError: (_, _) => finish()),
        );
    return completer.future;
  });
  await tester.pumpAndSettle();
}

void main() {
  group('carrier loader', () {
    testWidgets('occupies the specified 32x12 footprint', (tester) async {
      await tester.pumpWidget(const LoadingHarness(child: CarrierLoader()));

      expect(
        tester.getSize(find.byType(CarrierLoader)),
        const Size(Tokens.loaderWidth, Tokens.loaderHeight),
      );

      await tester.pumpWidget(const LoadingHarness(child: SizedBox.shrink()));
    });

    testWidgets('announces itself as a live region', (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(const LoadingHarness(child: CarrierLoader()));

      expect(find.bySemanticsLabel('Loading'), findsOneWidget);

      await tester.pumpWidget(const LoadingHarness(child: SizedBox.shrink()));
      semantics.dispose();
    });

    testWidgets('announces in Arabic when the locale is Arabic', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        const LoadingHarness(language: 'ar', child: CarrierLoader()),
      );

      expect(find.bySemanticsLabel('جارٍ التحميل'), findsOneWidget);

      await tester.pumpWidget(const LoadingHarness(child: SizedBox.shrink()));
      semantics.dispose();
    });

    testWidgets('uses no spinner', (tester) async {
      await tester.pumpWidget(const LoadingHarness(child: CarrierLoader()));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);

      await tester.pumpWidget(const LoadingHarness(child: SizedBox.shrink()));
    });

    testWidgets('renders static under reduced motion', (tester) async {
      await tester.pumpWidget(
        const LoadingHarness(reducedMotion: true, child: CarrierLoader()),
      );

      // A repeating oscillation would never settle.
      await tester.pumpAndSettle();
      expect(find.byType(CarrierLoader), findsOneWidget);
    });
  });

  group('empty state', () {
    testWidgets('shows the carrier at rest and a line of direction', (
      tester,
    ) async {
      await tester.pumpWidget(
        const LoadingHarness(
          child: SizedBox(
            width: 320,
            child: CarrierEmptyState(direction: 'Widen the filter'),
          ),
        ),
      );

      expect(find.text('Widen the filter'), findsOneWidget);
      // Nothing is in progress, so it must settle with no pending frames.
      await tester.pumpAndSettle();
    });

    testWidgets('uses no spinner', (tester) async {
      await tester.pumpWidget(
        const LoadingHarness(
          child: CarrierEmptyState(direction: 'Widen the filter'),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('skeleton text', () {
    testWidgets('matches the line box height of the style it stands in for', (
      tester,
    ) async {
      const style = TextStyle(fontSize: 16, height: 1.6);

      await tester.pumpWidget(
        const LoadingHarness(
          child: SizedBox(
            width: 400,
            child: SkeletonText(lines: 3, style: style),
          ),
        ),
      );

      expect(tester.getSize(find.byType(SkeletonText)).height, 16 * 1.6 * 3);
    });

    testWidgets('rules stop short of the full measure', (tester) async {
      await tester.pumpWidget(
        const LoadingHarness(
          child: SizedBox(
            width: 400,
            child: SkeletonText(
              lines: 1,
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
          ),
        ),
      );

      final rule = tester.getSize(find.byType(FractionallySizedBox));
      expect(rule.width, 400 * Tokens.skeletonTextFraction);
      expect(rule.height, Tokens.hairlineWidth);
    });
  });

  group('station card', () {
    testWidgets('renders the name without a recorded country', (tester) async {
      await tester.pumpWidget(
        const LoadingHarness(
          child: StationCard(
            seedId: 'mokaf',
            name: 'Mokaf',
            width: 320,
            height: 200,
            domainLabel: 'Mobility',
          ),
        ),
      );

      expect(find.text('Mokaf'), findsOneWidget);
      expect(find.text('Mobility'), findsOneWidget);
      expect(tester.getSize(find.byType(StationCard)), const Size(320, 200));
    });

    testWidgets('a name long enough to wrap never overflows its card', (
      tester,
    ) async {
      // The label draws up to two lines, and the height threshold that decides
      // whether to draw it at all reserved one. Every card between the two
      // overflowed the moment a name wrapped -- latent from milestone 1 until
      // the interests grid landed on it at 104px in milestone 4.
      //
      // Swept rather than pinned to the one height that failed: the threshold
      // is computed from a fluid type scale, so the band that breaks moves
      // with the viewport and a single sample would miss it again.
      for (var height = 40.0; height <= 240.0; height += 4) {
        await tester.pumpWidget(
          LoadingHarness(
            child: StationCard(
              seedId: 'wrapping',
              name: 'A name quite long enough to need two lines',
              width: 168,
              height: height,
            ),
          ),
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'overflowed at ${height}px',
        );
      }
    });

    testWidgets('renders the country when the content records one', (
      tester,
    ) async {
      await tester.pumpWidget(
        const LoadingHarness(
          child: StationCard(
            seedId: 'az-courses',
            name: 'AZ Courses',
            width: 320,
            height: 200,
            domainLabel: 'Education',
            country: 'EG',
            latitude: 31.0409,
            longitude: 31.3785,
          ),
        ),
      );

      expect(find.text('EG'), findsOneWidget);
      expect(find.text('Education'), findsOneWidget);
    });
  });

  group('three-stage image', () {
    // A warm image cache resolves synchronously, which would skip the
    // placeholder and sweep stages this group is about.
    setUp(() {
      imageCache
        ..clear()
        ..clearLiveImages();
    });

    testWidgets('declares its dimensions before anything loads', (
      tester,
    ) async {
      await tester.pumpWidget(
        LoadingHarness(
          child: ThreeStageImage(
            image: MemoryImage(_pixel),
            width: 320,
            height: 200,
            fallback: const SizedBox.shrink(),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(ThreeStageImage)),
        const Size(320, 200),
      );
    });

    testWidgets('announces the image while it resolves', (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        LoadingHarness(
          child: ThreeStageImage(
            image: MemoryImage(_pixel),
            width: 320,
            height: 200,
            fallback: const SizedBox.shrink(),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Loading image'), findsOneWidget);

      semantics.dispose();
    });

    testWidgets('cross-fades to the sharp image once it resolves', (
      tester,
    ) async {
      final provider = MemoryImage(_pixel);

      await tester.pumpWidget(
        LoadingHarness(
          child: ThreeStageImage(
            image: provider,
            width: 320,
            height: 200,
            fallback: const SizedBox.shrink(),
            semanticLabel: 'Fixture screenshot',
          ),
        ),
      );
      await _settleImage(tester, provider);

      final fade = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(fade.opacity, 1);
      expect(fade.duration, Tokens.imageResolve);
    });

    testWidgets('falls back to its station card when the image fails', (
      tester,
    ) async {
      final provider = MemoryImage(_corrupt);

      await tester.pumpWidget(
        LoadingHarness(
          child: ThreeStageImage(
            image: provider,
            width: 320,
            height: 200,
            fallback: const StationCard(
              seedId: 'mokaf',
              name: 'Mokaf',
              width: 320,
              height: 200,
            ),
          ),
        ),
      );
      await _settleImage(tester, provider);

      expect(find.byType(StationCard), findsOneWidget);
      expect(find.text('Mokaf'), findsOneWidget);
    });

    testWidgets('settles instantly under reduced motion', (tester) async {
      final provider = MemoryImage(_pixel);

      await tester.pumpWidget(
        LoadingHarness(
          reducedMotion: true,
          child: ThreeStageImage(
            image: provider,
            width: 320,
            height: 200,
            fallback: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fade = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(fade.duration, Duration.zero);
    });
  });
}
