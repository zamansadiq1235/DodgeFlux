import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_dodge/core/constants.dart';
import 'package:neon_dodge/core/enums.dart';
import 'package:neon_dodge/core/utils.dart';
import 'package:neon_dodge/game/neon_dodge_game.dart';
import 'package:neon_dodge/game/run_session.dart';
import 'package:neon_dodge/game/systems/difficulty_system.dart';
import 'package:neon_dodge/game/systems/neon_shift_system.dart';
import 'package:neon_dodge/game/systems/spawn_system.dart';
import 'package:neon_dodge/models/mission_data.dart';
import 'package:neon_dodge/models/player_progress.dart';
import 'package:neon_dodge/models/player_skin.dart';
import 'package:neon_dodge/models/zone_data.dart';
import 'package:neon_dodge/providers/providers.dart';
import 'package:neon_dodge/services/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('xpRequiredForLevel', () {
    test('follows the documented gentle curve', () {
      expect(xpRequiredForLevel(1), 80);
      expect(xpRequiredForLevel(2), 125);
      expect(xpRequiredForLevel(5), 260);
    });
  });

  group('RunResult', () {
    test('coins earned includes survival bonus', () {
      const result = RunResult(
        score: 500,
        coinsCollected: 12,
        survivalTime: 42.0,
        shiftsUsed: 3,
        isNewHighScore: false,
      );
      // floor(42 / 10) = 4 bonus coins.
      expect(result.coinsEarned, 16);
      // 12 * 2 XP per coin + 42 * 1.5 = 24 + 63.
      expect(result.xpEarned, 87);
    });
  });

  group('PlayerProgress', () {
    test(
      'tracks XP inside the current level instead of subtracting prior levels',
      () {
        const progress = PlayerProgress(level: 3, xp: 60);

        expect(progress.xpIntoCurrentLevel, 60);
        expect(progress.xpForNextLevel, xpRequiredForLevel(3));
        expect(
          progress.levelProgress,
          closeTo(60 / xpRequiredForLevel(3), 1e-9),
        );
      },
    );
  });

  group('NeonShiftSystem', () {
    test('starts in blue dimension, ready to shift', () {
      final system = NeonShiftSystem();
      expect(system.activeDimension, NeonDimension.blue);
      expect(system.canShift, isTrue);
    });

    test('toggles dimension and applies cooldown', () {
      final system = NeonShiftSystem();
      expect(system.tryShift(), isTrue);
      expect(system.activeDimension, NeonDimension.pink);
      expect(system.canShift, isFalse);

      // Cooldown elapses -> can shift again.
      system.update(GameTuning.shiftCooldown);
      expect(system.canShift, isTrue);
      expect(system.tryShift(), isTrue);
      expect(system.activeDimension, NeonDimension.blue);
    });

    test('matching dimension makes hazards safe', () {
      final system = NeonShiftSystem();
      // Blue active: blue hazards are safe, pink are dangerous.
      expect(system.isHazardSafe(NeonDimension.blue), isTrue);
      expect(system.isHazardSafe(NeonDimension.pink), isFalse);
    });
  });

  group('dimension coins (Neon Shift collectibility)', () {
    test('a coin is collectible only in its matching dimension', () {
      final system = NeonShiftSystem(); // starts in Blue
      // Same rule as hazards: matching dimension = collectible (safe).
      expect(system.isHazardSafe(NeonDimension.blue), isTrue);
      expect(system.isHazardSafe(NeonDimension.pink), isFalse);

      // Shift to Pink and the opposite holds — so to gather coins that live
      // in both dimensions the player must move through every dimension.
      system.tryShift();
      expect(system.isHazardSafe(NeonDimension.pink), isTrue);
      expect(system.isHazardSafe(NeonDimension.blue), isFalse);
    });
  });

  group('SpawnSystem coin lines', () {
    test(
      'coin lines are assigned a NeonDimension so coins spread across all',
      () {
        final spawn = SpawnSystem(random: Random(7));
        final difficulty = DifficultySystem();
        // Step until a coin line rolls; it must always carry a dimension.
        SpawnRequest? coinLine;
        for (var i = 0; i < 200 && coinLine == null; i++) {
          for (final req in spawn.update(2.0, difficulty)) {
            if (req.kind == SpawnKind.coinLine) coinLine = req;
          }
        }
        expect(coinLine, isNotNull);
        expect(coinLine!.dimension, isNotNull);
        expect(
          coinLine.dimension == NeonDimension.blue ||
              coinLine.dimension == NeonDimension.pink,
          isTrue,
        );
      },
    );
  });

  group('drag input', () {
    test(
      'updates both horizontal and vertical movement targets while running',
      () async {
        final game = NeonDodgeGame(
          zone: ZoneData.all.first,
          skin: PlayerSkin.all.first,
        );
        await game.onLoad();
        game.startRun();

        final startX = game.player.targetX;
        final startY = game.player.targetY;
        game.onPlayerDrag(30, -45);

        expect(game.player.targetX, startX + 30);
        expect(game.player.targetY, startY - 45);
      },
    );
  });

  group('daily missions', () {
    test(
      'completed missions can be claimed and count toward mission stats',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [
            saveServiceProvider.overrideWithValue(SaveService(prefs)),
          ],
        );
        addTearDown(container.dispose);

        final mission = MissionData.dailyPool.first;
        final notifier = container.read(dailyMissionsProvider.notifier);
        notifier.state = DailyMissionState(
          dateKey: dayKeyOf(DateTime.now()),
          missions: [mission],
          progress: [
            MissionProgress(
              missionId: mission.id,
              progressValue: mission.targetValue,
              isCompleted: true,
              isClaimed: false,
            ),
          ],
        );

        expect(notifier.claim(mission.id), isTrue);
        expect(notifier.state.progress.first.isClaimed, isTrue);
        expect(
          container.read(playerProgressProvider).totalCoins,
          mission.rewardCoins,
        );
        expect(container.read(playerProgressProvider).missionsCompleted, 1);
      },
    );
  });

  group('dayKeyOf', () {
    test('formats local dates as yyyy-MM-dd', () {
      expect(dayKeyOf(DateTime(2026, 8, 28)), '2026-08-28');
      expect(dayKeyOf(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });
}
