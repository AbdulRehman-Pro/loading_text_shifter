/// A vertically shifting loading indicator that cycles through a list of
/// messages with smooth fades, animated text styles, and optional async
/// per-step gating.
library;

import 'dart:async';

import 'package:flutter/material.dart';

/// A reusable loading indicator widget that vertically shifts through a list
/// of text messages, with the active message centered and adjacent messages
/// fading out via gradient overlays on the top and bottom.
///
/// Usage:
/// ```dart
/// LoadingTextShifter(
///   messages: const [
///     "Loading...",
///     "Checking your account...",
///     "Getting things ready...",
///     "Almost there...",
///     "Thanks for your patience...",
///   ],
///   shiftDuration: Duration(seconds: 2),
///   animationDuration: Duration(milliseconds: 600),
///   onShift: (index, message) {
///     debugPrint('Now showing [$index]: $message');
///   },
/// )
/// ```
class LoadingTextShifter extends StatefulWidget {
  /// The list of strings to cycle through.
  final List<String> messages;

  /// How long each message stays centered before shifting to the next.
  final Duration shiftDuration;

  /// How long the slide/fade animation takes between messages.
  final Duration animationDuration;

  /// Total height of the widget. The center text is sized to ~1/3 of this.
  final double height;

  /// Width of the widget. Defaults to filling the parent.
  final double? width;

  /// Style for the centered (active) text.
  final TextStyle? centerTextStyle;

  /// Style for the adjacent (above/below) texts.
  /// If null, falls back to [centerTextStyle] with reduced opacity via gradient.
  final TextStyle? adjacentTextStyle;

  /// Background color behind the gradient. Used as the gradient's fade color.
  /// Defaults to the surrounding [Scaffold]/[Material] background.
  final Color? backgroundColor;

  /// Whether the messages loop back to the beginning after the last item.
  final bool loop;

  /// Curve used for the slide/fade animation.
  final Curve curve;

  /// Called every time the centered message changes.
  /// Provides the new index and the corresponding message string.
  final void Function(int index, String message)? onShift;

  /// Per-step async gate. When provided, the widget calls this on each
  /// centered message and waits for the returned future before advancing.
  /// Return `true` to advance to the next message, `false` to stop on the
  /// current one. When null, [shiftDuration] is used as a simple timer.
  ///
  /// Use this to pause on a step until an API responds, then decide whether
  /// to continue:
  /// ```dart
  /// holdAt: (index, message) async {
  ///   if (index == 3) {
  ///     final result = await api.fetch();
  ///     return result.shouldContinue;
  ///   }
  ///   await Future.delayed(const Duration(seconds: 2));
  ///   return true;
  /// },
  /// ```
  final Future<bool> Function(int index, String message)? holdAt;

  /// Creates a [LoadingTextShifter] that cycles through [messages].
  ///
  /// [messages] must not be empty. All other parameters are optional and have
  /// sensible defaults; see each field for details.
  const LoadingTextShifter({
    super.key,
    required this.messages,
    this.shiftDuration = const Duration(seconds: 2),
    this.animationDuration = const Duration(milliseconds: 600),
    this.height = 120,
    this.width,
    this.centerTextStyle,
    this.adjacentTextStyle,
    this.backgroundColor,
    this.loop = true,
    this.curve = Curves.easeInOut,
    this.onShift,
    this.holdAt,
  }) : assert(messages.length > 0, 'messages must not be empty');

  @override
  State<LoadingTextShifter> createState() => _LoadingTextShifterState();
}

class _LoadingTextShifterState extends State<LoadingTextShifter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  int _currentIndex = 0;
  bool _disposed = false;
  Timer? _shiftTimer;
  Completer<void>? _shiftCompleter;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);

    // Fire initial callback for index 0.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) {
        widget.onShift?.call(_currentIndex, widget.messages[_currentIndex]);
        _scheduleNextShift();
      }
    });
  }

  @override
  void didUpdateWidget(covariant LoadingTextShifter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animationDuration != widget.animationDuration) {
      _controller.duration = widget.animationDuration;
    }
    if (oldWidget.curve != widget.curve) {
      _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    }
    // If the messages list shrinks past the current index, clamp it.
    if (_currentIndex >= widget.messages.length) {
      _currentIndex = widget.messages.length - 1;
      widget.onShift?.call(_currentIndex, widget.messages[_currentIndex]);
    }
  }

  Future<void> _waitShiftDuration() {
    final completer = Completer<void>();
    _shiftCompleter = completer;
    _shiftTimer = Timer(widget.shiftDuration, () {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  Future<void> _scheduleNextShift() async {
    final bool shouldAdvance;
    if (widget.holdAt != null) {
      shouldAdvance = await widget.holdAt!(
        _currentIndex,
        widget.messages[_currentIndex],
      );
    } else {
      await _waitShiftDuration();
      shouldAdvance = true;
    }
    if (_disposed || !mounted || !shouldAdvance) return;

    final isLast = _currentIndex >= widget.messages.length - 1;
    if (isLast && !widget.loop) return;

    await _controller.forward(from: 0);
    if (_disposed || !mounted) return;

    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.messages.length;
    });
    _controller.reset();

    widget.onShift?.call(_currentIndex, widget.messages[_currentIndex]);
    _scheduleNextShift();
  }

  @override
  void dispose() {
    _disposed = true;
    _shiftTimer?.cancel();
    if (_shiftCompleter?.isCompleted == false) {
      _shiftCompleter!.complete();
    }
    _controller.dispose();
    super.dispose();
  }

  String _messageAt(int offset) {
    final len = widget.messages.length;
    if (widget.loop) {
      final idx = (_currentIndex + offset) % len;
      return widget.messages[(idx + len) % len];
    } else {
      final idx = _currentIndex + offset;
      if (idx < 0 || idx >= len) return '';
      return widget.messages[idx];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.backgroundColor ?? theme.scaffoldBackgroundColor;

    final centerStyle =
        widget.centerTextStyle ??
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    final adjacentStyle = widget.adjacentTextStyle ?? centerStyle;

    // Each "slot" is one third of the widget's height.
    final slotHeight = widget.height / 3;

    final topGradient = IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgColor,
              bgColor.withValues(alpha: 0.85),
              bgColor.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );

    final bottomGradient = IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              bgColor,
              bgColor.withValues(alpha: 0.85),
              bgColor.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );

    return Semantics(
      liveRegion: true,
      label: widget.messages[_currentIndex],
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: ClipRect(
          child: Stack(
            alignment: Alignment.center,
            children: [
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    final t = _animation.value;
                    final shift = -t * slotHeight;
                    final leavingStyle = TextStyle.lerp(
                      centerStyle,
                      adjacentStyle,
                      t,
                    )!;
                    final enteringStyle = TextStyle.lerp(
                      adjacentStyle,
                      centerStyle,
                      t,
                    )!;
                    return Transform.translate(
                      offset: Offset(0, shift),
                      child: OverflowBox(
                        minHeight: 0,
                        maxHeight: double.infinity,
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSlot(
                              _messageAt(-1),
                              slotHeight,
                              adjacentStyle,
                            ),
                            _buildSlot(_messageAt(0), slotHeight, leavingStyle),
                            _buildSlot(
                              _messageAt(1),
                              slotHeight,
                              enteringStyle,
                            ),
                            // Extra slot below to feed in during transition.
                            _buildSlot(
                              _messageAt(2),
                              slotHeight,
                              adjacentStyle,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: slotHeight * 1.2,
                child: topGradient,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: slotHeight * 1.2,
                child: bottomGradient,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlot(String text, double height, TextStyle style) {
    return SizedBox(
      height: height,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }
}
