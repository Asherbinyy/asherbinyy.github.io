import 'package:material_ui/material_ui.dart';

import 'package:nocturne/features/work/presentation/widgets/embed_view_stub.dart'
    if (dart.library.js_interop) 'package:nocturne/features/work/presentation/widgets/embed_view_web.dart'
    as platform;

/// A third-party page embedded in the site, once the viewer has asked for it.
///
/// Only ever built by `PrototypeEmbed` after an explicit press, so nothing
/// third-party is requested on first paint. On the VM target — every widget
/// test — this renders a labelled stand-in rather than a frame, because there
/// is no browser to host one and a test should not pretend otherwise.
class EmbedView extends StatelessWidget {
  /// [url] must be absolute HTTPS; [title] is the frame's accessible name.
  const EmbedView({required this.url, required this.title, super.key});

  /// The embedded page.
  final Uri url;

  /// Accessible name, announced in place of the frame's contents.
  final String title;

  @override
  Widget build(BuildContext context) => Semantics(
    label: title,
    child: platform.buildEmbed(url: url, title: title),
  );
}
