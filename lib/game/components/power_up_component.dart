import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../models/power_up_data.dart';
import '../neon_dodge_game.dart';

/// A falling power-up pickup (Shield, Slow-Mo, Magnet, Dash, Score x2).
class PowerUpComponent extends PositionComponent
    with HasGameReference<NeonDodgeGame> {
  PowerUpComponent({required this.powerUpType, required double speed})
      : fallSpeed = speed;

  final PowerUpType powerUpType;
  double fallSpeed;
  double _pulse = 0;

  static const double radius = 16.0;

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulse += dt;
    final slowFactor = game.slowMotionActive ? GameTuning.slowMotionFactor : 1.0;
    position.y += fallSpeed * 0.55 * slowFactor * dt;
    if (position.y > game.size.y + 50) removeFromParent();
  }

  bool hitsPlayer(Vector2 playerPos, double playerRadius) =>
      (position - playerPos).length < radius + playerRadius;

  @override
  void render(Canvas canvas) {
    final color = NeonColors.forPowerUp(powerUpType);
    final r = radius * (1 + sin(_pulse * 4) * 0.1);

    canvas.drawCircle(
      Offset.zero,
      r + 8,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = color,
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.8,
      Paint()..color = color.withValues(alpha: 0.15),
    );

    // Glyph label (asset-free icons).
    final tp = TextPainter(
      text: TextSpan(
        text: PowerUpData.of(powerUpType).icon,
        style: TextStyle(fontSize: 16, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}
