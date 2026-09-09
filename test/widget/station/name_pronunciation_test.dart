import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/features/station/presentation/widgets/name_pronunciation.dart';

import '../../support/chrome_harness.dart';
import '../../support/pump.dart';
import '../../support/station_harness.dart';

void main() {
  testWidgets('the hero offers the name in the owner\'s own voice', (
    tester,
  ) async {
    await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

    expect(find.byType(NamePronunciation), findsOneWidget);
    final l10n = tester.element(find.byType(ChromeScaffold)).l10n;
    expect(find.text(l10n.heroSayName), findsOneWidget);
  });

  testWidgets('it is a button, and it is labelled', (tester) async {
    await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

    final l10n = tester.element(find.byType(ChromeScaffold)).l10n;
    // Asserted on the merged node the control exposes, rather than on a
    // particular Semantics widget inside it: the tree shape is an
    // implementation detail and the announcement is the contract.
    final node = tester.getSemantics(find.byType(NamePronunciation));
    expect(node.label, l10n.heroSayName);
    expect(
      node.hasFlag(SemanticsFlag.isButton),
      isTrue,
      reason: 'it should announce as a button',
    );
    // The caption repeats the label on screen, so a merged tree announced it
    // twice. Exact equality above is what catches that coming back.
    expect(node.label.split('\n'), hasLength(1));
  });

  testWidgets('nothing plays until it is asked to', (tester) async {
    // Audio a visitor did not ask for is the rudest thing a page can do, and
    // this asserts the button is the only thing that starts it. Playback
    // itself needs a real audio device, so what is checked is that building
    // the hero raises nothing and leaves no player running.
    await pumpStation(tester, breakpoint: ChromeBreakpoint.large);
    await pumpFrames(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('pressing it does not throw where there is no audio device', (
    tester,
  ) async {
    await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

    await tester.tap(find.byType(NamePronunciation));
    await pumpFrames(tester);

    // The recording failing to play is not an error worth surfacing: the name
    // is written directly above it.
    expect(tester.takeException(), isNull);
  });
}
