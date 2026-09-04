import 'package:flutter/material.dart';

import '../../core/constants.dart';
import 'animations.dart';

class NavItemSpec {
  const NavItemSpec({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color color;
}

const List<NavItemSpec> homeNavItems = [
  NavItemSpec(
    label: 'MENU',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    color: NeonColors.blue,
  ),
  NavItemSpec(
    label: 'SHOP',
    icon: Icons.storefront_outlined,
    activeIcon: Icons.storefront_rounded,
    color: NeonColors.coin,
  ),
  NavItemSpec(
    label: 'SETTINGS',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    color: NeonColors.slowMo,
  ),
  NavItemSpec(
    label: 'STATS',
    icon: Icons.insights_outlined,
    activeIcon: Icons.insights_rounded,
    color: NeonColors.pink,
  ),
];

/// Animated neon bottom navigation bar: a glowing pill glides smoothly to
/// the active tab while icons scale and labels highlight dynamically.
class NeonBottomNav extends StatelessWidget {
  const NeonBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final activeItem = homeNavItems[currentIndex];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: NeonColors.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: NeonColors.gridLine),
          boxShadow: [
            BoxShadow(
              color: activeItem.color.withValues(alpha: 0.25),
              blurRadius: 22,
              spreadRadius: 1,
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / homeNavItems.length;

            return SizedBox(
              height: 58,
              child: Stack(
                children: [
                  // Sliding Glowing Pill Background
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment(
                      -1.0 + (currentIndex / (homeNavItems.length - 1)) * 2.0,
                      0.0,
                    ),
                    child: Container(
                      width: itemWidth,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: activeItem.color.withValues(alpha: 0.15),
                        border: Border.all(
                          color: activeItem.color.withValues(alpha: 0.60),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),

                  // Navigation Items Row
                  Row(
                    children: [
                      for (var i = 0; i < homeNavItems.length; i++)
                        Expanded(
                          child: _NavItem(
                            spec: homeNavItems[i],
                            selected: i == currentIndex,
                            onTap: () => onTap(i),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final NavItemSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = selected ? spec.color : NeonColors.textSecondary;

    return Semantics(
      selected: selected,
      label: spec.label,
      button: true,
      child: PressableScale(
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 1.0, end: selected ? 1.18 : 1.0),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    selected ? spec.activeIcon : spec.icon,
                    key: ValueKey<String>('${spec.label}_$selected'),
                    size: 22,
                    color: activeColor,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.8,
                  color: activeColor,
                ),
                child: Text(spec.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
