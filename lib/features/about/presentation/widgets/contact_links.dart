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
  /// Reads the destinations from [contact].
  const ContactLinks({required this.contact, super.key});

  /// Supplied contact block.
  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final destinations = <(String, Uri)>[
      // Linktree first: it is the one page that collects the rest, so a reader
      // who wants "everything" needs exactly one click.
      if (contact.linktree case final url?) ('Linktree', url),
      if (contact.linkedin case final url?) ('LinkedIn', url),
      if (contact.github case final url?) ('GitHub', url),
      if (contact.gitlab case final url?) ('GitLab', url),
      if (contact.medium case final url?) ('Medium', url),
      ('Email', Uri(scheme: 'mailto', path: contact.email)),
    ];

    return Wrap(
      spacing: context.tokens.space16,
      runSpacing: context.tokens.space8,
      children: [
        for (final (name, url) in destinations)
          _ContactLink(name: name, url: url),
      ],
    );
  }
}

class _ContactLink extends StatefulWidget {
  const _ContactLink({required this.name, required this.url});

  final String name;
  final Uri url;

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
                    child: Text(
                      widget.name,
                      style: context.type.body.copyWith(
                        color: isHovered ? tokens.beaconGlow : tokens.beacon,
                      ),
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
