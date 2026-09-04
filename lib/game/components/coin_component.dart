import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/enums.dart';
import '../neon_dodge_game.dart';

/// A collectible coin. Every coin belongs to a [NeonDimension]: it can only be
/// collected while the player's active dimension MATCHES the coin's dimension,
/// so the player must move (Neon Shift) through every dimension to gather them
/// all. Applies the same readability rule as hazards — matching = active.
class CoinComponent extends PositionComponent
    with HasGameReference<NeonDodgeGame> {
  CoinComponent({required this.dimension, required double speed})
      : fallSpeed = speed;

  /// Which dimension this coin lives in. Only collectible while
  /// [NeonShiftSystem.activeDimension] matches.
  final NeonDimension dimension;

  double fallSpeed;
  double _spin = 0;

  static const double radius = 9.0;

  /// The Neon Shift rule applied to coins: a coin is collectible when the
  /// player is currently in the matching dimension (mirrors hazard safety).
  bool get isCollectible => game.shiftSystem.isHazardSafe(dimension);

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _spin += dt * 6;
    final slowFactor = game.slowMotionActive ? GameTuning.slowMotionFactor : 1.0;

    final player = game.player;
    final toPlayer = player.position - position;

    // The magnet only pulls coins that are collectible in the current
    // dimension, so it never drags "other-dimension" coins around.
    if (game.magnetActive &&
        isCollectible &&
        toPlayer.length < GameTuning.magnetRadius) {
      final pull = toPlayer.normalized() * GameTuning.magnetPullSpeed * dt;
      position.add(pull);
    } else {
      position.y += fallSpeed * 0.6 * slowFactor * dt;
    }

    if (position.y > game.size.y + 40) removeFromParent();
  }

  bool hitsPlayer(Vector2 playerPos, double playerRadius) =>
      (position - playerPos).length < radius + playerRadius;

  @override
  void render(Canvas canvas) {
    final collectible = isCollectible;
    final dimColor = NeonColors.forDimension(dimension);
    final squash = (cos(_spin)).abs() * 0.6 + 0.4;

    // Soft glow — full while collectible, barely-there when ghosted.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset.zero, width: radius * 2.6, height: radius * 2.6),
      Paint()
        ..color = dimColor.withValues(alpha: collectible ? 0.35 : 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Body tinted by its dimension (blended toward the gold coin tone) so the
    // player can read which dimension the coin lives in. Ghosted when in the
    // other dimension — same readability pattern as safe hazards.
    final bodyColor = collectible
        ? Color.lerp(dimColor, NeonColors.coin, 0.45)!
        : NeonColors.coin.withValues(alpha: 0.16);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset.zero,
          width: radius * 2 * squash,
          height: radius * 2),
      Paint()..color = bodyColor,
    );

    // Dimension ring: solid when collectible, faint hint when ghosted.
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = collectible ? 2 : 1.5
        ..color = dimColor.withValues(alpha: collectible ? 1.0 : 0.4),
    );

    // Bright inner glint only on coins you can currently grab.
    if (collectible) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: radius * squash, height: radius),
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }
  }
}
