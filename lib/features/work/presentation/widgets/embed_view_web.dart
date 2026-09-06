import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:material_ui/material_ui.dart';

@JS('document.createElement')
external JSObject _createElement(String tag);

/// View types already registered, so a rebuild does not re-register a factory.
final Set<String> _registered = {};

/// Builds a sandboxed iframe for [url].
///
/// Written against `dart:js_interop` rather than the `web` package because
/// `03-ARCHITECTURE.md` §4 fixes the dependency list, and this is the same
/// approach `browser_analytics_context_web.dart` already takes.
///
/// The sandbox is deliberately narrow. The prototype needs scripts to run and
/// its own origin to keep state, and nothing else: without `allow-scripts` it
/// would not run, and without `allow-same-origin` it could not store anything.
/// Top-level navigation, popups, form submission and downloads all stay off,
/// so an embedded page cannot take the viewer somewhere they did not choose to
/// go. `no-referrer` means the prototype's host is not told which page framed
/// it.
Widget buildEmbed({required Uri url, required String title}) {
  final viewType = 'nocturne-embed-${url.hashCode}';
  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final frame = _createElement('iframe')
        ..setProperty('src'.toJS, url.toString().toJS)
        ..setProperty('title'.toJS, title.toJS)
        ..setProperty('loading'.toJS, 'lazy'.toJS)
        ..setProperty('referrerPolicy'.toJS, 'no-referrer'.toJS)
        ..callMethodVarArgs('setAttribute'.toJS, [
          'sandbox'.toJS,
          'allow-scripts allow-same-origin'.toJS,
        ]);
      (frame.getProperty('style'.toJS)! as JSObject)
        ..setProperty('border'.toJS, 'none'.toJS)
        ..setProperty('width'.toJS, '100%'.toJS)
        ..setProperty('height'.toJS, '100%'.toJS);
      return frame;
    });
  }
  return HtmlElementView(viewType: viewType);
}
