import '../../core/constants.dart';
import '../../core/enums.dart';

/// Scales speed, spawn interval, pattern complexity and which obstacle
/// types are in play as a run goes on. New mechanics unlock gradually
/// instead of the game only getting faster (per the TDD).
class DifficultySystem {
  DifficultySystem({
    this.zoneModifier = 1.0,
    this.difficultyModifier = 1.0,
  });

  /// Zone multiplier (harder zones ramp faster).
  final double zoneModifier;

  /// Selected difficulty multiplier (Easy < Normal < Hard < Insane).
  final double difficultyModifier;

  /// Combined ramp factor applied to speed and spawn density.
  double get rampModifier => zoneModifier * difficultyModifier;

  double elapsed = 0;

  void update(double dt) => elapsed += dt;

  void reset() => elapsed = 0;

  /// Downward speed of hazards in px/s.
  double get fallSpeed {
    final raw = GameTuning.baseFallSpeed +
        elapsed * GameTuning.fallSpeedPerSecond * rampModifier;
    return raw.clamp(GameTuning.baseFallSpeed, GameTuning.maxFallSpeed)
        .toDouble();
  }

  /// Seconds between spawn ticks.
  double get spawnInterval {
    final raw = GameTuning.baseSpawnInterval -
        elapsed * GameTuning.spawnIntervalDecayPerSecond * rampModifier;
    return raw.clamp(GameTuning.minSpawnInterval, GameTuning.baseSpawnInterval)
        .toDouble();
  }

  /// How many hazards can spawn per tick (pattern complexity).
  int get maxSimultaneousSpawns {
    if (elapsed < 20) return 1;
    if (elapsed < 45) return 2;
    return 3;
  }

  /// Obstacle types allowed right now — introduced gradually.
  List<ObstacleType> get availableObstacleTypes {
    final types = <ObstacleType>[ObstacleType.barrier];
    if (elapsed > 15) types.add(ObstacleType.mine);
    if (elapsed > 35) types.add(ObstacleType.rotatingBarrier);
    if (elapsed > 55) types.add(ObstacleType.laser);
    if (elapsed > 80) types.add(ObstacleType.homingEnemy);
    return types;
  }
}
