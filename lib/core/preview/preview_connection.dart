import 'package:nocturne/core/preview/preview_transport.dart';
import 'package:nocturne/core/preview/preview_connection_stub.dart'
    if (dart.library.js_interop) 'package:nocturne/core/preview/preview_connection_web.dart'
    as platform;

/// Disabled unless embedded with a session and an explicit build-time origin.
PreviewTransport? createPreviewConnection() => platform.create();
