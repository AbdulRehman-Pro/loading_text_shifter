# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A pub.dev-publishable Flutter package: `loading_text_shifter`. The repo is a **package** (not an app). The `example/` subfolder is a runnable Flutter app that consumes the package via `path:` dependency.

## Layout

- `lib/loading_text_shifter.dart` — the entire package (single library; no barrel needed).
- `test/widget_test.dart` — package widget tests.
- `example/` — a complete Flutter app demonstrating usage. Has its own `pubspec.yaml` that depends on the parent package via `path: ../`.
- `pubspec.yaml` — the **package** manifest (no `flutter:` block, no app deps).
- `.pubignore` — keeps build artifacts, IDE files, and example platform folders out of the published archive.
- `LICENSE`, `CHANGELOG.md`, `README.md` — required by pub.dev.

## Commands

From the repo root:

- Install package deps: `flutter pub get`
- Static analysis: `dart analyze`
- Run all tests: `flutter test`
- Run a single test: `flutter test test/widget_test.dart -p "<plain-name pattern>"`
- Format: `dart format .`
- Validate the publish archive: `dart pub publish --dry-run`
- Preview pub.dev score locally: `dart pub global run pana --no-warning .`
- Publish (when ready): `dart pub publish`

To run the example app:
```
cd example && flutter pub get && flutter run
```

## Architecture

Single-purpose package exporting one widget. Key implementation details of `LoadingTextShifter` (worth understanding before editing):

- Renders **four** slots wrapped in `OverflowBox(alignment: Alignment.topCenter)`, then animates a `Transform.translate` upward by exactly one `slotHeight` (= `height / 3`). The +2 slot exists so there's content feeding in from the bottom while the previous +1 becomes the new center. The OverflowBox lets the 4-slot column (4 × slotHeight) lay out at its natural height inside the visible region (3 × slotHeight); `ClipRect` masks the overflow. After each animation, the controller is reset and `_currentIndex` advances by one — the visual position snaps back while the index moves forward, producing seamless scroll.
- Per-frame, the leaving slot's style lerps `centerStyle → adjacentStyle` and the entering slot lerps `adjacentStyle → centerStyle` via `TextStyle.lerp(_, _, _animation.value)`, so font size/weight/color animate alongside the position.
- Two `LinearGradient` overlays (top and bottom, each `slotHeight * 1.2` tall) fade the adjacent slots into `backgroundColor`. They're built **outside** the `AnimatedBuilder` so they don't rebuild every animation tick. If `backgroundColor` doesn't match the actual surrounding background, the fade will look wrong — callers must pass the real bg color.
- Shift loop in `_scheduleNextShift`: when `holdAt` is provided, awaits its returned `Future<bool>`; otherwise waits via a cancellable `Timer` (stored in `_shiftTimer`, completed via `_shiftCompleter`) so dispose can cancel cleanly. Returning `false` from `holdAt` permanently stops the cycle on that step (no built-in resume — rebuild to restart).
- `onShift` fires once on initial mount (post-frame) for index 0, then after each transition completes. The widget wraps itself in `Semantics(liveRegion: true, label: currentMessage)` so screen readers announce each new message.
- `didUpdateWidget` reacts to changes in `animationDuration`, `curve`, and a shrunk `messages` list. Other props are read on the next build.

## Publishing notes

- The version is set in `pubspec.yaml`. Pub.dev versions are **immutable** — once `1.0.0` is published, only `1.0.1` / `1.1.0` / etc. can replace it.
- Update `CHANGELOG.md` for every version bump; pub.dev shows it on the package page.
- `homepage` / `repository` / `issue_tracker` URLs in `pubspec.yaml` must currently point at `https://github.com/REPLACE_ME/loading_text_shifter` placeholders — update before the first publish or the issue-tracker check on pana will fail (it's the only thing standing between this package and a 160/160 pana score).
- `LICENSE` has `<YOUR_NAME>` placeholder — fill in before publishing.
