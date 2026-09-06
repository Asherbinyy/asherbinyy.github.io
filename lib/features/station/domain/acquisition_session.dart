import 'package:nocturne/features/station/domain/acquisition_session_stub.dart'
    if (dart.library.js_interop) 'package:nocturne/features/station/domain/acquisition_session_web.dart'
    as session;

/// Whether this browser tab has already completed or skipped acquisition.
bool hasPlayedAcquisition() => session.hasPlayed();

/// Persists only the functional once-per-tab flag, never a viewer identifier.
void markAcquisitionPlayed() => session.markPlayed();
