import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../providers/providers.dart';
import 'animations.dart';

/// Row of difficulty chips bound to the persisted [gameSettingsProvider].
class DifficultySelector extends ConsumerWidget {
  const DifficultySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(gameSettingsProvider).difficulty;
    return Row(
      children: [
        for (final level in DifficultyLevel.values) ...[
          Expanded(
            child: _DifficultyChip(
              level: level,
              selected: level == selected,
              onTap: level == selected
                  ? null
                  : () => ref
                      .read(gameSettingsProvider.notifier)
                      .setDifficulty(level),
            ),
          ),
          if (level != DifficultyLevel.values.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final DifficultyLevel level;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(level);
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : NeonColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : NeonColors.gridLine,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 14)]
              : null,
        ),
        child: Column(
          children: [
            Text(
              level.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? color : NeonColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'x${level.rewardMultiplier}',
              style: TextStyle(
                fontSize: 10,
                color: selected ? color : NeonColors.gridLine,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return NeonColors.shield;
      case DifficultyLevel.normal:
        return NeonColors.blue;
      case DifficultyLevel.hard:
        return NeonColors.coin;
      case DifficultyLevel.insane:
        return NeonColors.danger;
    }
  }
}