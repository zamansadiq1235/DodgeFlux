import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/game_settings.dart';
import '../providers/providers.dart';
import '../services/music_service.dart';
import 'screens/splash_screen.dart';

/// App root: dark neon Material 3 theme (UI/UX Design Brief).
///
/// Listens to the persisted music setting so toggling it anywhere in the app
/// immediately starts/stops the background loop.
class NeonDodgeApp extends ConsumerStatefulWidget {
  const NeonDodgeApp({super.key});

  @override
  ConsumerState<NeonDodgeApp> createState() => _NeonDodgeAppState();
}

class _NeonDodgeAppState extends ConsumerState<NeonDodgeApp> {
  @override
  Widget build(BuildContext context) {
    ref.listen<GameSettings>(gameSettingsProvider, (_, next) {
      MusicService.instance.setEnabled(next.musicEnabled);
    });

    return MaterialApp(
      title: 'Neon Dodge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: NeonColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: NeonColors.blue,
          brightness: Brightness.dark,
          surface: NeonColors.background,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
