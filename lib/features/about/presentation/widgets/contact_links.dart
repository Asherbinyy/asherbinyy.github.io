import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';

/// The owner's public destinations, in the order a recruiter uses them.
///
/// Names are the platforms' own and are deliberately not translated: "GitHub"
/// is GitHub in both channels, and localising a proper noun would make the
/// link harder to recognise, not easier.
///
/// Only links the content actually supplies are rendered. Nothing here is
/// inferred from a username or guessed from a pattern. WhatsApp is the one
/// derived destination and it is derived from the published phone number
/// rather than from a guess: it is the same number, reached a different way,
/// and the owner asked for it by name.
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
      if (_whatsApp(contact.phone) case final url?) ('WhatsApp', url),
      ('Email', Uri(scheme: 'mailto', path: contact.email)),
    ];

    return Wrap(
      spacing: context.tokens.space12,
      runSpacing: context.tokens.space12,
      children: [
        for (final (name, url) in destinations)
          _ContactLink(name: name, url: url),
      ],
    );
  }

  /// A chat link for the number the content already publishes.
  ///
  /// `wa.me` wants the number with no plus and no separators; anything else is
  /// left alone rather than reformatted into something that might not dial.
  static Uri? _whatsApp(String? phone) {
    if (phone == null) return null;
    final digits = phone.replaceAll(RegExp('[^0-9]'), '');
    if (digits.isEmpty) return null;
    return Uri.https('wa.me', '/$digits');
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
              // A card that lights rather than a word that changes colour.
              // The owner asked for one per platform with a glow on it; the
              // glow is the site's own gold, thrown softly behind the card,
              // so it reads as the same lamp that lights the wall rather than
              // as a web button with a shadow.
              child: AnimatedContainer(
                duration: ReducedMotion.duration(context, Motion.quick),
                curve: MotionCurves.emphasized,
                constraints: BoxConstraints(
                  minHeight: context.platform.minimumTarget,
                  minWidth: Tokens.contactCardWidth,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.space16,
                  vertical: tokens.space12,
                ),
                decoration: BoxDecoration(
                  color: isHovered ? tokens.surfaceRaised : tokens.surface,
                  borderRadius: BorderRadius.circular(tokens.controlRadius),
                  border: Border.all(
                    color: isHovered ? tokens.beacon : tokens.hairline,
                    width: tokens.hairlineWidth,
                  ),
                  boxShadow: isHovered
                      ? [
                          BoxShadow(
                            color: tokens.beacon.withValues(
                              alpha: Tokens.contactGlowAlpha,
                            ),
                            blurRadius: Tokens.contactGlowBlur,
                          ),
                        ]
                      : null,
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
