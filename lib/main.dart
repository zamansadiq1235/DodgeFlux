import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/providers.dart';
import 'services/save_service.dart';
import 'ui/neon_dodge_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persistence before the first frame so providers can read saves
  // synchronously in their build() (per the TDD save strategy).
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        saveServiceProvider.overrideWithValue(SaveService(prefs)),
      ],
      child: const NeonDodgeApp(),
    ),
  );
}
