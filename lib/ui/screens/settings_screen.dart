import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../providers/providers.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import '../widgets/difficulty_selector.dart';

/// Full-screen settings: audio (incl. the new music switch), haptics and
/// the run difficulty selector.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(gameSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          const NeonEntrance(
            child: Text(
              'SETTINGS',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: NeonColors.textPrimary,
                shadows: [
                  Shadow(color: NeonColors.blue, blurRadius: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          NeonEntrance(
            delay: const Duration(milliseconds: 60),
            child: NeonCard(
              child: Column(
                children: [
                  _NeonSwitchTile(
                    icon: Icons.music_note_rounded,
                    title: 'Music',
                    subtitle: 'Neon synth loops while you play',
                    value: settings.musicEnabled,
                    color: NeonColors.slowMo,
                    onChanged: (_) =>
                        ref.read(gameSettingsProvider.notifier).toggleMusic(),
                  ),
                  const Divider(color: NeonColors.gridLine, height: 1),
                  _NeonSwitchTile(
                    icon: Icons.graphic_eq_rounded,
                    title: 'Sound FX',
                    subtitle: 'Haptic blips and feedback',
                    value: settings.soundEnabled,
                    color: NeonColors.blue,
                    onChanged: (_) =>
                        ref.read(gameSettingsProvider.notifier).toggleSound(),
                  ),
                  const Divider(color: NeonColors.gridLine, height: 1),
                  _NeonSwitchTile(
                    icon: Icons.vibration_rounded,
                    title: 'Haptics',
                    subtitle: 'Vibration on hits and pickups',
                    value: settings.hapticsEnabled,
                    color: NeonColors.pink,
                    onChanged: (_) =>
                        ref.read(gameSettingsProvider.notifier).toggleHaptics(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          NeonEntrance(
            delay: const Duration(milliseconds: 120),
            child: const NeonSectionHeader('DIFFICULTY'),
          ),
          const SizedBox(height: 10),
          NeonEntrance(
            delay: const Duration(milliseconds: 160),
            child: const DifficultySelector(),
          ),
          const SizedBox(height: 10),
          const NeonEntrance(
            delay: Duration(milliseconds: 200),
            child: Text(
              'Difficulties scale hazard speed and density - and multiply '
              'coin/XP rewards.',
              style: TextStyle(color: NeonColors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          const NeonEntrance(
            delay: Duration(milliseconds: 240),
            child: NeonCard(
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: NeonColors.textSecondary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Neon Dodge v1.0.0\nRetro Arcade Build - made with Flame & Riverpod',
                      style: TextStyle(
                        color: NeonColors.textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
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

class _NeonSwitchTile extends StatelessWidget {
  const _NeonSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: NeonColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: NeonColors.textSecondary),
      ),
      trailing: Switch(
        activeThumbColor: color,
        activeTrackColor: color.withValues(alpha: 0.35),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
