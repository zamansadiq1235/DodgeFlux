import '../core/constants.dart';
import '../core/enums.dart';

/// Live stats of a single run, updated by the game and shown in the HUD.
class RunSession {
  const RunSession({
    this.score = 0,
    this.coins = 0,
    this.survivalTime = 0,
    this.shiftsUsed = 0,
    this.shieldActive = false,
    this.slowMoRemaining = 0,
    this.magnetRemaining = 0,
    this.multiplierRemaining = 0,
    this.dashRemaining = 0,
    this.activeDimension = NeonDimension.blue,
    this.shiftCooldownProgress = 1,
    this.comboCount = 0,
  });

  final int score;
  final int coins;
  final double survivalTime;
  final int shiftsUsed;
  final bool shieldActive;
  final double slowMoRemaining;
  final double magnetRemaining;
  final double multiplierRemaining;
  final double dashRemaining;

  /// Active Neon Shift dimension (drives the HUD indicator).
  final NeonDimension activeDimension;

  /// 1 = shift ready, 0 = just used. Drives the shift button ring.
  final double shiftCooldownProgress;

  /// Current combo count (prototype).
  final int comboCount;

  RunSession copyWith({
    int? score,
    int? coins,
    double? survivalTime,
    int? shiftsUsed,
    bool? shieldActive,
    double? slowMoRemaining,
    double? magnetRemaining,
    double? multiplierRemaining,
    double? dashRemaining,
    double? shiftCooldownProgress,
    NeonDimension? activeDimension,
    int? comboCount,
  }) {
    return RunSession(
      score: score ?? this.score,
      coins: coins ?? this.coins,
      survivalTime: survivalTime ?? this.survivalTime,
      shiftsUsed: shiftsUsed ?? this.shiftsUsed,
      shieldActive: shieldActive ?? this.shieldActive,
      slowMoRemaining: slowMoRemaining ?? this.slowMoRemaining,
      magnetRemaining: magnetRemaining ?? this.magnetRemaining,
      multiplierRemaining: multiplierRemaining ?? this.multiplierRemaining,
      dashRemaining: dashRemaining ?? this.dashRemaining,
      activeDimension: activeDimension ?? this.activeDimension,
      shiftCooldownProgress:
          shiftCooldownProgress ?? this.shiftCooldownProgress,
      comboCount: comboCount ?? this.comboCount,
    );
  }
}

/// Immutable summary produced when a run ends — fed into progression,
/// missions and the Game Over screen.
class RunResult {
  const RunResult({
    required this.score,
    required this.coinsCollected,
    required this.survivalTime,
    required this.shiftsUsed,
    required this.isNewHighScore,
    this.rewardMultiplier = 1.0,
    this.difficultyLabel = 'Normal',
  });

  final int score;
  final int coinsCollected;
  final double survivalTime;
  final int shiftsUsed;
  final bool isNewHighScore;

  /// Higher difficulties pay more. Multiplies earned coins + XP.
  final double rewardMultiplier;

  /// Display label of the difficulty this run was played on.
  final String difficultyLabel;

  /// Coins from pickups plus a small survival bonus.
  int get coinsEarned =>
      ((coinsCollected + (survivalTime / 10).floor()) * rewardMultiplier)
          .round();

  int get xpEarned =>
      ((coinsCollected * GameTuning.xpPerCoin +
                  survivalTime * GameTuning.xpPerSecondSurvived) *
              rewardMultiplier)
          .round();
}
