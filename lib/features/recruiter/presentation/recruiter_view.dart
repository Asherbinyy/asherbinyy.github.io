import 'dart:async';

import 'package:url_launcher/url_launcher.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/features/about/presentation/widgets/contact_links.dart';
import 'package:nocturne/features/about/presentation/widgets/education_table.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/locale_controller.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/content/period.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/content/models/education.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/loading/carrier_empty_state.dart';

/// Recruiter Mode: the whole site collapsed into one quiet page.
///
/// `00-PROJECT-BRIEF.md` section 5 calls this the highest-leverage feature on
/// the site: it demonstrates the judgement to know when not to be flashy, and
/// removes the risk that a conservative reviewer bounces off the main
/// experience. One screen, no map, no trace, no motion.
///
/// It renders the same content as the static `/brief` page — the featured
/// applications, education and contact — from the same JSON, so the two cannot
/// drift.
class RecruiterView extends ConsumerWidget {
  /// Reads identity, applications and education from the content layer.
  const RecruiterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final profile = switch (ref.watch(profileProvider).valueOrNull) {
      ContentReady(:final data) => data,
      ContentFallback(:final profile) => profile,
      _ => null,
    };
    if (profile == null) {
      return Padding(
        padding: EdgeInsets.all(context.tokens.space48),
        child: CarrierEmptyState(
          direction: context.l10n.heroContentUnavailable,
        ),
      );
    }

    final featured = switch (ref.watch(appsProvider).valueOrNull) {
      ContentReady(:final data) =>
        data.apps.where((app) => app.featured).toList(),
      _ => const <ShippedApp>[],
    };
    final entries = switch (ref.watch(educationProvider).valueOrNull) {
      ContentReady(:final data) => data.entries,
      _ => const <EducationEntry>[],
    };
    // The brief carried no work history at all, which is the one thing a
    // recruiter opens a summary to find.
    final roles = switch (ref.watch(careerProvider).valueOrNull) {
      ContentReady(:final data) =>
        data.roles
            .where((role) => role.kind == StopKind.role)
            .toList()
            .reversed
            .toList(),
      _ => const <CareerRole>[],
    };

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: context.platform.gutter,
        end: context.platform.gutter,
        top: context.tokens.space48,
        bottom: context.tokens.space64,
      ),
      child: _Brief(
        profile: profile,
        featured: featured,
        entries: entries,
        roles: roles,
        locale: locale,
      ),
    );
  }
}

class _Brief extends StatelessWidget {
  const _Brief({
    required this.profile,
    required this.featured,
    required this.entries,
    required this.roles,
    required this.locale,
  });

  final Profile profile;
  final List<ShippedApp> featured;
  final List<EducationEntry> entries;
  final List<CareerRole> roles;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;
    final status = profile.status;
    final location = profile.location;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(profile.shownName.resolve(locale), style: type.displayL),
        SizedBox(height: tokens.space8),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: type.measureFor(type.bodyL)),
          child: Text(
            profile.positioning.resolve(locale),
            style: type.bodyL.copyWith(color: tokens.textSecondary),
          ),
        ),
        if (location != null) Text(location.resolve(locale), style: type.meta),
        if (status != null) ...[
          SizedBox(height: tokens.space8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
            child: Text(status.resolve(locale), style: type.body),
          ),
        ],
        SizedBox(height: tokens.space32),

        // Most recent first. A recruiter reads a summary from the top and
        // stops when they have decided, so the newest role has to be the one
        // they meet.
        if (roles.isNotEmpty)
          _Row(
            label: l10n.recruiterExperience,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Two columns where the surface allows it. This was one
                // narrow column capped to the reading measure, so on a laptop
                // the right half of the page was empty and the owner had to
                // scroll a summary that would have fitted on one screen.
                _Columns(
                  children: [
                    for (final role in roles)
                      _Role(
                        role: role,
                        locale: locale,
                        // The title is repeated verbatim on most roles, so it
                        // is printed only where it changes.
                        showTitle:
                            role == roles.first ||
                            role.title?.resolve(locale) !=
                                roles[roles.indexOf(role) - 1].title?.resolve(
                                  locale,
                                ),
                      ),
                  ],
                ),
              ],
            ),
          ),

        if (featured.isNotEmpty)
          _Row(
            label: l10n.recruiterShipped,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final app in featured)
                  Padding(
                    padding: EdgeInsets.only(bottom: tokens.space8),
                    child: _App(app: app, locale: locale),
                  ),
              ],
            ),
          ),

        // One row for education, not one row per entry. It repeated its own
        // label down the page, which read as a bug because it was one.
        if (entries.isNotEmpty)
          _Row(
            label: l10n.recruiterEducation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in entries)
                  Padding(
                    padding: EdgeInsets.only(bottom: tokens.space12),
                    child: _Education(entry: entry, locale: locale),
                  ),
              ],
            ),
          ),

        _Row(
          label: l10n.recruiterContact,
          child: ContactLinks(contact: profile.contact),
        ),
      ],
    );
  }
}

/// One role: employer, what he did there, and when.
class _Role extends StatelessWidget {
  const _Role({
    required this.role,
    required this.locale,
    this.showTitle = true,
  });

  final CareerRole role;
  final AppLocale locale;

  /// Whether to print the job title.
  ///
  /// Five of the seven roles carry the identical title, so printing it under
  /// every employer made "Mobile Application Developer" the most repeated
  /// phrase on a page whose job is to be read in a minute.
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final title = role.title?.resolve(locale);
    final summary = role.summary?.resolve(locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                role.company ?? role.city,
                style: type.body.copyWith(color: tokens.textPrimary),
              ),
            ),
            SizedBox(width: tokens.space12),
            Text(
              formatPeriod(context.l10n, role.start, role.end),
              style: type.telemetryS.copyWith(color: tokens.textMuted),
            ),
          ],
        ),
        if (title != null && showTitle)
          Text(title, style: type.bodyS.copyWith(color: tokens.textSecondary)),
        if (summary != null)
          Text(
            summary,
            style: type.bodyS.copyWith(color: tokens.textSecondary),
          ),
      ],
    );
  }
}

/// One shipped application, with its listing where there is one.
///
/// The names were plain text before, which made the strongest evidence on the
/// site the one thing a reader could not click.
class _App extends StatelessWidget {
  const _App({required this.app, required this.locale});

  final ShippedApp app;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final role = app.role?.resolve(locale);
    final store = app.store.values.firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (store == null)
              Text(app.name, style: type.body)
            else
              _Link(label: app.name, url: store),
            if (app.metric case final metric?) ...[
              SizedBox(width: tokens.space12),
              Text(
                metric,
                style: type.telemetryS.copyWith(color: tokens.textMuted),
              ),
            ],
          ],
        ),
        if (role != null)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: type.measureFor(type.bodyS)),
            child: Text(
              role,
              style: type.bodyS.copyWith(color: tokens.textSecondary),
            ),
          ),
      ],
    );
  }
}

/// One qualification, with the marks that are worth reading.
class _Education extends StatelessWidget {
  const _Education({required this.entry, required this.locale});

  final EducationEntry entry;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final status = entry.status?.resolve(locale);
    // The same line the About page publishes, so the two cannot disagree.
    final best =
        entry.modules
            .where((module) => module.mark >= EducationTable.publishableMark)
            .toList()
          ..sort((a, b) => b.mark.compareTo(a.mark));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(entry.award.resolve(locale), style: type.body),
        Text(
          '${entry.institution.resolve(locale)}   '
          '${entry.start} to ${entry.end}',
          style: type.telemetryS.copyWith(color: tokens.textMuted),
        ),
        if (status != null)
          Text(status, style: type.bodyS.copyWith(color: tokens.beacon)),
        if (best.isNotEmpty)
          Text(
            best
                .take(3)
                .map(
                  (module) =>
                      '${module.name.resolve(locale)} '
                      '${module.mark.toStringAsFixed(0)}',
                )
                .join('   '),
            style: type.telemetryS.copyWith(color: tokens.textSecondary),
          ),
      ],
    );
  }
}

/// A store listing, opened in a new tab.
class _Link extends StatelessWidget {
  const _Link({required this.label, required this.url});

  final String label;
  final Uri url;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      link: true,
      child: InkWell(
        onTap: () =>
            unawaited(launchUrl(url, mode: LaunchMode.externalApplication)),
        hoverColor: Colors.transparent,
        child: Text(
          label,
          style: context.type.body.copyWith(
            color: tokens.beacon,
            decoration: TextDecoration.underline,
            decorationColor: tokens.beaconDim,
          ),
        ),
      ),
    );
  }
}

/// One labelled row of the brief: label in the leading column, value beside it.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: tokens.space128,
            child: Text(label, style: context.type.meta),
          ),
          SizedBox(width: tokens.space16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Lays children out in two columns where the surface is wide enough.
///
/// The recruiter view was a single column capped to the reading measure, which
/// is right for prose and wrong for a summary meant to be scanned in under a
/// minute: on a laptop the right half of the page was empty and the reader had
/// to scroll past content that would have fitted on one screen.
class _Columns extends StatelessWidget {
  const _Columns({required this.children});

  final List<Widget> children;

  /// Below this the second column would be narrower than a readable measure.
  static const double _twoColumnWidth = 720;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _twoColumnWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final child in children)
                Padding(
                  padding: EdgeInsets.only(bottom: tokens.space16),
                  child: child,
                ),
            ],
          );
        }

        // Split down the middle, in order, so the sequence still reads down
        // the left column and then down the right rather than zig-zagging.
        final half = (children.length / 2).ceil();
        Widget column(Iterable<Widget> items) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final child in items)
                Padding(
                  padding: EdgeInsets.only(bottom: tokens.space16),
                  child: child,
                ),
            ],
          ),
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            column(children.take(half)),
            SizedBox(width: tokens.space32),
            column(children.skip(half)),
          ],
        );
      },
    );
  }
}
