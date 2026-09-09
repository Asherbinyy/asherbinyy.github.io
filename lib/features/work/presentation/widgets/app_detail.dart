import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/content/work_domain_label.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/loading/station_card.dart';
import 'package:nocturne/features/work/presentation/widgets/store_links.dart';

/// What `/work/<id>` shows for an application with no written study.
///
/// The route used to answer every unwritten slug with "not written yet", which
/// is honest and useless: the site knows the name, the role, the metric, the
/// sector and the store links for all fourteen applications, and was refusing
/// to show any of it because a long-form case study did not exist.
///
/// A study, where one is ever written, still wins. This is the floor, not a
/// replacement, and it is what makes the app names on the journey page worth
/// linking at all.
class AppDetail extends ConsumerWidget {
  /// Renders [app] as a page.
  const AppDetail({required this.app, required this.locale, super.key});

  /// The application to describe.
  final ShippedApp app;

  /// Active content channel.
  final AppLocale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final type = context.type;
    final role = app.role?.resolve(locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(app.name, style: type.displayM),
        SizedBox(height: tokens.space8),
        Text(
          app.domain.label(context.l10n),
          style: type.telemetry.copyWith(color: tokens.beacon),
        ),
        SizedBox(height: tokens.space32),
        // The mark stands in until the owner uploads real media through the
        // panel. Unlabelled: the name is directly above it.
        ClipRRect(
          borderRadius: BorderRadius.circular(Tokens.cardRadius),
          child: StationCard(
            seedId: app.id,
            name: '',
            width: double.infinity,
            height: tokens.space64 * 4,
          ),
        ),
        if (role != null) ...[
          SizedBox(height: tokens.space32),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
            child: Text(role, style: type.body),
          ),
        ],
        if (app.metric case final String metric) ...[
          SizedBox(height: tokens.space16),
          Text(
            metric,
            style: type.telemetry.copyWith(color: tokens.instrument),
          ),
        ],
        if (app.store.isNotEmpty) ...[
          SizedBox(height: tokens.space32),
          StoreLinks(app: app),
        ],
        SizedBox(height: tokens.space48),
        BeaconButton(
          label: context.l10n.caseStudyBackToWork,
          onPressed: () => context.goNamed(AppRoute.work.name),
        ),
      ],
    );
  }
}
