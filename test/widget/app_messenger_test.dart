import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/app.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/platform/app_messenger.dart';
import 'package:nocturne/core/platform/message_surface.dart';
import 'package:nocturne/core/platform/platform_provider.dart';
import 'package:nocturne/core/platform/pointer_capabilities.dart';
import 'package:nocturne/core/widgets/placeholder_screen.dart';

const _pointer = PointerCapabilities(canHover: true, hasFinePointer: true);
const _touch = PointerCapabilities(hasCoarsePointer: true);

Future<void> _showMessage(
  WidgetTester tester,
  PointerCapabilities capabilities,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        platformCapabilitiesProvider.overrideWith(
          () => _Capabilities(capabilities),
        ),
      ],
      child: const NocturneApp(),
    ),
  );
  await tester.pumpAndSettle();
  final context = tester.element(find.byType(PlaceholderScreen));
  AppMessenger.of(context)
      .show('Fixture message', closeLabel: 'Dismiss fixture');
  await tester.pump();
}

/// Whether keyboard focus currently rests inside the message's close button.
bool _closeButtonHasFocus() {
  final focused = FocusManager.instance.primaryFocus?.context;
  return focused?.findAncestorWidgetOfExactType<TextButton>() != null;
}

void main() {
  testWidgets('pointer toast occupies the upper trailing corner and closes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _showMessage(tester, _pointer);
    final screen = tester.getRect(find.byType(Scaffold));
    final message = tester.getRect(find.byType(MessageSurface));

    expect(message.top, screen.top + Tokens.space16);
    expect(message.right, screen.right - Tokens.space16);
    expect(find.bySemanticsLabel('Dismiss fixture'), findsOneWidget);
    await tester.tap(find.text('Dismiss fixture'));
    await tester.pump();
    expect(find.byType(MessageSurface), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('touch snackbar occupies the bottom and swipes away', (
    tester,
  ) async {
    await _showMessage(tester, _touch);
    final screen = tester.getRect(find.byType(Scaffold));
    final message = tester.getRect(find.byType(MessageSurface));

    expect(message.bottom, screen.bottom - Tokens.space16);
    await tester.drag(
      find.byType(MessageSurface),
      const Offset(Tokens.zero, Tokens.space128),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MessageSurface), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hovering over a pointer toast prevents timeout', (tester) async {
    await _showMessage(tester, _pointer);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(MessageSurface)));
    await tester.pump(Tokens.messageLifetime * 2);

    expect(find.byType(MessageSurface), findsOneWidget);
    await gesture.moveTo(Offset.zero);
    await tester.pump(Tokens.messageLifetime);
    expect(find.byType(MessageSurface), findsNothing);
  });

  testWidgets('keyboard focus persists and exposes a beacon border', (
    tester,
  ) async {
    await _showMessage(tester, _pointer);
    // The global chrome now sits ahead of the message in the traversal order,
    // so tab until the close button holds focus. That still proves keyboard
    // reachability without pinning the test to chrome's control count.
    var guard = 0;
    while (guard++ < 32 && !_closeButtonHasFocus()) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump(Tokens.quick);
    }
    final button = tester.widget<TextButton>(find.byType(TextButton));
    final context = tester.element(find.byType(TextButton));

    expect(_closeButtonHasFocus(), isTrue);
    expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);
    expect(
      button.style?.side?.resolve({WidgetState.focused})?.color,
      context.tokens.beacon,
    );
    await tester.pump(Tokens.messageLifetime * 2);
    expect(find.byType(MessageSurface), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.byType(MessageSurface), findsNothing);
  });
}

class _Capabilities extends PlatformCapabilities {
  _Capabilities(this.capabilities);
  final PointerCapabilities capabilities;

  @override
  Stream<PointerCapabilities> build() => Stream.value(capabilities);
}
