import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/content/models/education.dart';
import 'package:nocturne/content/models/localized_text.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/content/models/study.dart';

/// JSON decoding boundary shared by runtime loading and static generation.
abstract final class ContentParser {
  /// Rejects invalid identity and unsafe outbound links.
  static Profile profile(Map<String, dynamic> json) {
    final value = Profile.fromJson(json);
    for (final copy in [
      value.name,
      value.positioning,
      value.location,
      value.status,
      value.venture?.label,
    ]) {
      if (copy != null) _localized(copy);
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.contact.email)) {
      throw const FormatException('Invalid contact email');
    }
    for (final link in [
      value.contact.linkedin,
      value.contact.github,
      value.contact.gitlab,
      value.contact.medium,
      value.contact.calendly,
      value.venture?.url,
    ]) {
      if (link != null) _link(link);
    }
    if (value.cvFile case final String path) _asset(path);
    if (value.portrait case final Portrait portrait) _asset(portrait.src);
    return value;
  }

  /// Validates chronology, coordinates, optional weights, and unique IDs.
  static Career career(Map<String, dynamic> json) {
    final value = Career.fromJson(json);
    _unique(value.roles.map((role) => role.id));
    String? previous;
    for (final role in value.roles) {
      _period(role.start, role.end);
      if (previous != null && role.start.compareTo(previous) < 0) {
        throw const FormatException('Career must be chronological');
      }
      previous = role.start;
      _text(role.city);
      if (!RegExp(r'^[A-Z]{2}$').hasMatch(role.country) ||
          role.coords.length != 2 ||
          role.coords.any((coordinate) => !coordinate.isFinite) ||
          role.coords.first.abs() > 90 ||
          role.coords.last.abs() > 180) {
        throw const FormatException('Invalid station coordinates or country');
      }
      if (role.traceWeight case final double weight) _range(weight, 1);
      if (role.title case final LocalizedText copy) _localized(copy);
      if (role.summary case final LocalizedText copy) _localized(copy);
    }
    return value;
  }

  /// Validates featured membership and correspondence between stores/platforms.
  static Apps apps(Map<String, dynamic> json) {
    final value = Apps.fromJson(json);
    _unique(value.apps.map((app) => app.id));
    final storeLinks = <Uri>{};
    if (value.apps.where((app) => app.featured).length > 6) {
      throw const FormatException('At most six featured applications');
    }
    for (final app in value.apps) {
      _text(app.name);
      if (app.platforms.isEmpty ||
          app.platforms.toSet().length != app.platforms.length ||
          app.store.keys.any((platform) => !app.platforms.contains(platform))) {
        throw const FormatException('Invalid application platforms');
      }
      app.store.values.forEach(_link);
      if (app.store.values.any((link) => !storeLinks.add(link))) {
        throw const FormatException('Duplicate public store link');
      }
      if (app.role case final LocalizedText copy) _localized(copy);
      if (app.metric case final String copy) _text(copy);
    }
    return value;
  }

  /// Preserves supplied academic status while checking dates and mark ranges.
  static Education education(Map<String, dynamic> json) {
    final value = Education.fromJson(json);
    for (final entry in value.entries) {
      _localized(entry.institution);
      _localized(entry.award);
      if (entry.status case final LocalizedText copy) _localized(copy);
      for (final highlight in entry.highlights) {
        _localized(highlight);
      }
      _period(entry.start, entry.end);
      if (entry.overallMark case final double mark) _range(mark, 100);
      for (final module in entry.modules) {
        _localized(module.name);
        _range(module.mark, 100);
      }
    }
    return value;
  }

  /// Missing narrative is not a publishable case study.
  static Study study(Map<String, dynamic> json) {
    final value = Study.fromJson(json);
    _unique([value.id]);
    for (final copy in [
      value.title,
      value.context,
      value.problem,
      value.approach,
      value.outcome,
    ]) {
      _localized(copy);
    }
    for (final screen in value.screens) {
      _asset(screen.src);
      _localized(screen.caption);
    }
    return value;
  }

  static void _text(String value) {
    if (value.trim().isEmpty || value == '...' || value == '…') {
      throw const FormatException('Missing supplied copy');
    }
  }

  static void _localized(LocalizedText value) {
    _text(value.en);
    if (value.ar case final String arabic) _text(arabic);
  }

  static void _link(Uri value) {
    if (value.scheme != 'https' ||
        value.host.isEmpty ||
        value.userInfo.isNotEmpty) {
      throw const FormatException('Content links must be absolute HTTPS URLs');
    }
  }

  static void _asset(String value) {
    if (!value.startsWith('assets/') ||
        value.contains('..') ||
        value.contains(r'\') ||
        value.contains('?') ||
        value.contains('#')) {
      throw const FormatException('Invalid local asset path');
    }
  }

  static void _range(double value, double maximum) {
    if (!value.isFinite || value < 0 || value > maximum) {
      throw const FormatException('Numeric content is outside its valid range');
    }
  }

  static void _period(String start, String? end) {
    final month = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');
    if (!month.hasMatch(start) ||
        (end != null && (!month.hasMatch(end) || end.compareTo(start) < 0))) {
      throw const FormatException('Invalid year-month period');
    }
  }

  static void _unique(Iterable<String> ids) {
    final seen = <String>{};
    for (final id in ids) {
      if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(id) ||
          !seen.add(id)) {
        throw const FormatException('Invalid or duplicate content ID');
      }
    }
  }
}
