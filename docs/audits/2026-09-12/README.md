# Journey repair — browser evidence

Final local WebAssembly build, inspected 2026-09-12 in isolated Chrome. This is a layout repair, not approval of the final Egyptian art direction.

| Capture | Viewport | Verified |
|---|---|---|
| [Desktop](journey-desktop.png) | 1440 × 900 | Centered, bounded map and timeline visible before selection |
| [Selected](journey-selected-desktop.png) | 1440 × 900 | Map narrows; details and Close control appear on the right |
| [Closed](journey-closed-desktop.png) | 1440 × 900 | Visible Close click restores the initial map/timeline layout |
| [Phone](journey-phone.png) | 390 × 844 | Map and compact timeline coexist |
| [Small phone](journey-small-phone.png) | 320 × 568 | Full boundary-year labels remain on one line |

Also captured 1366 × 768 and 844 × 390 in temporary audit files. No browser exceptions or horizontal document overflow were reported. Short landscape intentionally permits page scrolling; the regression suite verifies timeline reachability.

Phone views are Chrome emulation, not physical Android/iPhone tests. Desktop interaction used pointer/keyboard input with motion enabled. Close was clicked at its inspected visible position because the initial DOM selector did not locate Flutter's generated semantics; widget tests separately cover its accessible label and interaction.

The loopback development server maps `/journey` to the app shell. Its successful HTTP response is not evidence that production deep-link status or semantic HTML is fixed. No deployment, production content mutation or analytics activation occurred.
