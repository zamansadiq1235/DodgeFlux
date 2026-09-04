import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../models/player_progress.dart';
import '../../models/player_skin.dart';
import '../../models/zone_data.dart';
import '../../providers/providers.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';

/// Analytics tab: lifetime stats with count-up numbers, level progress and
/// a per-zone best-score chart.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(playerProgressProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          const NeonEntrance(
            child: Text(
              'ANALYTICS',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: NeonColors.textPrimary,
                shadows: [
                  Shadow(color: NeonColors.pink, blurRadius: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const NeonEntrance(
            delay: Duration(milliseconds: 60),
            child: Text(
              'Your run history across every zone.',
              style: TextStyle(color: NeonColors.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 18),
          _LevelCard(progress: progress),
          const SizedBox(height: 18),
          _StatGrid(progress: progress),
          const SizedBox(height: 24),
          _ZoneBests(progress: progress),
          const SizedBox(height: 24),
          NeonEntrance(
            delay: const Duration(milliseconds: 300),
            child: NeonCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Skins owned',
                    style: TextStyle(color: NeonColors.textSecondary),
                  ),
                  Text(
                    '${progress.ownedSkinIds.length}/${PlayerSkin.all.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: NeonColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    return NeonEntrance(
      delay: const Duration(milliseconds: 80),
      child: NeonCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Level ${progress.level}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: NeonColors.textPrimary,
                  ),
                ),
                NeonCountUp(
                  value: progress.xpIntoCurrentLevel,
                  format: (v) => '$v/${progress.xpForNextLevel} XP',
                  style: const TextStyle(color: NeonColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.levelProgress,
                minHeight: 10,
                backgroundColor: NeonColors.gridLine,
                valueColor: const AlwaysStoppedAnimation(NeonColors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final survival = progress.totalSurvivalSeconds.round();
    final mins = survival ~/ 60;
    final secs = survival % 60;

    final stats = <(String, int, Color, String?)>[
      ('BEST SCORE', progress.highScore, NeonColors.coin, null),
      ('TOTAL RUNS', progress.totalRuns, NeonColors.blue, null),
      ('COINS EARNED', progress.totalCoinsEarned, NeonColors.coin, null),
      (
        'SURVIVED',
        0,
        NeonColors.shield,
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}'
      ),
      ('SHIFTS USED', progress.totalShiftsUsed, NeonColors.slowMo, null),
      ('MISSIONS DONE', progress.missionsCompleted, NeonColors.pink, null),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.45,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final (label, value, color, custom) = stats[index];
        return NeonEntrance(
          delay: Duration(milliseconds: 90 + index * 45),
          child: NeonCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: NeonColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                if (custom != null)
                  Text(
                    custom,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  )
                else
                  NeonCountUp(
                    value: value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
class _ZoneBests extends StatelessWidget {
  const _ZoneBests({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final bests = ZoneData.all
        .map((z) => (z, progress.bestScorePerZone[z.id] ?? 0))
        .toList();
    final maxBest = bests.fold<int>(1, (m, e) => e.$2 > m ? e.$2 : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const NeonEntrance(
          delay: Duration(milliseconds: 220),
          child: NeonSectionHeader('ZONE BESTS', color: NeonColors.coin),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < bests.length; i++)
          NeonEntrance(
            delay: Duration(milliseconds: 240 + i * 50),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NeonCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bests[i].$1.accentColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bests[i].$1.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: bests[i].$2 / maxBest),
                              duration: Duration(milliseconds: 300 + i * 80),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, _) => LinearProgressIndicator(
                                value: v,
                                minHeight: 6,
                                backgroundColor: NeonColors.gridLine,
                                valueColor: AlwaysStoppedAnimation(
                                    bests[i].$1.accentColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${bests[i].$2}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: NeonColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}