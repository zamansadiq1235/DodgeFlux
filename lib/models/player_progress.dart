import '../core/constants.dart';

/// Persistent player meta-progression: currencies, level, unlocks and records.
class PlayerProgress {
  const PlayerProgress({
    this.totalCoins = 0,
    this.xp = 0,
    this.level = 1,
    this.highScore = 0,
    this.totalRuns = 0,
    this.selectedSkinId = 'orb',
    this.currentZoneId = 'neon_city',
    this.unlockedZoneIds = const ['neon_city'],
    this.ownedSkinIds = const ['orb'],
    this.loginStreak = 0,
    this.lastPlayedUtc = 0,
    this.totalCoinsEarned = 0,
    this.totalShiftsUsed = 0,
    this.totalSurvivalSeconds = 0.0,
    this.missionsCompleted = 0,
    this.bestScorePerZone = const {},
  });

  final int totalCoins;
  final int xp;
  final int level;
  final int highScore;
  final int totalRuns;
  final String selectedSkinId;
  final String currentZoneId;
  final List<String> unlockedZoneIds;
  final List<String> ownedSkinIds;

  /// Consecutive-day streak, used for streak rewards.
  final int loginStreak;

  /// Epoch millis of last completed run / session (for streak + dailies).
  final int lastPlayedUtc;

  // ---- Lifetime analytics (shown in the Analytics tab) ----
  final int totalCoinsEarned;
  final int totalShiftsUsed;
  final double totalSurvivalSeconds;
  final int missionsCompleted;

  /// Best score ever achieved per zone id.
  final Map<String, int> bestScorePerZone;

  int get xpIntoCurrentLevel => xp.clamp(0, xpForNextLevel);

  int get xpForNextLevel => xpRequiredForLevel(level);

  double get levelProgress {
    final threshold = xpForNextLevel;
    if (threshold <= 0) return 0;
    return (xpIntoCurrentLevel / threshold).clamp(0.0, 1.0).toDouble();
  }

  PlayerProgress copyWith({
    int? totalCoins,
    int? xp,
    int? level,
    int? highScore,
    int? totalRuns,
    String? selectedSkinId,
    String? currentZoneId,
    List<String>? unlockedZoneIds,
    List<String>? ownedSkinIds,
    int? loginStreak,
    int? lastPlayedUtc,
    int? totalCoinsEarned,
    int? totalShiftsUsed,
    double? totalSurvivalSeconds,
    int? missionsCompleted,
    Map<String, int>? bestScorePerZone,
  }) {
    return PlayerProgress(
      totalCoins: totalCoins ?? this.totalCoins,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      highScore: highScore ?? this.highScore,
      totalRuns: totalRuns ?? this.totalRuns,
      selectedSkinId: selectedSkinId ?? this.selectedSkinId,
      currentZoneId: currentZoneId ?? this.currentZoneId,
      unlockedZoneIds: unlockedZoneIds ?? this.unlockedZoneIds,
      ownedSkinIds: ownedSkinIds ?? this.ownedSkinIds,
      loginStreak: loginStreak ?? this.loginStreak,
      lastPlayedUtc: lastPlayedUtc ?? this.lastPlayedUtc,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      totalShiftsUsed: totalShiftsUsed ?? this.totalShiftsUsed,
      totalSurvivalSeconds: totalSurvivalSeconds ?? this.totalSurvivalSeconds,
      missionsCompleted: missionsCompleted ?? this.missionsCompleted,
      bestScorePerZone: bestScorePerZone ?? this.bestScorePerZone,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalCoins': totalCoins,
    'xp': xp,
    'level': level,
    'highScore': highScore,
    'totalRuns': totalRuns,
    'selectedSkinId': selectedSkinId,
    'currentZoneId': currentZoneId,
    'unlockedZoneIds': unlockedZoneIds,
    'ownedSkinIds': ownedSkinIds,
    'loginStreak': loginStreak,
    'lastPlayedUtc': lastPlayedUtc,
    'totalCoinsEarned': totalCoinsEarned,
    'totalShiftsUsed': totalShiftsUsed,
    'totalSurvivalSeconds': totalSurvivalSeconds,
    'missionsCompleted': missionsCompleted,
    'bestScorePerZone': bestScorePerZone,
  };

  factory PlayerProgress.fromJson(Map<String, dynamic> json) {
    return PlayerProgress(
      totalCoins: (json['totalCoins'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      highScore: (json['highScore'] as num?)?.toInt() ?? 0,
      totalRuns: (json['totalRuns'] as num?)?.toInt() ?? 0,
      selectedSkinId: json['selectedSkinId'] as String? ?? 'orb',
      currentZoneId: json['currentZoneId'] as String? ?? 'neon_city',
      unlockedZoneIds:
          (json['unlockedZoneIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['neon_city'],
      ownedSkinIds:
          (json['ownedSkinIds'] as List?)?.map((e) => e.toString()).toList() ??
          const ['orb'],
      loginStreak: (json['loginStreak'] as num?)?.toInt() ?? 0,
      lastPlayedUtc: (json['lastPlayedUtc'] as num?)?.toInt() ?? 0,
      totalCoinsEarned: (json['totalCoinsEarned'] as num?)?.toInt() ?? 0,
      totalShiftsUsed: (json['totalShiftsUsed'] as num?)?.toInt() ?? 0,
      totalSurvivalSeconds:
          (json['totalSurvivalSeconds'] as num?)?.toDouble() ?? 0,
      missionsCompleted: (json['missionsCompleted'] as num?)?.toInt() ?? 0,
      bestScorePerZone:
          (json['bestScorePerZone'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ) ??
          const {},
    );
  }
}
