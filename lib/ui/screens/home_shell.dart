import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/constants.dart';
import '../widgets/neon_bottom_nav.dart';
import 'analytics_screen.dart';
import 'main_menu_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

/// State provider to hold the active bottom navigation bar tab index.
final homeNavIndexProvider = StateProvider<int>((ref) => 0);

/// Const list of pages to avoid rebuilding screen widgets unnecessarily.
const List<Widget> _pages = [
  MainMenuScreen(),
  ShopScreen(),
  SettingsScreen(),
  AnalyticsScreen(),
];

/// Root of the game UI: an animated bottom navigation bar switching between
/// the main menu, shop, settings, and analytics tabs.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeNavIndexProvider);

    return Scaffold(
      backgroundColor: NeonColors.background,
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 340),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.03, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(currentIndex),
            child: _pages[currentIndex],
          ),
        ),
      ),
      bottomNavigationBar: NeonBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(homeNavIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}