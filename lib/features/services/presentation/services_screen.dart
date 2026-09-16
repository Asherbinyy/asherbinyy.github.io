import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/locale_controller.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/widgets/even_grid.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';
import 'package:nocturne/features/about/presentation/widgets/contact_links.dart';

/// What the owner will take on, and how to ask him for it.
///
/// The site had no answer to "can you build me one of these?". Work is a
/// ledger of what shipped and Journey is where it happened; both look
/// backwards. This is the page that looks forward, and it is the only page on
/// the site whose job is to start a conversation.
///
/// The services themselves come from content, like the skills and the tools,
/// so the list is the owner's to change without touching a widget.
class ServicesScreen extends ConsumerWidget {
  /// Reads the offer and the contact block from the content layer.
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final profile = switch (ref.watch(profileProvider).valueOrNull) {
      ContentReady<Profile>(:final data) => data,
      ContentFallback<Profile>(:final profile) => profile,
      _ => null,
    };

    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: context.platform.gutter,
        end: context.platform.gutter,
        top: tokens.space64,
        bottom: tokens.space96,
      ),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.servicesHeading, style: type.displayM),
            SizedBox(height: tokens.space16),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
              child: Text(
                l10n.servicesIntro,
                style: type.body.copyWith(color: tokens.textSecondary),
              ),
            ),
            SizedBox(height: tokens.space48),
            if (profile != null && profile.services.isNotEmpty)
              _Offer(services: profile.services),
            SizedBox(height: tokens.space64),
            if (profile != null)
              _Invitation(contact: profile.contact, locale: locale),
          ],
        ),
      ),
    );
  }
}

/// The grid of what he does.
class _Offer extends StatelessWidget {
  const _Offer({required this.services});

  final List<String> services;

  /// The mark for one service.
  ///
  /// Matched on the owner's own words rather than on an enum, because the list
  /// lives in content and he can add to it without a code change. Anything
  /// unrecognised still gets a card, with a neutral mark.
  static IconData iconFor(String service) {
    final name = service.toLowerCase();
    if (name.contains('whatsapp')) return SimpleIcons.whatsapp;
    if (name.contains('telegram')) return SimpleIcons.telegram;
    if (name.contains('ui') || name.contains('design')) {
      return SimpleIcons.figma;
    }
    // Admin before dashboard: both say "dashboard" and they are not the same
    // job. One is a panel somebody runs a business from, the other is a report.
    if (name.contains('admin')) return Icons.space_dashboard_outlined;
    if (name.contains('power bi') || name.contains('dashboard')) {
      return Icons.insert_chart_outlined_rounded;
    }
    if (name.contains('ai') || name.contains('automation')) {
      return Icons.auto_awesome_outlined;
    }
    if (name.contains('web')) return Icons.public_outlined;
    if (name.contains('mobile') || name.contains('app')) {
      return Icons.phone_iphone_rounded;
    }
    return Icons.bolt_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // Balanced rather than wrapped: eight services in a row that fits five
    // used to read five-then-three, which looks like the last row ran out
    // rather than like a set. Four and four is a set.
    return EvenGrid(
      minTileWidth: Tokens.serviceCardWidth,
      spacing: tokens.space16,
      children: [for (final service in services) _ServiceCard(name: service)],
    );
  }
}

class _ServiceCard extends StatefulWidget {
  const _ServiceCard({required this.name});

  final String name;

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _isLit = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return MouseRegion(
      onEnter: (_) => setState(() => _isLit = true),
      onExit: (_) => setState(() => _isLit = false),
      child: AnimatedContainer(
        duration: ReducedMotion.duration(context, Motion.quick),
        curve: MotionCurves.emphasized,
        width: Tokens.serviceCardWidth,
        padding: EdgeInsets.all(tokens.space24),
        decoration: BoxDecoration(
          color: _isLit ? tokens.surfaceRaised : tokens.surface,
          borderRadius: BorderRadius.circular(tokens.controlRadius),
          border: Border.all(
            color: _isLit ? tokens.beacon : tokens.hairline,
            width: tokens.hairlineWidth,
          ),
          boxShadow: _isLit
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _Offer.iconFor(widget.name),
              size: Tokens.serviceIconSize,
              color: tokens.beacon,
            ),
            SizedBox(height: tokens.space16),
            Text(
              widget.name,
              style: context.type.body.copyWith(color: tokens.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Wanna chat?" — the ask, and the two ways to make it.
class _Invitation extends StatelessWidget {
  const _Invitation({required this.contact, required this.locale});

  final Contact contact;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.controlRadius),
        border: Border.all(
          color: tokens.beacon.withValues(alpha: Tokens.portraitEdgeAlpha),
          width: tokens.hairlineWidth,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.space32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.servicesChatHeading,
              style: type.heading.copyWith(color: tokens.beacon),
            ),
            SizedBox(height: tokens.space12),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
              child: Text(
                l10n.servicesChatBody,
                style: type.body.copyWith(color: tokens.textSecondary),
              ),
            ),
            SizedBox(height: tokens.space24),
            if (contact.calendly case final url?)
              _BookButton(url: url, label: l10n.servicesBook),
            SizedBox(height: tokens.space24),
            ContactLinks(contact: contact, includesBooking: false),
          ],
        ),
      ),
    );
  }
}

/// The one loud control on the page.
class _BookButton extends StatefulWidget {
  const _BookButton({required this.url, required this.label});

  final Uri url;
  final String label;

  @override
  State<_BookButton> createState() => _BookButtonState();
}

class _BookButtonState extends State<_BookButton> {
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
      label: widget.label,
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) {
          final isLit = _states.value.contains(WidgetState.hovered);
          return FocusRing(
            isFocused: _states.value.contains(WidgetState.focused),
            child: InkWell(
              onTap: () => unawaited(
                launchUrl(widget.url, mode: LaunchMode.externalApplication),
              ),
              statesController: _states,
              borderRadius: BorderRadius.circular(tokens.controlRadius),
              mouseCursor: context.platform.isPointer
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: AnimatedContainer(
                duration: ReducedMotion.duration(context, Motion.quick),
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.space32,
                  vertical: tokens.space16,
                ),
                decoration: BoxDecoration(
                  color: isLit ? tokens.beaconGlow : tokens.beacon,
                  borderRadius: BorderRadius.circular(tokens.controlRadius),
                ),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        SimpleIcons.calendly,
                        size: Tokens.contactIconSize,
                        color: tokens.void_,
                      ),
                      SizedBox(width: tokens.space12),
                      Text(
                        widget.label,
                        style: context.type.body.copyWith(color: tokens.void_),
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
