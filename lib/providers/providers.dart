import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../core/constants.dart';
import '../core/enums.dart';
import '../core/utils.dart';
import '../game/run_session.dart';
import '../models/game_settings.dart';
import '../models/mission_data.dart';
import '../models/player_progress.dart';
import '../models/player_skin.dart';
import '../models/zone_data.dart';
import '../services/save_service.dart';

/// Provided via ProviderScope overrides after async SharedPreferences init.
final saveServiceProvider = Provider<SaveService>(
  (ref) => throw UnimplementedError(
    'saveServiceProvider must be overridden with an initialized SaveService',
  ),
);

// ---------------------------------------------------------------------------
// Game status (menu, loading, playing, paused, gameOver, reward)
// ---------------------------------------------------------------------------

class GameStatusNotifier extends Notifier<GameStatus> {
  @override
  GameStatus build() => GameStatus.menu;

  void toPlaying() => state = GameStatus.playing;
  void pause() => state = GameStatus.paused;
  void resume() => state = GameStatus.playing;
  void gameOver() => state = GameStatus.gameOver;
  void toMenu() => state = GameStatus.menu;
}

final gameStatusProvider = NotifierProvider<GameStatusNotifier, GameStatus>(
  GameStatusNotifier.new,
);

/// Result of the last finished run (for the Game Over overlay).
final lastRunProvider = StateProvider<RunResult?>((ref) => null);

/// Celebration messages from the last run (level ups, unlocks, streaks).
final runCelebrationsProvider = StateProvider<List<String>>((ref) => const []);

// ---------------------------------------------------------------------------
// Player progress: coins, XP, level, unlocks, streaks
// ---------------------------------------------------------------------------

class PlayerProgressNotifier extends Notifier<PlayerProgress> {
  @override
  PlayerProgress build() => ref.read(saveServiceProvider).loadProgress();

  void _save() => ref.read(saveServiceProvider).saveProgress(state);

  /// Applies a finished run and returns celebration messages.
  List<String> applyRunResult(RunResult result) {
    final celebrations = <String>[];
    final p = state;

    // Daily streak (hybrid-casual retention mechanic).
    final today = dayKeyOf(DateTime.now());
    final lastDay = p.lastPlayedUtc == 0
        ? null
        : dayKeyOf(DateTime.fromMillisecondsSinceEpoch(p.lastPlayedUtc));
    final sameDay = lastDay == today;
    final isYesterday =
        lastDay == dayKeyOf(DateTime.now().subtract(const Duration(days: 1)));
    final streak = sameDay
        ? max(1, p.loginStreak)
        : (isYesterday ? p.loginStreak + 1 : 1);
    final streakBonus = sameDay ? 0 : min(streak, 7) * 10;
    if (streakBonus > 0) {
      celebrations.add('Daily streak x$streak: +$streakBonus coins!');
    }

    final coins = p.totalCoins + result.coinsEarned + streakBonus;
    var xp = p.xp + result.xpEarned;
    var level = p.level;
    var leveledUp = false;
    while (xp >= xpRequiredForLevel(level)) {
      xp -= xpRequiredForLevel(level);
      level++;
      leveledUp = true;
    }
    if (leveledUp) celebrations.add('Level up! You are now level $level');

    // Zone unlocks driven by level.
    var zones = p.unlockedZoneIds;
    for (final z in ZoneData.all) {
      if (!zones.contains(z.id) && level >= z.requiredLevel) {
        zones = [...zones, z.id];
        celebrations.add('New zone unlocked: ${z.name}!');
      }
    }

    if (result.isNewHighScore && p.highScore > 0) {
      celebrations.add('New personal best: ${result.score}!');
    }

    state = p.copyWith(
      totalCoins: coins,
      xp: xp,
      level: level,
      highScore: max(p.highScore, result.score),
      totalRuns: p.totalRuns + 1,
      unlockedZoneIds: zones,
      loginStreak: streak,
      lastPlayedUtc: DateTime.now().millisecondsSinceEpoch,
    );
    _save();

    // Lifetime analytics counters.
    recordRunAnalytics(result);

    // Missions progress.
    ref.read(dailyMissionsProvider.notifier).applyRunResult(result);
    return celebrations;
  }

  void addCoins(int amount) {
    state = state.copyWith(totalCoins: state.totalCoins + amount);
    _save();
  }

  /// Updates lifelong analytic counters after a finished run.
  void recordRunAnalytics(RunResult result) {
    final previousZoneBest = state.bestScorePerZone[state.currentZoneId] ?? 0;
    state = state.copyWith(
      totalCoinsEarned: state.totalCoinsEarned + result.coinsEarned,
      totalShiftsUsed: state.totalShiftsUsed + result.shiftsUsed,
      totalSurvivalSeconds:
          state.totalSurvivalSeconds + result.survivalTime.clamp(0, 60 * 60),
      bestScorePerZone: {
        ...state.bestScorePerZone,
        state.currentZoneId: max(previousZoneBest, result.score),
      },
    );
    _save();
  }

  void addMissionCompleted() {
    state = state.copyWith(missionsCompleted: state.missionsCompleted + 1);
    _save();
  }

  void selectZone(String zoneId) {
    if (!state.unlockedZoneIds.contains(zoneId)) return;
    state = state.copyWith(currentZoneId: zoneId);
    _save();
  }

  void selectSkin(String skinId) {
    if (!state.ownedSkinIds.contains(skinId)) return;
    state = state.copyWith(selectedSkinId: skinId);
    _save();
  }

  bool buySkin(PlayerSkin skin) {
    if (state.ownedSkinIds.contains(skin.id)) return false;
    if (state.totalCoins < skin.cost) return false;
    state = state.copyWith(
      totalCoins: state.totalCoins - skin.cost,
      ownedSkinIds: [...state.ownedSkinIds, skin.id],
      selectedSkinId: skin.id,
    );
    _save();
    return true;
  }
}

final playerProgressProvider =
    NotifierProvider<PlayerProgressNotifier, PlayerProgress>(
      PlayerProgressNotifier.new,
    );

// ---------------------------------------------------------------------------
// Daily missions
// ---------------------------------------------------------------------------

class DailyMissionsNotifier extends Notifier<DailyMissionState> {
  @override
  DailyMissionState build() {
    final save = ref.read(saveServiceProvider);
    final today = dayKeyOf(DateTime.now());
    final stored = save.loadMissions();
    if (stored == null ||
        stored.dateKey != today ||
        stored.missions.length < 3) {
      final rolled = _rollDaily(today);
      save.saveMissions(rolled);
      return rolled;
    }

    final normalized = _normalizeMissionState(stored);
    if (normalized != stored) {
      save.saveMissions(normalized);
    }
    return normalized;
  }

  DailyMissionState _normalizeMissionState(DailyMissionState state) {
    final missionMap = {
      for (final mission in state.missions) mission.id: mission,
    };
    final progress = <MissionProgress>[];
    for (final mission in state.missions) {
      final previous = state.progress.firstWhere(
        (p) => p.missionId == mission.id,
        orElse: () => MissionProgress(missionId: mission.id),
      );
      final derivedCompleted = previous.progressValue >= mission.targetValue;
      progress.add(
        previous.copyWith(isCompleted: previous.isClaimed || derivedCompleted),
      );
    }

    final validMissionIds = missionMap.keys.toSet();
    final filteredProgress = state.progress.where(
      (entry) => validMissionIds.contains(entry.missionId),
    );
    for (final entry in filteredProgress) {
      final mission = missionMap[entry.missionId];
      if (mission == null) continue;
      final completed =
          entry.isClaimed || entry.progressValue >= mission.targetValue;
      final index = progress.indexWhere((p) => p.missionId == entry.missionId);
      if (index >= 0) {
        progress[index] = progress[index].copyWith(
          progressValue: entry.progressValue,
          isCompleted: completed,
        );
      }
    }

    return DailyMissionState(
      dateKey: state.dateKey,
      missions: state.missions,
      progress: progress,
    );
  }

  /// Deterministic per day so app restarts keep the same missions.
  DailyMissionState _rollDaily(String today) {
    final pool = [...MissionData.dailyPool]..shuffle(Random(today.hashCode));
    final missions = pool.take(3).toList();
    return DailyMissionState(
      dateKey: today,
      missions: missions,
      progress: missions.map((m) => MissionProgress(missionId: m.id)).toList(),
    );
  }

  void applyRunResult(RunResult result) {
    final missions = state.missions;
    final progress = <MissionProgress>[];
    for (final p in state.progress) {
      final mission = missions.firstWhere((m) => m.id == p.missionId);
      var value = p.progressValue;
      switch (mission.type) {
        case MissionType.collectCoins:
          value += result.coinsCollected;
        case MissionType.surviveTime:
          value = max(value, result.survivalTime.round());
        case MissionType.shiftTimes:
          value += result.shiftsUsed;
        case MissionType.reachScore:
          value = max(value, result.score);
        case MissionType.finishRuns:
          value += 1;
      }
      progress.add(
        p.copyWith(
          progressValue: value,
          isCompleted: p.isClaimed || value >= mission.targetValue,
        ),
      );
    }
    state = _normalizeMissionState(
      DailyMissionState(
        dateKey: state.dateKey,
        missions: missions,
        progress: progress,
      ),
    );
    ref.read(saveServiceProvider).saveMissions(state);
  }

  bool claim(String missionId) {
    final idx = state.progress.indexWhere((p) => p.missionId == missionId);
    if (idx < 0) return false;
    final p = state.progress[idx];
    final mission = state.missions.firstWhere((m) => m.id == missionId);
    if (!p.isCompleted || p.isClaimed) return false;
    final updated = [...state.progress];
    updated[idx] = p.copyWith(isClaimed: true);
    state = DailyMissionState(
      dateKey: state.dateKey,
      missions: state.missions,
      progress: updated,
    );
    ref.read(saveServiceProvider).saveMissions(state);
    ref.read(playerProgressProvider.notifier).addCoins(mission.rewardCoins);
    ref.read(playerProgressProvider.notifier).addMissionCompleted();
    return true;
  }
}

final dailyMissionsProvider =
    NotifierProvider<DailyMissionsNotifier, DailyMissionState>(
      DailyMissionsNotifier.new,
    );

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

class GameSettingsNotifier extends Notifier<GameSettings> {
  @override
  GameSettings build() => ref.read(saveServiceProvider).loadSettings();

  void _save() => ref.read(saveServiceProvider).saveSettings(state);

  void toggleSound() {
    state = state.copyWith(soundEnabled: !state.soundEnabled);
    _save();
  }

  void toggleHaptics() {
    state = state.copyWith(hapticsEnabled: !state.hapticsEnabled);
    _save();
  }

  void toggleMusic() {
    state = state.copyWith(musicEnabled: !state.musicEnabled);
    _save();
  }

  void setDifficulty(DifficultyLevel difficulty) {
    if (state.difficulty == difficulty) return;
    state = state.copyWith(difficulty: difficulty);
    _save();
  }
}

final gameSettingsProvider =
    NotifierProvider<GameSettingsNotifier, GameSettings>(
      GameSettingsNotifier.new,
    );
