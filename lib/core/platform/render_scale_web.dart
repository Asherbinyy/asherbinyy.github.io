import 'dart:js_interop';

@JS('window.__ascentCapDpr')
external void _capDpr(double cap);

@JS('window.__ascentRestoreDpr')
external void _restoreDpr();

/// Calls the shim installed in `web/index.html`.
void capDevicePixelRatio(double cap) => _capDpr(cap);

/// Calls the shim installed in `web/index.html`.
void restoreDevicePixelRatio() => _restoreDpr();
