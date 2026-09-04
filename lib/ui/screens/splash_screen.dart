// ignore_for_file: unnecessary_underscores, unused_field

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../providers/providers.dart';
import '../../services/music_service.dart';
import 'home_shell.dart';

/// Branded intro: a pulsing neon logo, letter-spaced game name and a thin
/// glowing progress bar, then a smooth hand-off to the home shell.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2300),
  );

  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
  );
  late final Animation<double> _titleSpacing = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.45, 0.8, curve: Curves.easeOutBack),
  );
  late final Animation<double> _tagline = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.65, 0.95, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    // Initialise music from persisted settings before the first track request.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || MusicService.isRunningInTest) return;
      MusicService.instance.setEnabled(
        ref.read(gameSettingsProvider).musicEnabled,
      );
      MusicService.instance.playMenuMusic();
    });
    _controller
      ..forward()
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const HomeShell(),
              transitionDuration: const Duration(milliseconds: 450),
              reverseTransitionDuration: const Duration(milliseconds: 250),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.94, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
            ),
          );
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              const CustomPaint(painter: _SplashGridPainter()),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: _logoScale.value,
                    child: const _NeonLogo(r: 56),
                  ),
                  const SizedBox(height: 34),
                  Text(
                    'NEON',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 10 * _titleSpacing.value,
                      color: NeonColors.blue,
                      shadows: const [
                        Shadow(color: NeonColors.blue, blurRadius: 26),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(
                      'D O D G E',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 14,
                        color: NeonColors.pink,
                      ),
                    ),
                  ),
                ],
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: _tagline.value,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 320),
                      child: Text(
                        'Shift dimensions.  Survive the grid.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: NeonColors.textSecondary,
                          fontSize: 14,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Thin glowing progress bar.
              Positioned(
                left: 72,
                right: 72,
                bottom: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _controller.value,
                    minHeight: 4,
                    backgroundColor: NeonColors.gridLine,
                    valueColor: const AlwaysStoppedAnimation(NeonColors.blue),
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 40,
                child: Text(
                  'v1.0.0 · RETRO-ARCADE BUILD',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: NeonColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Glowing core + rotating orbit arcs used as the splash logo mark.
class _NeonLogo extends StatelessWidget {
  const _NeonLogo({required this.r});

  final double r;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(r * 2),
      painter: _LogoPainter(r: r),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({required this.r});

  final double r;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final now = DateTime.now().millisecondsSinceEpoch / 1000;

    // Outer static ring.
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = NeonColors.blue.withValues(alpha: 0.5),
    );

    // Rotating orbit arcs.
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = NeonColors.pink;
    for (final fraction in [0.0, 0.5]) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r * 0.78),
        now * 2.2 + fraction * math.pi,
        math.pi * 0.55,
        false,
        arcPaint,
      );
    }

    // Pulsing core.
    final pulse = 1 + math.sin(now * 3.2) * 0.08;
    canvas.drawCircle(
      center,
      r * 0.42 * pulse,
      Paint()
        ..color = NeonColors.blue.withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(
      center,
      r * 0.42 * pulse,
      Paint()..color = NeonColors.blue,
    );
    canvas.drawCircle(
      center,
      r * 0.18,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => oldDelegate.r != r;
}

/// Background perspective grid + vignette for the splash.
class _SplashGridPainter extends CustomPainter {
  const _SplashGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NeonColors.gridLine.withValues(alpha: 0.8)
      ..strokeWidth = 1;

    const spacing = 44.0;
    for (var x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vignette.
    final rect = Offset.zero & size;
    final gradient = RadialGradient(
      colors: [
        Colors.transparent,
        Colors.transparent,
        Colors.black.withValues(alpha: 0.55),
      ],
      stops: const [0.45, 0.75, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = gradient);
  }

  @override
  bool shouldRepaint(_SplashGridPainter oldDelegate) => false;
}
