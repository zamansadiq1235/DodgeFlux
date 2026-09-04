/// Core enumerations for Neon Dodge.
library;

/// The two neon dimensions the player can shift between.
///
/// Central mechanic ("Neon Shift"): a hazard whose [NeonDimension] matches
/// the player's active dimension is SAFE; the opposite one is DANGEROUS.
enum NeonDimension {
  blue,
  pink;

  NeonDimension get opposite =>
      this == NeonDimension.blue ? NeonDimension.pink : NeonDimension.blue;
}

/// High-level game states described in the TDD:
/// menu, loading, playing, paused, gameOver and reward.
enum GameStatus { menu, loading, playing, paused, gameOver, reward }

/// Obstacle families, introduced gradually as difficulty ramps.
enum ObstacleType { barrier, rotatingBarrier, laser, mine, homingEnemy }

/// Selectable run difficulty. Higher = faster hazard ramp and better rewards.
enum DifficultyLevel {
  easy('Easy', 0.7, 0.8),
  normal('Normal', 1.0, 1.0),
  hard('Hard', 1.3, 1.25),
  insane('Insane', 1.6, 1.6);

  const DifficultyLevel(this.label, this.rampModifier, this.rewardMultiplier);

  final String label;

  /// Multiplier for speed / spawn density ramping.
  final double rampModifier;

  /// Coin / XP reward multiplier for finishing a run on this difficulty.
  final double rewardMultiplier;

  static DifficultyLevel fromId(String? id) =>
      values.firstWhere((d) => d.name == id, orElse: () => DifficultyLevel.normal);
}

/// Physical silhouette of a [PlayerSkin] (drives in-game + shop rendering).
enum SkinShape { orb, diamond, ring, hexagon }

/// Collectible power-ups.
enum PowerUpType { shield, slowMotion, coinMagnet, dash, scoreMultiplier }

/// Reward currencies / progression resources.
enum RewardType { coins, xp }
