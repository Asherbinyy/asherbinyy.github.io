import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/content/models/localized_text.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/painting/papyrus_roll_painter.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/platform/pointer_capabilities.dart';
import 'package:nocturne/features/station/presentation/widgets/papyrus_stat_panel.dart';

import '../../support/loading_harness.dart';

/// The owner asked for a scroll that rolls closed on a click and opens again
/// when the pointer leaves or on a second click. All three are behaviour, so
/// all three are tested rather than left to a screenshot.
void main() {
  const stat = ProfileStat(
    value: '5+',
    label: LocalizedText(en: 'years experience'),
  );

  /// How far the sheet is wound, read off the painter that draws it.
  double rollOf(WidgetTester tester) {
    final paints = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where((paint) => paint.painter is PapyrusRollPainter);
    expect(paints, isNotEmpty, reason: 'the roll painter should be mounted');
    return (paints.first.painter! as PapyrusRollPainter).roll;
  }

  Future<void> pumpCard(WidgetTester tester, {bool reducedMotion = false}) =>
      tester.pumpWidget(
        LoadingHarness(
          reducedMotion: reducedMotion,
          // A pointer machine: the card asks the platform whether to show a
          // click cursor, and the pointer-exit rule only exists there.
          child: const PlatformScope(
            service: PlatformService(
              capabilities: PointerCapabilities(
                canHover: true,
                hasFinePointer: true,
              ),
              viewportWidth: 800,
            ),
            child: PapyrusStatPanel(stat: stat, locale: AppLocale.english),
          ),
        ),
      );

  testWidgets('a sheet starts flat and readable', (tester) async {
    await pumpCard(tester);
    expect(rollOf(tester), 0);
    expect(find.text('5+'), findsOneWidget);
  });

  testWidgets('a click rolls it closed', (tester) async {
    await pumpCard(tester);
    await tester.tap(find.byType(PapyrusStatPanel));
    await tester.pumpAndSettle();
    expect(rollOf(tester), 1);
  });

  testWidgets('a second click opens it again', (tester) async {
    await pumpCard(tester);
    await tester.tap(find.byType(PapyrusStatPanel));
    await tester.pumpAndSettle();
    expect(rollOf(tester), 1);

    // Touch has no pointer to leave, so this is the only way back there.
    await tester.tap(find.byType(PapyrusStatPanel));
    await tester.pumpAndSettle();
    expect(rollOf(tester), 0);
  });

  testWidgets('the pointer leaving opens it again', (tester) async {
    await pumpCard(tester);
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    final centre = tester.getCenter(find.byType(PapyrusStatPanel));

    await tester.sendEventToBinding(pointer.hover(centre));
    await tester.pump();
    await tester.tap(find.byType(PapyrusStatPanel));
    await tester.pumpAndSettle();
    expect(rollOf(tester), 1);

    // Off the card. A sheet rolled shut hides the control that would reopen
    // it, so this is what stops it being a trap.
    await tester.sendEventToBinding(pointer.hover(const Offset(2000, 2000)));
    await tester.pumpAndSettle();
    expect(rollOf(tester), 0);
  });

  testWidgets('reduced motion still rolls, without the travel', (tester) async {
    // The state is information. Removing it would leave the card with no
    // interaction at all, which is not what reduced motion asks for.
    await pumpCard(tester, reducedMotion: true);
    await tester.tap(find.byType(PapyrusStatPanel));
    await tester.pump();
    expect(rollOf(tester), 1);

    await tester.tap(find.byType(PapyrusStatPanel));
    await tester.pump();
    expect(rollOf(tester), 0);
  });

  testWidgets('the figure is announced with the way to roll it', (
    tester,
  ) async {
    await pumpCard(tester);
    final node = tester.getSemantics(find.byType(PapyrusStatPanel).first);
    expect(node.label, contains('5+'));
    expect(node.label, contains('years experience'));
  });
}
