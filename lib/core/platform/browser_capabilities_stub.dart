import 'package:nocturne/core/platform/pointer_capabilities.dart';

/// Unit-test host fallback; this implementation is not selected on the web.
Stream<PointerCapabilities> observe() =>
    Stream.value(const PointerCapabilities());
