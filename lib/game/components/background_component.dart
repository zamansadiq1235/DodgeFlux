import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/constants.dart';
import '../../models/zone_data.dart';
import '../neon_dodge_game.dart';

/// Scrolling neon grid background. Tinted subtly toward the active
/// dimension so the whole screen communicates the Neon Shift state.
class BackgroundComponent extends PositionComponent
    with HasGameReference<NeonDodgeGame> {
  BackgroundComponent({required this.zone});

  final ZoneData zone;
  double _scroll = 0;

  static const double _cell = 48;

  @override
  Future<void> onLoad() async {
    size = game.size.clone();
    position = Vector2.zero();
    priority = -10;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final speed =
        game.slowMotionActive ? 40 * GameTuning.slowMotionFactor : 40.0;
    _scroll = (_scroll + speed * dt) % _cell;
  }

  @override
  void render(Canvas canvas) {
    final bg = zone.backgroundColor;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = bg,
    );

    // Soft dimension tint overlay.
    final dimColor =
        NeonColors.dimForDimension(game.shiftSystem.activeDimension);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = dimColor.withValues(alpha: 0.08),
    );

    final gridPaint = Paint()
      ..color = zone.gridColor.withValues(alpha: 0.8)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.x; x += _cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = -_cell + _scroll; y <= size.y; y += _cell) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }
  }
}
