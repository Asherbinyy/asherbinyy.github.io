import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/content_media.dart';
import 'package:nocturne/content/models/gallery.dart';

/// Supplied media only. External video opens after an explicit press.
class ContentGallery extends StatelessWidget {
  /// Uses the supplied page/item name as the gallery label.
  const ContentGallery({required this.entries, required this.label, super.key});

  /// Owner-supplied media in source order.
  final List<GalleryEntry> entries;

  /// Name of the project or interest.
  final String label;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return TextButton.icon(
      icon: const Icon(Icons.photo_library_outlined),
      label: Text(label),
      onPressed: () => unawaited(
        showDialog<void>(
          context: context,
          builder: (context) => _GalleryDialog(entries: entries, label: label),
        ),
      ),
    );
  }
}

class _GalleryDialog extends StatelessWidget {
  const _GalleryDialog({required this.entries, required this.label});
  final List<GalleryEntry> entries;
  final String label;

  @override
  Widget build(BuildContext context) => Dialog(
    child: Padding(
      padding: EdgeInsets.all(context.tokens.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: context.type.heading)),
              const CloseButton(),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final entry in entries)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: context.tokens.space16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          switch (entry.kind) {
                            GalleryKind.image => Image(
                              image: contentImage(context, entry.image!),
                              semanticLabel: entry.alt.resolve(context.channel),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stack) =>
                                  Text(entry.alt.resolve(context.channel)),
                            ),
                            GalleryKind.video => TextButton.icon(
                              onPressed: () => unawaited(
                                launchUrl(
                                  entry.url!,
                                  mode: LaunchMode.externalApplication,
                                ),
                              ),
                              icon: const Icon(Icons.open_in_new),
                              label: Text(entry.alt.resolve(context.channel)),
                            ),
                          },
                          if (entry.caption case final caption?)
                            Text(
                              caption.resolve(context.channel),
                              style: context.type.body,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
