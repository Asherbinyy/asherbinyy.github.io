/// VM fallback used by unit and widget tests.
void captureCampaign(String campaign) {}

/// VM tests have no browser tab.
String? currentCampaign() => null;

/// VM tests have no document referrer.
String? currentReferrerHost() => null;

/// VM tests have no session storage, so no session identifier exists.
String? readSessionId() => null;

/// VM tests store nothing.
void writeSessionId(String id) {}
