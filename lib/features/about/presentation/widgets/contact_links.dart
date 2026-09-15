import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:simple_icons/simple_icons.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/content/content_media.dart';
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
  const ContactLinks({
    required this.contact,
    this.includesBooking = true,
    this.links = const [],
    super.key,
  });

  /// Supplied contact block.
  final Contact contact;

  /// Owner-ordered destinations, replacing the fixed cards when supplied.
  final List<ProfileLink> links;

  /// Whether the booking link is one of the cards.
  ///
  /// False on the services page, which already carries it as the one loud
  /// control on the page: offering the same appointment twice, three inches
  /// apart, makes a visitor wonder whether they are different.
  final bool includesBooking;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (links.isNotEmpty) {
      return Wrap(
        spacing: tokens.space12,
        runSpacing: tokens.space12,
        children: [
          for (final link in links)
            _ContactLink(
              name: link.label.resolve(context.channel),
              icon: Icons.link,
              image: link.icon,
              url: link.url,
            ),
        ],
      );
    }

    // The two ways of reaching him, kept apart. The first is a message; the
    // rest are places to go and read. Mixing them made a row of eight
    // identical cards where the important one was third from the left.
    final direct = <(String, IconData, Uri)>[
      ('Email', SimpleIcons.gmail, Uri(scheme: 'mailto', path: contact.email)),
      if (contact.whatsapp ?? _whatsApp(contact.phone) case final url?)
        ('WhatsApp', SimpleIcons.whatsapp, url),
      if (includesBooking)
        if (contact.calendly case final url?)
          ('Book a call', SimpleIcons.calendly, url),
    ];

    final social = <(String, IconData, Uri)>[
      // Linktree first: it is the one page that collects the rest, so a reader
      // who wants "everything" needs exactly one click.
      if (contact.linktree case final url?)
        ('Linktree', SimpleIcons.linktree, url),
      // LinkedIn has no mark in the icon set -- the company had it withdrawn
      // -- and redrawing somebody's trademark by hand is not the answer. A
      // neutral link glyph carries it instead.
      if (contact.linkedin case final url?) ('LinkedIn', Icons.link, url),
      if (contact.github case final url?) ('GitHub', SimpleIcons.github, url),
      if (contact.gitlab case final url?) ('GitLab', SimpleIcons.gitlab, url),
      if (contact.medium case final url?) ('Medium', SimpleIcons.medium, url),
      if (contact.tiktok case final url?) ('TikTok', SimpleIcons.tiktok, url),
      if (contact.instagram case final url?)
        ('Instagram', SimpleIcons.instagram, url),
      if (contact.facebook case final url?)
        ('Facebook', SimpleIcons.facebook, url),
      // Fiverr is where somebody can actually hire him, so it sits with the
      // profiles rather than pretending to be a social account.
      if (contact.fiverr case final url?) ('Fiverr', SimpleIcons.fiverr, url),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Row(destinations: direct),
        if (social.isNotEmpty) ...[
          SizedBox(height: tokens.space24),
          _Label(text: context.l10n.contactSocial),
          SizedBox(height: tokens.space12),
          _Row(destinations: social),
        ],
      ],
    );
  }

  /// A chat link derived from the published phone number.
  ///
  /// Only a fallback now: the owner publishes a WhatsApp link of his own and
  /// it is a different number from the phone here, so `contact.whatsapp` wins
  /// wherever it is set. `wa.me` wants the number with no plus and no
  /// separators; anything else is left alone rather than reformatted into
  /// something that might not dial.
  static Uri? _whatsApp(String? phone) {
    if (phone == null) return null;
    final digits = phone.replaceAll(RegExp('[^0-9]'), '');
    if (digits.isEmpty) return null;
    return Uri.https('wa.me', '/$digits');
  }
}

/// One row of cards, wrapped.
class _Row extends StatelessWidget {
  const _Row({required this.destinations});

  final List<(String, IconData, Uri)> destinations;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: context.tokens.space12,
    runSpacing: context.tokens.space12,
    children: [
      for (final (name, icon, url) in destinations)
        _ContactLink(name: name, icon: icon, url: url),
    ],
  );
}

/// The quiet heading over a group of them.
class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: tokens.space16,
          height: tokens.hairlineWidth * 2,
          child: ColoredBox(color: tokens.instrumentDim),
        ),
        SizedBox(width: tokens.space8),
        Text(
          text,
          style: context.type.telemetryS.copyWith(color: tokens.textMuted),
        ),
      ],
    );
  }
}

class _ContactLink extends StatefulWidget {
  const _ContactLink({
    required this.name,
    required this.icon,
    required this.url,
    this.image,
  });

  final String name;
  final IconData icon;
  final Uri url;
  final String? image;

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
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.image case final image?)
                        Image(
                          image: contentImage(context, image),
                          width: Tokens.contactIconSize,
                          height: Tokens.contactIconSize,
                          errorBuilder: (context, error, stack) => Icon(
                            widget.icon,
                            size: Tokens.contactIconSize,
                            color: tokens.beacon,
                          ),
                        )
                      else
                        Icon(
                          widget.icon,
                          size: Tokens.contactIconSize,
                          color: isHovered ? tokens.beaconGlow : tokens.beacon,
                        ),
                      SizedBox(width: tokens.space12),
                      Text(
                        widget.name,
                        style: context.type.body.copyWith(
                          color: isHovered ? tokens.beaconGlow : tokens.beacon,
                        ),
                      ),
                    ],
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
