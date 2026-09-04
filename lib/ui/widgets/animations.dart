import 'package:flutter/material.dart';

import '../../core/constants.dart';

/// Entrance animation: fades and slides the child up into place once.
///
/// The optional [delay] is encoded as a curve interval rather than a timer,
/// so widget tests (which dislike pending timers) settle cleanly and the
/// whole page animates in a smooth staggered sequence.
class NeonEntrance extends StatefulWidget {
  const NeonEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 480),
    this.offset = const Offset(0, 0.12),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<NeonEntrance> createState() => _NeonEntranceState();
}

class _NeonEntranceState extends State<NeonEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMilliseconds / (widget.delay + widget.duration).inMilliseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_animation.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(widget.offset.dx * (1 - t), widget.offset.dy * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Counts up to [value] with an ease-out curve every time it changes.
class NeonCountUp extends StatelessWidget {
  const NeonCountUp({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 700),
    this.style,
    this.format,
  });

  final int value;
  final Duration duration;
  final TextStyle? style;

  /// Optional formatter (e.g. mm:ss display).
  final String Function(int value)? format;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final display = format?.call(v.round()) ?? v.round().toString();
        return Text(display, style: style);
      },
    );
  }
}

/// Press feedback: the child shrinks softly while a pointer is down and snaps
/// back afterwards — a cheap, satisfying "arcade button" feel.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.94,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Animated pill with a subtle glow; pulses when its [value] changes so coins
/// and counters feel alive.
class NeonPill extends StatelessWidget {
  const NeonPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(label),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      builder: (context, t, _) {
        final scale = 1 + (1 - t) * 0.28;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          transform: Matrix4.diagonal3Values(scale, scale, 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 10),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

/// Neon section header used across the new screens.
class NeonSectionHeader extends StatelessWidget {
  const NeonSectionHeader(this.text, {super.key, this.color = NeonColors.blue});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: NeonColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}