/// VM processes do not have a browser tab to persist across reloads.
bool hasPlayed() => false;

/// No browser storage exists on the VM.
void markPlayed() {}
