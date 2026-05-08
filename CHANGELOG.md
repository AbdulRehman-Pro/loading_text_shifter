## 1.0.1

- Add demo gif to README.

## 1.0.0

- Initial release.
- `LoadingTextShifter` widget that vertically cycles through messages with smooth slide and fade-style transitions.
- Per-step async gating via `holdAt` — pause on a step until a future resolves, then decide whether to advance.
- Animated text styles: leaving and entering messages interpolate between `centerTextStyle` and `adjacentTextStyle`.
- `loop`, `onShift`, `curve`, `shiftDuration`, `animationDuration`, `backgroundColor`, custom dimensions.
- Accessible: wraps content in `Semantics(liveRegion: true)` so screen readers announce each new message.
