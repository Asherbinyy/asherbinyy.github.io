import 'package:flutter/widgets.dart';

import 'package:nocturne/core/platform/platform_service.dart';

/// Inherited infrastructure for context.platform; it owns no mutable state.
class PlatformScope extends InheritedWidget {
  /// Installs the current service for descendants.
  const PlatformScope({required this.service, required super.child, super.key});

  /// Immutable current resolution inputs.
  final PlatformService service;

  @override
  bool updateShouldNotify(PlatformScope oldWidget) =>
      service != oldWidget.service;
}

/// Feature widgets ask the central service instead of checking the browser.
extension PlatformContext on BuildContext {
  /// Subscribes to both viewport and capability changes.
  PlatformService get platform {
    final scope = dependOnInheritedWidgetOfExactType<PlatformScope>();
    if (scope == null) throw StateError('PlatformScope is missing.');
    return scope.service;
  }
}
