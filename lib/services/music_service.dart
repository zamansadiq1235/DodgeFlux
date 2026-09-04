import 'dart:io';

import 'package:flame_audio/flame_audio.dart';

/// Global background-music controller.
///
/// Uses Flame's `bgm` player (gapless `ReleaseMode.loop`). It decides which
/// track "this screen wants" and starts/stops playback whenever the enabled
/// flag or the current screen changes, so the music follows the app around
/// without a widget listening everywhere.
class MusicService {
  MusicService._();

  static final MusicService instance = MusicService._();

  static const String menuTrack = 'menu_loop.wav';
  static const String gameTrack = 'game_loop.wav';

  static const double _menuVolume = 0.30;
  static const double _gameVolume = 0.34;

  bool _enabled = true;

  /// Track the current screen asked for (played even while disabled, so the
  /// correct one resumes when the user flips the switch back on).
  String? _wanted;
  String? _current;

  bool get isEnabled => _enabled;

  /// Widget tests should never touch native audio backends. Flutter's test
  /// harness exposes a few environment signals depending on the runner, so we
  /// guard for the common ones and the explicit compile-time flag as well.
  static bool get isRunningInTest {
    return const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false) ||
        Platform.environment.containsKey('FLUTTER_TEST') ||
        Platform.environment.containsKey('FLUTTER_WIDGET_TEST') ||
        Platform.environment.containsKey('DART_TEST');
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (isRunningInTest) return;
    if (!enabled) {
      _current = null;
      _stop();
      return;
    }
    if (_wanted != null && _current == null) {
      _current = _wanted;
      _play(_wanted!, _volumeFor(_wanted!));
    }
  }

  void playMenuMusic() => _want(menuTrack, _menuVolume);

  void playGameMusic() => _want(gameTrack, _gameVolume);

  void stop() {
    _wanted = null;
    _current = null;
    _stop();
  }

  void _want(String track, double volume) {
    _wanted = track;
    if (isRunningInTest || !_enabled) return;
    if (_current == track) return;
    _current = track;
    _play(track, volume);
  }

  double _volumeFor(String track) =>
      track == gameTrack ? _gameVolume : _menuVolume;

  void _play(String track, double volume) {
    FlameAudio.bgm.play(track, volume: volume).catchError((Object _) {});
  }

  void _stop() {
    FlameAudio.bgm.stop().catchError((Object _) {});
  }
}
