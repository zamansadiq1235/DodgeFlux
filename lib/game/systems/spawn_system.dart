import 'dart:math';

import '../../core/constants.dart';
import '../../core/enums.dart';
import 'difficulty_system.dart';

enum SpawnKind { obstacle, coinLine, powerUp }

/// Describes one entity the game should create.
class SpawnRequest {
  const SpawnRequest.obstacle({
    required this.xFraction,
    required this.obstacleType,
    required this.dimension,
  })  : kind = SpawnKind.obstacle,
        powerUpType = null;

  const SpawnRequest.coinLine({
    required this.xFraction,
    required this.dimension,
  })  : kind = SpawnKind.coinLine,
        obstacleType = null,
        powerUpType = null;

  const SpawnRequest.powerUp(
      {required this.xFraction, required this.powerUpType})
      : kind = SpawnKind.powerUp,
        obstacleType = null,
        dimension = null;

  final SpawnKind kind;

  /// Horizontal position as a 0..1 fraction of the playfield width.
  final double xFraction;
  final ObstacleType? obstacleType;
  final PowerUpType? powerUpType;
  final NeonDimension? dimension;
}

/// Decides *what* spawns each tick. Pure logic — the game turns requests
/// into components. Kept separate so difficulty/spawn rules are testable.
class SpawnSystem {
  SpawnSystem({Random? random}) : _random = random ?? Random();

  final Random _random;
  double _timeSinceSpawn = 0;

  void reset() => _timeSinceSpawn = 0;

  /// Call every frame; returns the entities to create this frame
  /// (usually empty, occasionally one batch).
  List<SpawnRequest> update(double dt, DifficultySystem difficulty) {
    _timeSinceSpawn += dt;
    if (_timeSinceSpawn < difficulty.spawnInterval) {
      return const [];
    }
    _timeSinceSpawn = 0;

    final requests = <SpawnRequest>[];
    final roll = _random.nextDouble();

    if (roll < GameTuning.powerUpSpawnChance) {
      requests.add(SpawnRequest.powerUp(
        xFraction: _lane(),
        powerUpType:
            PowerUpType.values[_random.nextInt(PowerUpType.values.length)],
      ));
      return requests;
    }

    if (roll < GameTuning.powerUpSpawnChance + GameTuning.coinSpawnChance) {
      // Coin lines are spread across BOTH dimensions so the player has to
      // Neon Shift through every dimension to collect them all.
      requests.add(SpawnRequest.coinLine(
        xFraction: _lane(),
        dimension: _random.nextBool() ? NeonDimension.blue : NeonDimension.pink,
      ));
      return requests;
    }

    // Obstacles: 1..N at once depending on difficulty.
    final count = 1 + _random.nextInt(difficulty.maxSimultaneousSpawns);
    final usedLanes = <double>{};
    for (var i = 0; i < count; i++) {
      double lane = _lane();
      // Avoid two hazards in nearly the same lane in one batch.
      var guard = 0;
      while (usedLanes.any((l) => (l - lane).abs() < 0.25) && guard++ < 6) {
        lane = _lane();
      }
      usedLanes.add(lane);
      final types = difficulty.availableObstacleTypes;
      requests.add(SpawnRequest.obstacle(
        xFraction: lane,
        obstacleType: types[_random.nextInt(types.length)],
        dimension: _random.nextBool() ? NeonDimension.blue : NeonDimension.pink,
      ));
    }
    return requests;
  }

  /// Random lane between 10% and 90% of the width.
  double _lane() => 0.1 + _random.nextDouble() * 0.8;
}
