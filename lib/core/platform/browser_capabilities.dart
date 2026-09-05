import 'package:nocturne/core/platform/browser_capabilities_stub.dart'
    if (dart.library.js_interop) 'package:nocturne/core/platform/browser_capabilities_web.dart'
    as browser;
import 'package:nocturne/core/platform/pointer_capabilities.dart';

/// Observes live capability changes without storage or network side effects.
Stream<PointerCapabilities> observePointerCapabilities() => browser.observe();
