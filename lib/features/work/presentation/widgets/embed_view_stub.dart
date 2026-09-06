import 'package:material_ui/material_ui.dart';

/// Stands in for the frame off the web target, where no browser exists.
///
/// Every widget test runs on the VM, so this is what they see. It returns a
/// sized placeholder rather than throwing, which keeps the case study
/// renderable under test without pretending a frame loaded.
Widget buildEmbed({required Uri url, required String title}) {
  // Named to match the web implementation's signature; neither is used here.
  assert(url.isAbsolute, 'An embed needs an absolute URL');
  return const SizedBox.expand();
}
