import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/game_settings.dart';
import '../models/mission_data.dart';
import '../models/player_progress.dart';

/// Local persistence (MVP has no backend — see Backend Schema in the docs).
class SaveService {
  SaveService(this._prefs);

  final SharedPreferences _prefs;

  static Future<SaveService> init() async =>
      SaveService(await SharedPreferences.getInstance());

  PlayerProgress loadProgress() {
    final raw = _prefs.getString(GameTuning.saveKeyProgress);
    if (raw == null) return const PlayerProgress();
    try {
      return PlayerProgress.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return const PlayerProgress();
    }
  }

  Future<void> saveProgress(PlayerProgress progress) => _prefs.setString(
      GameTuning.saveKeyProgress, jsonEncode(progress.toJson()));

  GameSettings loadSettings() {
    final raw = _prefs.getString(GameTuning.saveKeySettings);
    if (raw == null) return const GameSettings();
    try {
      return GameSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return const GameSettings();
    }
  }

  Future<void> saveSettings(GameSettings settings) => _prefs.setString(
      GameTuning.saveKeySettings, jsonEncode(settings.toJson()));

  DailyMissionState? loadMissions() {
    final raw = _prefs.getString(GameTuning.saveKeyMissions);
    if (raw == null) return null;
    try {
      return DailyMissionState.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveMissions(DailyMissionState missions) => _prefs.setString(
      GameTuning.saveKeyMissions, jsonEncode(missions.toJson()));
}
