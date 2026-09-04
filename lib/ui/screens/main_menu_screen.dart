// ignore_for_file: unused_element_parameter, unused_local_variable, unused_element, deprecated_member_use, unnecessary_underscores, strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../models/mission_data.dart';
import '../../models/zone_data.dart';
import '../../providers/providers.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import '../widgets/difficulty_selector.dart';
import 'game_screen.dart';

/// Main menu: Play, current zone, progression, missions, shop, settings
/// and currency summary (per the UI/UX brief).
class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(playerProgressProvider);
    final missions = ref.watch(dailyMissionsProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                NeonEntrance(
                  child: _buildHeader(progress.highScore, progress.totalCoins),
                ),
                const SizedBox(height: 24),
                NeonEntrance(
                  delay: const Duration(milliseconds: 70),
                  child: _buildLevelCard(progress),
                ),
                const SizedBox(height: 24),
                NeonEntrance(
                  delay: const Duration(milliseconds: 140),
                  child: _buildPlayButton(context, ref),
                ),
                const SizedBox(height: 24),
                NeonEntrance(
                  delay: const Duration(milliseconds: 190),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      NeonSectionHeader('DIFFICULTY'),
                      SizedBox(height: 10),
                      DifficultySelector(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                NeonEntrance(
                  delay: const Duration(milliseconds: 240),
                  child: _buildZoneSelector(context, ref),
                ),
                const SizedBox(height: 24),
                NeonEntrance(
                  delay: const Duration(milliseconds: 300),
                  child: _buildMissionsSection(ref, missions),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int highScore, int coins) {
    return Row(
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  'NEON DODGE',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: NeonColors.textPrimary,
                    shadows: [
                      Shadow(color: NeonColors.blue, blurRadius: 24),
                      Shadow(color: NeonColors.pink, blurRadius: 40),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Shift dimensions. Survive the grid.',
                style: TextStyle(color: NeonColors.textSecondary),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FittedBox(
                child: Pill(label: '🪙 $coins', color: NeonColors.coin),
              ),
              const SizedBox(height: 6),
              FittedBox(
                child: Pill(label: 'BEST $highScore', color: NeonColors.blue),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCard(progress) {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Level ${progress.level}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: NeonColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'XP ${progress.xpIntoCurrentLevel}/${progress.xpForNextLevel}',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: NeonColors.textSecondary),
                ),
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
          const SizedBox(height: 6),
          Text(
            '${progress.totalRuns} runs · streak ${progress.loginStreak} 🔥',
            style: const TextStyle(
              color: NeonColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context, WidgetRef ref) {
    final progress = ref.read(playerProgressProvider);
    return _AnimatedPlayButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => buildGameScreen(
              zoneId: progress.currentZoneId,
              skinId: progress.selectedSkinId,
            ),
          ),
        );
      },
    );
  }

  Widget _buildZoneSelector(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(playerProgressProvider);
    final compact = MediaQuery.sizeOf(context).height < 720;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('ZONES'),
        const SizedBox(height: 12),
        SizedBox(
          height: compact ? 104 : 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ZoneData.all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final zone = ZoneData.all[index];
              final unlocked = progress.unlockedZoneIds.contains(zone.id);
              final selected = progress.currentZoneId == zone.id;
              final starsCount = ((zone.difficultyModifier * 2).round()).clamp(
                1,
                4,
              );

              return GestureDetector(
                onTap: unlocked
                    ? () => ref
                          .read(playerProgressProvider.notifier)
                          .selectZone(zone.id)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: compact ? 128 : 145,
                  padding: EdgeInsets.all(compact ? 8 : 10),
                  decoration: BoxDecoration(
                    color: zone.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? zone.accentColor
                          : (unlocked
                                ? zone.accentColor.withValues(alpha: 0.3)
                                : NeonColors.gridLine),
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: zone.accentColor.withValues(alpha: 0.35),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  zone.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: compact ? 11 : 13,
                                    color: unlocked
                                        ? NeonColors.textPrimary
                                        : NeonColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: List.generate(
                                    4,
                                    (i) => Icon(
                                      Icons.star_rounded,
                                      size: compact ? 9 : 10,
                                      color: i < starsCount
                                          ? (unlocked
                                                ? zone.accentColor
                                                : NeonColors.textSecondary)
                                          : NeonColors.gridLine,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!unlocked)
                            Icon(
                              Icons.lock_outline_rounded,
                              size: compact ? 12 : 14,
                              color: NeonColors.textSecondary,
                            ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'BEST ${progress.bestScorePerZone[zone.id] ?? 0}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: compact ? 9 : 10,
                                fontWeight: FontWeight.w600,
                                color: NeonColors.textSecondary,
                              ),
                            ),
                          ),
                          if (unlocked)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 4 : 5,
                                vertical: compact ? 1 : 2,
                              ),
                              decoration: BoxDecoration(
                                color: zone.accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bolt_rounded,
                                    size: compact ? 8 : 10,
                                    color: zone.accentColor,
                                  ),
                                  Text(
                                    'SPEED',
                                    style: TextStyle(
                                      fontSize: compact ? 7 : 8,
                                      fontWeight: FontWeight.bold,
                                      color: zone.accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      if (unlocked)
                        Container(
                          width: double.infinity,
                          height: compact ? 18 : 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? zone.accentColor
                                : zone.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            selected ? 'SELECTED' : 'PLAY',
                            style: TextStyle(
                              color: selected ? Colors.black : zone.accentColor,
                              fontSize: compact ? 8 : 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      else
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'UNLOCK',
                                  style: TextStyle(
                                    fontSize: compact ? 7 : 8,
                                    fontWeight: FontWeight.w700,
                                    color: NeonColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  'LVL ${zone.requiredLevel}',
                                  style: TextStyle(
                                    fontSize: compact ? 7 : 8,
                                    fontWeight: FontWeight.w800,
                                    color: zone.accentColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (progress.level / zone.requiredLevel)
                                    .clamp(0.0, 1.0),
                                minHeight: compact ? 3 : 4,
                                backgroundColor: NeonColors.gridLine,
                                valueColor: AlwaysStoppedAnimation(
                                  zone.accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMissionsSection(WidgetRef ref, DailyMissionState missions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('DAILY MISSIONS'),
        const SizedBox(height: 10),
        ...missions.missions.map((mission) {
          final progressState = missions.progress.firstWhere(
            (p) => p.missionId == mission.id,
          );
          final value = progressState.progressValue.clamp(
            0,
            mission.targetValue,
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NeonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mission.title,
                          style: const TextStyle(
                            color: NeonColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (progressState.isClaimed)
                        const Pill(label: 'CLAIMED ✔', color: NeonColors.shield)
                      else if (progressState.isCompleted)
                        SmallButton(
                          label: 'CLAIM +${mission.rewardCoins}',
                          onPressed: () => ref
                              .read(dailyMissionsProvider.notifier)
                              .claim(mission.id),
                        )
                      else
                        Text(
                          '+${mission.rewardCoins} 🪙',
                          style: const TextStyle(color: NeonColors.coin),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progressState.isCompleted
                                ? 1
                                : value / mission.targetValue,
                            minHeight: 8,
                            backgroundColor: NeonColors.gridLine,
                            valueColor: const AlwaysStoppedAnimation(
                              NeonColors.pink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        progressState.isCompleted
                            ? 'DONE'
                            : '$value/${mission.targetValue}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: NeonColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _AnimatedPlayButton extends StatefulWidget {
  const _AnimatedPlayButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_AnimatedPlayButton> createState() => _AnimatedPlayButtonState();
}

class _AnimatedPlayButtonState extends State<_AnimatedPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_ctl.value);
        final scale = 1.0 + (0.06 * t);
        final glow = 8.0 + (18.0 * t);
        final pressScale = _pressed ? 0.94 : 1.0;
        return Transform.scale(
          scale: scale * pressScale,
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [NeonColors.blue, NeonColors.pink],
              ),
              boxShadow: [
                BoxShadow(
                  color: NeonColors.blue.withOpacity(0.28 * (0.6 + t * 0.8)),
                  blurRadius: glow,
                  spreadRadius: 1.5 * t,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: widget.onPressed,
                onTapDown: (_) => setState(() => _pressed = true),
                onTapUp: (_) => setState(() => _pressed = false),
                onTapCancel: () => setState(() => _pressed = false),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'PLAY',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Colors.white24, blurRadius: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
