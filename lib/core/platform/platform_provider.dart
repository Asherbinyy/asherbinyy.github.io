import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:nocturne/core/platform/browser_capabilities.dart';
import 'package:nocturne/core/platform/pointer_capabilities.dart';

part 'platform_provider.g.dart';

/// Owns and disposes browser capability listeners with the app scope.
@riverpod
class PlatformCapabilities extends _$PlatformCapabilities {
  /// Riverpod cancels the capability stream when the app scope is disposed.
  @override
  Stream<PointerCapabilities> build() => observePointerCapabilities();
}
