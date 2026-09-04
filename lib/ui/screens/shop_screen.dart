import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../models/player_skin.dart';
import '../../providers/providers.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import '../widgets/skin_preview.dart';

/// Full-screen skin shop: an animated grid of every skin with buy / equip.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(playerProgressProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          NeonEntrance(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SKIN SHOP',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: NeonColors.textPrimary,
                    shadows: [Shadow(color: NeonColors.pink, blurRadius: 18)],
                  ),
                ),
                NeonPill(
                  label: '🪙 ${progress.totalCoins}',
                  color: NeonColors.coin,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const NeonEntrance(
            delay: Duration(milliseconds: 60),
            child: Text(
              'Outfit your core. Every skin changes how your ship renders in-game.',
              style: TextStyle(color: NeonColors.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 10,
              crossAxisSpacing: 12,
              childAspectRatio: 0.73,
            ),
            itemCount: PlayerSkin.all.length,
            itemBuilder: (context, index) {
              final skin = PlayerSkin.all[index];
              return NeonEntrance(
                delay: Duration(milliseconds: 80 + index * 50),
                child: _SkinTile(
                  skin: skin,
                  owned: progress.ownedSkinIds.contains(skin.id),
                  selected: progress.selectedSkinId == skin.id,
                  affordable: progress.totalCoins >= skin.cost,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SkinTile extends ConsumerWidget {
  const _SkinTile({
    required this.skin,
    required this.owned,
    required this.selected,
    required this.affordable,
  });

  final PlayerSkin skin;
  final bool owned;
  final bool selected;
  final bool affordable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borderColor = selected
        ? skin.trailColor
        : (owned
              ? skin.trailColor.withValues(alpha: 0.4)
              : NeonColors.gridLine);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NeonColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: selected ? 2 : 1),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: skin.trailColor.withValues(alpha: 0.35),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SkinPreview(skin: skin, size: 76),
          const SizedBox(height: 8),
          Text(
            skin.name,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: NeonColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            skin.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: NeonColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (selected)
            const Pill(label: 'EQUIPPED', color: NeonColors.shield)
          else if (owned)
            SmallButton(
              label: 'EQUIP',
              color: skin.trailColor,
              onPressed: () =>
                  ref.read(playerProgressProvider.notifier).selectSkin(skin.id),
            )
          else
            SmallButton(
              label: 'BUY · ${skin.cost} 🪙',
              color: affordable ? NeonColors.coin : NeonColors.gridLine,
              onPressed: affordable
                  ? () {
                      final bought = ref
                          .read(playerProgressProvider.notifier)
                          .buySkin(skin);
                      if (!bought && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Not enough coins')),
                        );
                      }
                    }
                  : null,
            ),
        ],
      ),
    );
  }
}
