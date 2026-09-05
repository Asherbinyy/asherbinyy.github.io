import 'dart:js_interop';

@JS('window.location.assign')
external void _assign(String url);

/// Leaves the Flutter app entirely for a statically served path.
void open(String path) => _assign(path);
