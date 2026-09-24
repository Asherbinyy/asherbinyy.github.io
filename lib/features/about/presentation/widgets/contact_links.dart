import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:simple_icons/simple_icons.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/content_media.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/widgets/even_grid.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';
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
      return EvenGrid(
        minTileWidth: Tokens.contactCardWidth,
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
    // Booking is deliberately not in this row. It was the third identical
    // card, which made "send a message" and "take an hour of his week" look
    // like the same size of decision -- and the owner asked for it to be its
    // own thing, after an "or".
    final direct = <(String, IconData, Uri)>[
      ('Email', SimpleIcons.gmail, Uri(scheme: 'mailto', path: contact.email)),
      if (contact.whatsapp ?? _whatsApp(contact.phone) case final url?)
        ('WhatsApp', SimpleIcons.whatsapp, url),
    ];
    final booking = includesBooking ? contact.calendly : null;

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

    // A phone had every destination as a full-width bar, fourteen of them
    // down the screen; the owner found it far too much. There the two ways to
    // message sit side by side and the profiles are small tiles, four across.
    final isCompact = context.platform.viewport == ViewportClass.compact;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Row(
          destinations: direct,
          minTileWidth: isCompact
              ? Tokens.contactCompactDirect
              : Tokens.contactCardWidth,
        ),
        if (booking != null) ...[
          SizedBox(height: tokens.space16),
          _Or(text: context.l10n.contactOr),
          SizedBox(height: tokens.space16),
          _BookingCard(url: booking),
        ],
        if (social.isNotEmpty) ...[
          SizedBox(height: tokens.space24),
          _Label(text: context.l10n.contactSocial),
          SizedBox(height: tokens.space12),
          // Narrower tiles than the two ways to message him: nine profiles in
          // two columns made the contact half of a panel twice the height of
          // the half beside it.
          _Row(
            destinations: social,
            minTileWidth: isCompact
                ? Tokens.contactCompactTile
                : Tokens.contactSocialWidth,
            isTile: isCompact,
          ),
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

/// The cards, in a grid rather than a wrap.
///
/// A `Wrap` sized each card to its own word, so "GitLab" and "Instagram" were
/// different widths and a line that fit eight left one stranded on the next —
/// which the owner reported as the social links looking unorganised. Equal
/// tiles, balanced rows.
class _Row extends StatelessWidget {
  const _Row({
    required this.destinations,
    this.minTileWidth = Tokens.contactCardWidth,
    this.isTile = false,
  });

  /// Drawn as small square tiles, mark over name, as on a phone.
  final bool isTile;

  final List<(String, IconData, Uri)> destinations;

  /// Wide enough for the longest of these words plus its mark, so a column
  /// is dropped before a name is ever squeezed.
  final double minTileWidth;

  @override
  Widget build(BuildContext context) => EvenGrid(
    minTileWidth: minTileWidth,
    children: [
      for (final (name, icon, url) in destinations)
        _ContactLink(name: name, icon: icon, url: url, isTile: isTile),
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
        // Flexible: inside a panel on a phone this has well under two hundred
        // pixels, and a label that cannot wrap pushes the row past its edge.
        Flexible(
          child: Text(
            text,
            style: context.type.meta.copyWith(color: tokens.textMuted),
          ),
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
    this.isTile = false,
  });

  /// Mark over name, small, instead of mark beside name.
  final bool isTile;

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
            child: _TileTip(
              name: widget.isTile ? widget.name : null,
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
                  ),
                  padding: widget.isTile
                      ? EdgeInsets.symmetric(
                          horizontal: tokens.space4,
                          vertical: tokens.space8,
                        )
                      : EdgeInsets.symmetric(
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
                    // The name gives way rather than overflowing. A card in a
                    // grid is handed its width instead of choosing it, so at a
                    // narrow measure "Book a call" is wider than the tile it is
                    // in -- and a row that cannot shrink answers that with a
                    // striped overflow bar. The mark keeps its size; the word
                    // takes what is left, and the full name is still on the
                    // card's own semantics label for anyone who cannot see it.
                    child: Flex(
                      direction: widget.isTile
                          ? Axis.vertical
                          : Axis.horizontal,
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
                            color: isHovered
                                ? tokens.beaconGlow
                                : tokens.beacon,
                          ),
                        // On a phone the mark alone: the name is the tooltip
                        // and the link's accessible name.
                        if (!widget.isTile) ...[
                          SizedBox(width: tokens.space12),
                          Flexible(
                            child: Text(
                              widget.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: context.type.body.copyWith(
                                color: isHovered
                                    ? tokens.beaconGlow
                                    : tokens.beacon,
                              ),
                            ),
                          ),
                        ],
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

/// The word between two ways of doing something, with a rule either side.
class _Or extends StatelessWidget {
  const _Or({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final line = Expanded(
      child: SizedBox(
        height: tokens.hairlineWidth,
        child: ColoredBox(color: tokens.hairline),
      ),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.space12),
          child: Text(
            text,
            style: context.type.meta.copyWith(color: tokens.textMuted),
          ),
        ),
        line,
      ],
    );
  }
}

/// Booking a call, as a thing of its own rather than a third link.
///
/// It used to be one of three identical cards, which made "send an email" and
/// "put an hour in his calendar" read as the same size of decision. This one
/// carries a sentence and the site's own gold, because it is the action the
/// page actually wants.
///
/// It does not name a duration. The owner suggested "30 mins", and the length
/// of the meeting is a fact about his Calendly rather than something this file
/// can know -- printing a number the booking page then contradicts is worse
/// than not printing one.
class _BookingCard extends StatefulWidget {
  const _BookingCard({required this.url});

  final Uri url;

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;

    return Semantics(
      link: true,
      label: l10n.aboutOpenLink(l10n.contactBookTitle),
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) {
          final isLit =
              _states.value.contains(WidgetState.hovered) ||
              _states.value.contains(WidgetState.focused);
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
              child: ExcludeSemantics(
                child: AnimatedContainer(
                  duration: ReducedMotion.duration(context, Motion.quick),
                  curve: MotionCurves.emphasized,
                  // Its own size, not the panel's. Stretched across a whole
                  // panel it read as a banner rather than a thing to press --
                  // the owner called it wide and odd.
                  constraints: const BoxConstraints(
                    maxWidth: Tokens.bookingCardMaxWidth,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.space16,
                    vertical: tokens.space12,
                  ),
                  decoration: BoxDecoration(
                    color: isLit
                        ? tokens.beacon.withValues(alpha: 0.10)
                        : tokens.surface,
                    borderRadius: BorderRadius.circular(tokens.controlRadius),
                    border: Border.all(
                      color: tokens.beacon,
                      width: tokens.hairlineWidth,
                    ),
                    boxShadow: isLit
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // A calendar, which is what booking is. The shadow clock
                      // before it read, as the owner put it, like a scale.
                      AnimatedSwitcher(
                        duration: ReducedMotion.duration(context, Motion.quick),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          isLit
                              ? Icons.event_available_rounded
                              : Icons.calendar_month_rounded,
                          key: ValueKey(isLit),
                          size: Tokens.bookingIconSize,
                          color: isLit ? tokens.beaconGlow : tokens.beacon,
                        ),
                      ),
                      SizedBox(width: tokens.space16),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.contactBookTitle,
                              style: type.body.copyWith(color: tokens.beacon),
                            ),
                            // The sentence under it on a wide card only: on
                            // a phone it ran to three lines under two words.
                            if (context.platform.viewport !=
                                ViewportClass.compact) ...[
                              SizedBox(height: tokens.space4),
                              Text(
                                l10n.contactBookBody,
                                style: type.bodyS.copyWith(
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: tokens.space16),
                      AnimatedSlide(
                        offset: isLit
                            ? const Offset(Tokens.bookingArrowTravel, 0)
                            : Offset.zero,
                        duration: ReducedMotion.duration(context, Motion.quick),
                        curve: MotionCurves.emphasized,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: Tokens.contactIconSize,
                          color: isLit ? tokens.beaconGlow : tokens.beacon,
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

/// A phone's icon-only tile names itself on a long press; a labelled card
/// has its name on it already and gets no tooltip.
class _TileTip extends StatelessWidget {
  const _TileTip({required this.name, required this.child});

  final String? name;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final name = this.name;
    if (name == null) return child;
    return Tooltip(message: name, excludeFromSemantics: true, child: child);
  }
}
