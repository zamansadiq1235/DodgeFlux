import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/enums.dart';
import '../../models/player_skin.dart';

/// Renders a [PlayerSkin] silhouette so the shop and analytics show the exact
/// shape/color a skin has in-game.
class SkinPreview extends StatelessWidget {
  const SkinPreview({
    super.key,
    required this.skin,
    this.size = 72,
    this.backgroundColor = const Color(0xFF050510),
  });

  final PlayerSkin skin;
  final double size;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: skin.trailColor, width: 2),
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size.square(size * 0.62),
        painter: _SkinPainter(
          shape: skin.shape,
          color: skin.coreColor,
          accent: skin.trailColor,
        ),
      ),
    );
  }
}

class _SkinPainter extends CustomPainter {
  const _SkinPainter({
    required this.shape,
    required this.color,
    required this.accent,
  });

  final SkinShape shape;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2;

    // Soft glow behind the shape.
    canvas.drawCircle(
      center,
      r * 1.1,
      Paint()
        ..color = accent.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    void highlight(double inner) {
      canvas.drawCircle(center, r * inner, Paint()..color = Colors.white);
    }

    switch (shape) {
      case SkinShape.orb:
        canvas.drawCircle(center, r, Paint()..color = color);
        highlight(0.42);
      case SkinShape.diamond:
        final path = Path()
          ..moveTo(center.dx, center.dy - r)
          ..lineTo(center.dx + r * 0.78, center.dy)
          ..lineTo(center.dx, center.dy + r)
          ..lineTo(center.dx - r * 0.78, center.dy)
          ..close();
        canvas.drawPath(path, Paint()..color = color);
        canvas.drawCircle(
          center,
          r * 0.3,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
      case SkinShape.ring:
        canvas.drawCircle(
          center,
          r * 0.9,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.38
            ..color = color.withValues(alpha: 0.55),
        );
        canvas.drawCircle(
          center,
          r * 0.9,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = Colors.white.withValues(alpha: 0.8),
        );
        canvas.drawCircle(
          center,
          r * 0.5,
          Paint()..color = Colors.white.withValues(alpha: 0.25),
        );
      case SkinShape.hexagon:
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final angle = math.pi / 3 * i - math.pi / 2;
          final x = center.dx + math.cos(angle) * r;
          final y = center.dy + math.sin(angle) * r;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, Paint()..color = color);
        canvas.drawCircle(
          center,
          r * 0.34,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
    }
  }

  @override
  bool shouldRepaint(_SkinPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.color != color ||
      oldDelegate.accent != accent;
}