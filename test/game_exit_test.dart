import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_dodge/core/enums.dart';
import 'package:neon_dodge/providers/providers.dart';
import 'package:neon_dodge/services/save_service.dart';
import 'package:neon_dodge/ui/neon_dodge_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> pumpMenu(WidgetTester tester) async {
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
    UncontrolledProviderScope(container: container, child: const NeonDodgeApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('exiting via the pause overlay MENU button does not throw',
      (tester) async {
    final container = await pumpMenu(tester);

    // Open the game screen. The running Flame game schedules a frame every
    // tick, so pumpAndSettle can never settle here - use stepped pumps.

    await tester.tap(find.text('PLAY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));


    // Game screen is up and the run has begun.


    expect(container.read(gameStatusProvider), GameStatus.playing);


    // Open the pause overlay and leave the run via its MENU button.


    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('MENU'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));


    // Back on the menu. Exiting the game screen must not have thrown.


    expect(find.text('PLAY'), findsOneWidget);
    expect(container.read(gameStatusProvider), GameStatus.menu);
  });

  testWidgets(
      'leaving via system back while paused does not throw', (tester) async {
    final container = await pumpMenu(tester);


    await tester.tap(find.text('PLAY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(gameStatusProvider), GameStatus.playing);


    // Pause, then leave the game screen with the system back gesture. The
    // screen is disposed while status is still `paused` (no `_exitToMenu`,
    // which pre-sets `menu`), exactly the path that crash with Riverpod's
    // "Tried to modify a provider while the widget tree was building".

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(gameStatusProvider), GameStatus.paused);


    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));


    // No exception was thrown and the status was reset after the frame.

    expect(find.text('PLAY'), findsOneWidget);
    expect(container.read(gameStatusProvider), GameStatus.menu);
  });
}