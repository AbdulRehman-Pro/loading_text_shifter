# loading_text_shifter

A vertically shifting loading indicator for Flutter that cycles through a list of
messages, fading the edges and animating text styles between adjacent and center
states. Supports async per-step gating so you can pause on a specific step until
an API responds, then decide whether to continue.

![demo](https://raw.githubusercontent.com/AbdulRehman-Pro/loading_text_shifter/main/doc/demo.gif)

## Features

- Smooth vertical slide between messages with top/bottom gradient fades.
- Animated text styles — font size, weight, and color interpolate as a message moves into and out of the center.
- Async `holdAt` hook for waiting on side-effects (e.g. API calls) before advancing — return `false` to stop the cycle.
- Optional looping. Configurable durations, curve, and styles.
- Accessible via `Semantics(liveRegion: true)` — screen readers announce each new message.
- Pure Dart — no platform plugins.

## Install

```yaml
dependencies:
  loading_text_shifter: ^1.0.0
```

Then:

```dart
import 'package:loading_text_shifter/loading_text_shifter.dart';
```

## Basic usage

```dart
LoadingTextShifter(
  messages: const [
    'Loading...',
    'Checking your account...',
    'Almost there...',
  ],
  shiftDuration: const Duration(seconds: 2),
  animationDuration: const Duration(milliseconds: 500),
  backgroundColor: Colors.white,
  centerTextStyle: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  ),
  adjacentTextStyle: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.black54,
  ),
)
```

> The `backgroundColor` should match the surface this widget is placed on,
> because the gradient overlays fade into it.

## Pause on a step until a future resolves

Use `holdAt` to wait on each step. Return `true` to advance, `false` to stop on
the current step. When `holdAt` is provided, `shiftDuration` is ignored.

```dart
LoadingTextShifter(
  messages: const ['Connecting…', 'Authenticating…', 'Fetching data…', 'Done'],
  loop: false,
  holdAt: (index, message) async {
    if (index == 2) {
      final result = await api.fetch();
      return result.success; // false stops on step 2
    }
    await Future.delayed(const Duration(seconds: 2));
    return true;
  },
  onShift: (index, message) => debugPrint('[$index] $message'),
)
```

## Parameters

| Parameter            | Type                                              | Default                | Description                                                                |
|----------------------|---------------------------------------------------|------------------------|----------------------------------------------------------------------------|
| `messages`           | `List<String>`                                    | required               | Messages to cycle through. Must not be empty.                              |
| `shiftDuration`      | `Duration`                                        | `2s`                   | Time the centered message stays before advancing. Ignored if `holdAt` set. |
| `animationDuration`  | `Duration`                                        | `600ms`                | Time of the slide/fade between messages.                                   |
| `height`             | `double`                                          | `120`                  | Total widget height. Each slot is `height / 3`.                            |
| `width`              | `double?`                                         | `null`                 | Optional fixed width. Defaults to filling the parent.                      |
| `centerTextStyle`    | `TextStyle?`                                      | `theme.titleMedium`    | Style for the centered message.                                            |
| `adjacentTextStyle`  | `TextStyle?`                                      | `centerTextStyle`      | Style for above/below messages. Animated between center and adjacent.      |
| `backgroundColor`    | `Color?`                                          | `theme.scaffoldBg`     | Color the gradient fades into. Match the parent surface for best effect.   |
| `loop`               | `bool`                                            | `true`                 | When `false`, stops on the last message.                                   |
| `curve`              | `Curve`                                           | `Curves.easeInOut`     | Curve for the slide/fade animation.                                        |
| `onShift`            | `void Function(int, String)?`                     | `null`                 | Fires when the centered message changes. Also fires once at index 0.       |
| `holdAt`             | `Future<bool> Function(int, String)?`             | `null`                 | Async gate per step. Return `false` to stop the cycle.                     |

## Notes

- When `holdAt` returns `false` the widget stops on that step and does not resume on its own. Rebuild the widget to restart from index 0.
- If `messages` shrinks while the widget is mounted, `_currentIndex` clamps to the new last index.
- The widget is wrapped in `RepaintBoundary` and the gradient overlays are built outside the animation loop to keep per-frame work minimal.

## License

MIT — see [LICENSE](LICENSE).
