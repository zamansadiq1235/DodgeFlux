import 'package:flutter/material.dart';

import 'enums.dart';

/// Neon palette + accessibility-friendly values used across game and UI.
class NeonColors {
  NeonColors._();

  static const Color background = Color(0xFF050510);
  static const Color surface = Color(0xFF0D0D1F);
  static const Color gridLine = Color(0xFF14142B);

  static const Color blue = Color(0xFF22D3EE);
  static const Color blueDim = Color(0x5522D3EE);
  static const Color pink = Color(0xFFF472B6);
  static const Color pinkDim = Color(0x55F472B6);

  static const Color coin = Color(0xFFFFD54A);
  static const Color shield = Color(0xFF7CFC00);
  static const Color slowMo = Color(0xFFB388FF);
  static const Color magnet = Color(0xFFFF8A65);
  static const Color dash = Color(0xFFFFFFFF);
  static const Color multiplier = Color(0xFFFFE082);

  static const Color danger = Color(0xFFFF5252);
  static const Color textPrimary = Color(0xFFF5F5FF);
  static const Color textSecondary = Color(0xFF9E9EC2);

  static Color forDimension(NeonDimension dimension) =>
      dimension == NeonDimension.blue ? blue : pink;

  static Color dimForDimension(NeonDimension dimension) =>
      dimension == NeonDimension.blue ? blueDim : pinkDim;

  static Color forPowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.shield:
        return shield;
      case PowerUpType.slowMotion:
        return slowMo;
      case PowerUpType.coinMagnet:
        return magnet;
      case PowerUpType.dash:
        return dash;
      case PowerUpType.scoreMultiplier:
        return multiplier;
    }
  }
}

/// Single place for gameplay tuning numbers.
class GameTuning {
  GameTuning._();

  // Player
  static const double playerRadius = 16.0;
  static const double playerYFraction = 0.82; // vertical anchor on screen
  static const double playerFollowSpeed = 14.0; // drag follow lerp factor

  // Neon Shift
  static const double shiftCooldown = 0.8; // seconds

  // Difficulty ramp
  static const double baseFallSpeed = 220.0;
  static const double maxFallSpeed = 620.0;
  static const double fallSpeedPerSecond = 7.0;

  static const double baseSpawnInterval = 1.1; // seconds between spawns
  static const double minSpawnInterval = 0.34;
  static const double spawnIntervalDecayPerSecond = 0.012;

  // Scoring
  static const double scorePerSecond = 10.0;
  static const int scorePerCoin = 25;
  static const int xpPerCoin = 2;
  static const double xpPerSecondSurvived = 1.5;

  // Power-ups
  static const double powerUpDuration = 6.0;
  static const double dashDuration = 0.45;
  static const double slowMotionFactor = 0.45;
  static const double magnetRadius = 170.0;
  static const double magnetPullSpeed = 520.0;
  static const double scoreMultiplierValue = 2.0;
  static const double powerUpSpawnChance = 0.10; // per spawn tick
  static const double coinSpawnChance = 0.55; // per spawn tick

  // Persistence keys
  static const String saveKeyProgress = 'neon_dodge_progress_v1';
  static const String saveKeySettings = 'neon_dodge_settings_v1';
  static const String saveKeyMissions = 'neon_dodge_missions_v1';
}

/// XP needed to go from [level] to [level] + 1 (gentle hybrid-casual curve).
int xpRequiredForLevel(int level) => 80 + (level - 1) * 45;
