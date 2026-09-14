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

/// The measured space left by persistent chrome, before page scrolling.
class ContentViewport extends InheritedWidget {
  /// Publishes the available [height] without estimating header/nav sizes.
  const ContentViewport({
    required this.height,
    required super.child,
    super.key,
  });

  /// Actual visible content height, in logical pixels.
  final double height;

  /// Null for standalone widgets rendered outside the scrolling chrome.
  static double? heightOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ContentViewport>()?.height;

  @override
  bool updateShouldNotify(ContentViewport oldWidget) =>
      height != oldWidget.height;
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
