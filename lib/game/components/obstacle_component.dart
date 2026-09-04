import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/enums.dart';
import '../neon_dodge_game.dart';

/// A falling hazard. Every obstacle belongs to a [NeonDimension]; the Neon
/// Shift rules decide whether touching it is safe or deadly. Safe hazards
/// render dimmed/ghosted so the player can read the danger instantly.
class ObstacleComponent extends PositionComponent
    with HasGameReference<NeonDodgeGame> {
  ObstacleComponent({
    required this.obstacleType,
    required this.dimension,
    required double speed,
  }) : fallSpeed = speed;

  final ObstacleType obstacleType;
  final NeonDimension dimension;
  double fallSpeed;

  /// Mark to avoid double-counting near-miss events for the same obstacle.
  bool nearMissRecorded = false;

  double _angle = 0;
  double _pulse = 0;

  bool get isSafe => game.shiftSystem.isHazardSafe(dimension);

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    switch (obstacleType) {
      case ObstacleType.barrier:
        size = Vector2(64, 22);
      case ObstacleType.rotatingBarrier:
        size = Vector2(90, 18);
      case ObstacleType.laser:
        size = Vector2(16, 130);
      case ObstacleType.mine:
        size = Vector2.all(34);
      case ObstacleType.homingEnemy:
        size = Vector2.all(30);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulse += dt;
    final slowFactor = game.slowMotionActive
        ? GameTuning.slowMotionFactor
        : 1.0;

    position.y += fallSpeed * slowFactor * dt;

    switch (obstacleType) {
      case ObstacleType.rotatingBarrier:
        _angle += dt * 2.2;
      case ObstacleType.homingEnemy:
        // Drift toward the player's x slowly.
        final player = game.player;
        final dx = player.position.x - position.x;
        position.x += dx.clamp(-1.0, 1.0).toDouble() * 60 * slowFactor * dt;
      default:
        break;
    }

    if (position.y > game.size.y + 140) {
      removeFromParent();
    }
  }

  /// Approximate circular hit test against the player.
  bool hitsPlayer(Vector2 playerPos, double playerRadius) {
    // Use half the largest extent as an approximate radius, slightly
    // forgiving (0.82 factor) for fair hybrid-casual feel.
    final obstacleRadius = (max(size.x, size.y) / 2) * 0.82;
    return (position - playerPos).length < obstacleRadius + playerRadius * 0.85;
  }

  @override
  void render(Canvas canvas) {
    final base = NeonColors.forDimension(dimension);
    // Safe hazards ghost out — readability first (UX brief).
    final color = isSafe ? base.withValues(alpha: 0.16) : base;
    final glowColor = isSafe
        ? base.withValues(alpha: 0.05)
        : base.withValues(alpha: 0.45);

    final paint = Paint()..color = color;
    final glow = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    switch (obstacleType) {
      case ObstacleType.barrier:
      case ObstacleType.rotatingBarrier:
        canvas.save();
        if (obstacleType == ObstacleType.rotatingBarrier) {
          canvas.rotate(_angle);
        }
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: size.x,
          height: size.y,
        );
        canvas.drawRect(rect.inflate(4), glow);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          paint,
        );
        canvas.restore();
      case ObstacleType.laser:
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: size.x,
          height: size.y,
        );
        canvas.drawRect(rect.inflate(6), glow);
        canvas.drawRect(rect, paint);
        // Bright core line.
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: 4, height: size.y),
          Paint()..color = Colors.white.withValues(alpha: isSafe ? 0.1 : 0.8),
        );
      case ObstacleType.mine:
      case ObstacleType.homingEnemy:
        final r = size.x / 2 * (1 + sin(_pulse * 6) * 0.08);
        canvas.drawCircle(Offset.zero, r + 6, glow);
        canvas.drawCircle(Offset.zero, r, paint);
        // Spikes for mines, eye for homing enemies.
        if (obstacleType == ObstacleType.mine) {
          final spikePaint = Paint()
            ..color = color
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke;
          for (var i = 0; i < 6; i++) {
            final a = i * pi / 3 + _pulse;
            canvas.drawLine(
              Offset(cos(a) * r, sin(a) * r),
              Offset(cos(a) * (r + 8), sin(a) * (r + 8)),
              spikePaint,
            );
          }
        } else {
          canvas.drawCircle(
            Offset.zero,
            r * 0.35,
            Paint()
              ..color = Colors.white.withValues(alpha: isSafe ? 0.15 : 0.9),
          );
        }
    }
  }
}
