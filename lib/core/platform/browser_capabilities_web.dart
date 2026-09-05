import 'dart:async';
import 'dart:js_interop';

import 'package:nocturne/core/platform/pointer_capabilities.dart';

@JS('window.matchMedia')
external _MediaQueryList _matchMedia(String query);

extension type _MediaQueryList(JSObject _) implements JSObject {
  external bool get matches;
  external void addEventListener(String type, JSFunction listener);
  external void removeEventListener(String type, JSFunction listener);
}

/// Only capability booleans cross this boundary, never user agent data.
Stream<PointerCapabilities> observe() {
  final hover = _matchMedia('(hover: hover)');
  final fine = _matchMedia('(pointer: fine)');
  final coarse = _matchMedia('(pointer: coarse)');
  late final StreamController<PointerCapabilities> controller;
  void emit() => controller.add(
    PointerCapabilities(
      canHover: hover.matches,
      hasFinePointer: fine.matches,
      hasCoarsePointer: coarse.matches,
    ),
  );
  final listener = ((JSAny? event) => emit()).toJS;
  controller = StreamController<PointerCapabilities>(
    onListen: () {
      for (final query in [hover, fine, coarse]) {
        query.addEventListener('change', listener);
      }
      emit();
    },
    onCancel: () {
      for (final query in [hover, fine, coarse]) {
        query.removeEventListener('change', listener);
      }
    },
  );
  return controller.stream;
}
