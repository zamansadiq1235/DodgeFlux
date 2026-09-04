import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../models/player_skin.dart';
import '../neon_dodge_game.dart';

/// The player: a glowing neon orb anchored near the bottom of the screen,
/// steered horizontally by dragging. Its body color always shows the
/// active dimension (Blue/Pink) so the state is readable at a glance.
class PlayerComponent extends PositionComponent
    with HasGameReference<NeonDodgeGame> {
  PlayerComponent({required this.skin});

  final PlayerSkin skin;

  double targetX = 0;
  double targetY = 0;

  double _pulse = 0;
  double _trailTimer = 0;

  @override
  Future<void> onLoad() async {
    size = Vector2.all(GameTuning.playerRadius * 2);
    anchor = Anchor.center;
    targetX = game.size.x / 2;
    targetY = game.size.y * GameTuning.playerYFraction;
    position = Vector2(targetX, targetY);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulse += dt;

    // Smoothly follow the drag target on both axes.
    final dx = targetX - position.x;
    position.x += dx * min(1.0, GameTuning.playerFollowSpeed * dt);
    position.x = position.x
        .clamp(GameTuning.playerRadius, game.size.x - GameTuning.playerRadius)
        .toDouble();

    final dy = targetY - position.y;
    position.y += dy * min(1.0, GameTuning.playerFollowSpeed * dt);
    position.y = position.y
        .clamp(GameTuning.playerRadius, game.size.y - GameTuning.playerRadius)
        .toDouble();

    // Emit trail particles while playing.
    _trailTimer += dt;
    if (_trailTimer > 0.05) {
      _trailTimer = 0;
      game.add(
        _TrailParticle(
          position: position.clone(),
          color: NeonColors.forDimension(game.shiftSystem.activeDimension),
          skinColor: skin.trailColor,
        ),
      );
    }
  }

  double get radius => GameTuning.playerRadius;

  @override
  void render(Canvas canvas) {
    final dimension = game.shiftSystem.activeDimension;
    final dimColor = NeonColors.forDimension(dimension);

    // Body colour = dimension colour blended toward the skin's own core
    // colour, so skins stay readable in both dimensions but look distinct.
    final bodyColor = Color.lerp(dimColor, skin.coreColor, 0.45)!;

    final r = GameTuning.playerRadius;
    final pulseScale = 1 + sin(_pulse * 5) * 0.06;

    // Outer glow.
    canvas.drawCircle(
      Offset.zero,
      skin.glowRadius * pulseScale,
      Paint()
        ..color = dimColor.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    switch (skin.shape) {
      case SkinShape.orb:
        _drawOrb(canvas, r, pulseScale, bodyColor);
      case SkinShape.diamond:
        _drawDiamond(canvas, r, pulseScale, bodyColor);
      case SkinShape.ring:
        _drawRing(canvas, r, pulseScale, bodyColor);
      case SkinShape.hexagon:
        _drawHexagon(canvas, r, pulseScale, bodyColor);
    }

    // Shield ring while the shield power-up is active.
    if (game.shieldActive) {
      canvas.drawCircle(
        Offset.zero,
        r + 7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = NeonColors.shield,
      );
    }

    // Dash streak ring while dashing.
    if (game.dashActive) {
      canvas.drawCircle(
        Offset.zero,
        r + 12,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.7),
      );
    }
  }

  void _drawOrb(Canvas canvas, double r, double pulse, Color color) {
    canvas.drawCircle(Offset.zero, r * pulse, Paint()..color = color);
    canvas.drawCircle(
      Offset.zero,
      r * 0.45,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  void _drawDiamond(Canvas canvas, double r, double pulse, Color color) {
    final path = Path()
      ..moveTo(0, -r * 1.15 * pulse)
      ..lineTo(r * 0.85 * pulse, 0)
      ..lineTo(0, r * 1.15 * pulse)
      ..lineTo(-r * 0.85 * pulse, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(
      Offset.zero,
      r * 0.35,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  void _drawRing(Canvas canvas, double r, double pulse, Color color) {
    canvas.drawCircle(
      Offset.zero,
      r * pulse,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = color.withValues(alpha: 0.45),
    );
    canvas.drawCircle(
      Offset.zero,
      r * pulse,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white.withValues(alpha: 0.8),
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.55,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  void _drawHexagon(Canvas canvas, double r, double pulse, Color color) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = pi / 3 * i - pi / 2;
      final x = cos(angle) * r * 1.15 * pulse;
      final y = sin(angle) * r * 1.15 * pulse;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(
      Offset.zero,
      r * 0.4,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }
}

/// Short-lived fading dot left behind the player.
class _TrailParticle extends PositionComponent {
  _TrailParticle({
    required Vector2 position,
    required this.color,
    required this.skinColor,
  }) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(10);
    priority = -1;
  }

  final Color color;
  final Color skinColor;
  double _life = 0.35;

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_life / 0.35).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset.zero,
      5 * t,
      Paint()
        ..color = Color.lerp(color, skinColor, 0.4)!.withValues(alpha: 0.5 * t),
    );
  }
}
