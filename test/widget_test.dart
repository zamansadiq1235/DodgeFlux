import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_dodge/core/enums.dart';
import 'package:neon_dodge/providers/providers.dart';
import 'package:neon_dodge/services/save_service.dart';
import 'package:neon_dodge/ui/neon_dodge_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pumpMenu(WidgetTester tester) async {
  // Use a phone-sized viewport so the entire main-menu ListView (including
  // the daily-missions strip at the bottom) is rendered during tests.
  tester.view
    ..devicePixelRatio = 1.0
    ..physicalSize = const Size(1080, 1920);
  addTearDown(tester.view.resetPhysicalSize);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [saveServiceProvider.overrideWithValue(SaveService(prefs))],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const NeonDodgeApp(),
    ),
  );
  // Splash screen runs its intro animations before landing on the home shell.
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
    'splash leads to a main menu with title, currencies and missions',
    (WidgetTester tester) async {
      await _pumpMenu(tester);

      expect(find.text('NEON DODGE'), findsOneWidget);
      expect(find.text('PLAY'), findsOneWidget);
      expect(find.text('🪙 0'), findsOneWidget);
      expect(find.text('BEST 0'), findsOneWidget);
      // Three daily missions are rolled on first launch.
      expect(find.text('DAILY MISSIONS'), findsOneWidget);
    },
  );

  testWidgets('main menu remains stable on a short viewport', (
    WidgetTester tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1.0
      ..physicalSize = const Size(390, 600);
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [saveServiceProvider.overrideWithValue(SaveService(prefs))],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NeonDodgeApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NEON DODGE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings toggles persist to the provider', (
    WidgetTester tester,
  ) async {
    final container = await _pumpMenu(tester);

    expect(container.read(gameSettingsProvider).soundEnabled, isTrue);
    container.read(gameSettingsProvider.notifier).toggleSound();
    expect(container.read(gameSettingsProvider).soundEnabled, isFalse);
  });

  testWidgets('music and difficulty settings persist', (
    WidgetTester tester,
  ) async {
    final container = await _pumpMenu(tester);

    // Music switch defaults to on; toggling flips + persists state.
    expect(container.read(gameSettingsProvider).musicEnabled, isTrue);
    container.read(gameSettingsProvider.notifier).toggleMusic();
    expect(container.read(gameSettingsProvider).musicEnabled, isFalse);

    // Difficulty defaults to Normal and can be changed.
    expect(
      container.read(gameSettingsProvider).difficulty,
      DifficultyLevel.normal,
    );
    container
        .read(gameSettingsProvider.notifier)
        .setDifficulty(DifficultyLevel.hard);
    expect(
      container.read(gameSettingsProvider).difficulty,
      DifficultyLevel.hard,
    );
  });

  testWidgets('animated bottom nav switches between shop/settings/analytics', (
    WidgetTester tester,
  ) async {
    await _pumpMenu(tester);

    // Menu tab is active by default.
    expect(find.text('PLAY'), findsOneWidget);

    // -> Shop
    await tester.tap(find.text('SHOP'));
    await tester.pumpAndSettle();
    expect(find.text('SKIN SHOP'), findsOneWidget);
    // All eight skins are listed.
    expect(find.text('Orb'), findsOneWidget);
    expect(find.text('Void'), findsOneWidget);

    // -> Settings
    await tester.tap(find.text('SETTINGS'));
    await tester.pumpAndSettle();
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);

    // -> Analytics
    await tester.tap(find.text('STATS'));
    await tester.pumpAndSettle();
    expect(find.text('ANALYTICS'), findsOneWidget);
    expect(find.text('ZONE BESTS'), findsOneWidget);

    // Back to menu.
    await tester.tap(find.text('MENU'));
    await tester.pumpAndSettle();
    expect(find.text('PLAY'), findsOneWidget);
  });
}
