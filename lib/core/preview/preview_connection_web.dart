import 'dart:js_interop';

import 'package:nocturne/core/preview/preview_transport.dart';

@JS('Object.is')
external bool _same(JSAny? left, JSAny? right);

@JS('window')
external _Window get _window;

extension type _Window(JSObject _) implements JSObject {
  external _Window get parent;
  external void addEventListener(String type, JSFunction listener);
  external void removeEventListener(String type, JSFunction listener);
  external void postMessage(JSAny? message, String targetOrigin);
}

extension type _Message(JSObject _) implements JSObject {
  external String get origin;
  external JSAny? get data;
  external _Window? get source;
}

/// No user-supplied origin can enable the bridge. The build owns the allowlist.
PreviewTransport? create() {
  const allowed = String.fromEnvironment('ADMIN_PREVIEW_ORIGIN');
  final origin = Uri.tryParse(allowed);
  final query = Uri.base.queryParameters;
  final session = query['session'] ?? '';
  if (allowed.isEmpty ||
      origin == null ||
      !{'https', 'http'}.contains(origin.scheme) ||
      origin.host.isEmpty ||
      origin.origin != allowed ||
      (origin.scheme == 'http' &&
          !{'localhost', '127.0.0.1'}.contains(origin.host)) ||
      query['preview'] != '1' ||
      !RegExp(r'^[a-f0-9]{32}$').hasMatch(session) ||
      _same(_window.parent, _window)) {
    return null;
  }
  return _BrowserPreview(allowed, session);
}

class _BrowserPreview implements PreviewTransport {
  _BrowserPreview(this.origin, this.session);
  final String origin;
  final String session;
  JSFunction? _listener;

  @override
  void listen(void Function(Map<String, dynamic>) receive) {
    _listener = ((_Message event) {
      if (event.origin != origin || !_same(event.source, _window.parent)) {
        return;
      }
      try {
        final data = event.data.dartify();
        if (data is! Map) return;
        final message = Map<String, dynamic>.from(data);
        if (message['channel'] != 'portfolio-preview' ||
            message['version'] != 1 ||
            message['sessionId'] != session) {
          return;
        }
        receive(message);
      } on Object {
        // Untrusted messages never affect the rendered draft.
      }
    }).toJS;
    _window.addEventListener('message', _listener!);
  }

  @override
  void send(String type, Map<String, dynamic> payload) {
    _window.parent.postMessage(
      {
        'channel': 'portfolio-preview',
        'version': 1,
        'sessionId': session,
        'type': type,
        'payload': payload,
      }.jsify(),
      origin,
    );
  }

  @override
  void dispose() {
    if (_listener case final listener?) {
      _window.removeEventListener('message', listener);
    }
  }
}
