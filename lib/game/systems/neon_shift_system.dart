import '../../core/constants.dart';
import '../../core/enums.dart';

/// Neon Shift — the game's core mechanic.
///
/// In Blue mode blue hazards are safe and pink ones are dangerous;
/// in Pink mode the opposite holds. Shifting has a short cooldown so
/// spamming is not free. This class is pure logic and unit-tested.
class NeonShiftSystem {
  NeonShiftSystem({
    NeonDimension initial = NeonDimension.blue,
    this.cooldown = GameTuning.shiftCooldown,
  })  : activeDimension = initial,
        _cooldownRemaining = 0;

  NeonDimension activeDimension;

  /// Seconds the player must wait between shifts.
  final double cooldown;

  double _cooldownRemaining;

  double get cooldownRemaining => _cooldownRemaining;
  bool get canShift => _cooldownRemaining <= 0;

  /// Normalized cooldown progress (1 = ready, 0 = just shifted). For UI ring.
  double get cooldownProgress =>
      cooldown <= 0 ? 1 : (1 - _cooldownRemaining / cooldown).clamp(0.0, 1.0).toDouble();

  /// Attempts a shift. Returns true when the dimension actually flipped.
  bool tryShift() {
    if (!canShift) return false;
    activeDimension = activeDimension.opposite;
    _cooldownRemaining = cooldown;
    return true;
  }

  /// The core rule: a hazard is safe when its dimension matches the active one.
  bool isHazardSafe(NeonDimension hazardDimension) =>
      hazardDimension == activeDimension;

  void update(double dt) {
    if (_cooldownRemaining > 0) {
      _cooldownRemaining -= dt;
      if (_cooldownRemaining < 0) _cooldownRemaining = 0;
    }
  }

  void reset({NeonDimension to = NeonDimension.blue}) {
    activeDimension = to;
    _cooldownRemaining = 0;
  }
}
