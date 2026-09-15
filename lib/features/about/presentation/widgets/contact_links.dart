import 'package:nocturne/content/content_media.dart';

import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';

/// The owner's public destinations, in the order a recruiter uses them.
///
/// Names are the platforms' own and are deliberately not translated: "GitHub"
/// is GitHub in both channels, and localising a proper noun would make the
/// link harder to recognise, not easier.
///
/// Only links the content actually supplies are rendered. Nothing here is
/// inferred from a username or guessed from a pattern.
class ContactLinks extends StatelessWidget {
  /// Reads flexible links, falling back to the fixed contact destinations.
  const ContactLinks({required this.contact, this.links = const [], super.key});

  /// Supplied contact block.
  final Contact contact;

  /// Flexible links replace fixed destinations when supplied.
  final List<ProfileLink> links;

  @override
  Widget build(BuildContext context) {
    final destinations = links.isNotEmpty
        ? [
            for (final link in links)
              (link.label.resolve(context.channel), link.url, link.icon),
          ]
        : <(String, Uri, String?)>[
            // Linktree collects the remaining destinations.
            if (contact.linktree case final url?) ('Linktree', url, null),
            if (contact.linkedin case final url?) ('LinkedIn', url, null),
            if (contact.github case final url?) ('GitHub', url, null),
            if (contact.gitlab case final url?) ('GitLab', url, null),
            if (contact.medium case final url?) ('Medium', url, null),
            ('Email', Uri(scheme: 'mailto', path: contact.email), null),
          ];

    return Wrap(
      spacing: context.tokens.space16,
      runSpacing: context.tokens.space8,
      children: [
        for (final (name, url, icon) in destinations)
          _ContactLink(name: name, url: url, icon: icon),
      ],
    );
  }
}

class _ContactLink extends StatefulWidget {
  const _ContactLink({required this.name, required this.url, this.icon});

  final String name;
  final Uri url;
  final String? icon;

  @override
  State<_ContactLink> createState() => _ContactLinkState();
}

class _ContactLinkState extends State<_ContactLink> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      link: true,
      label: context.l10n.aboutOpenLink(widget.name),
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) {
          final isHovered = _states.value.contains(WidgetState.hovered);
          return FocusRing(
            isFocused: _states.value.contains(WidgetState.focused),
            child: InkWell(
              onTap: () => unawaited(
                launchUrl(widget.url, mode: LaunchMode.externalApplication),
              ),
              statesController: _states,
              borderRadius: BorderRadius.circular(tokens.controlRadius),
              hoverColor: Colors.transparent,
              mouseCursor: context.platform.isPointer
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: context.platform.minimumTarget,
                ),
                child: Center(
                  widthFactor: 1,
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon case final icon?) ...[
                          Image(
                            image: contentImage(context, icon),
                            width: tokens.space24,
                            height: tokens.space24,
                            errorBuilder: (context, error, stack) =>
                                const Icon(Icons.link),
                          ),
                          SizedBox(width: tokens.space8),
                        ],
                        Text(
                          widget.name,
                          style: context.type.body.copyWith(
                            color: isHovered
                                ? tokens.beaconGlow
                                : tokens.beacon,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
