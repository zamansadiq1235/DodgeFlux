import '../core/enums.dart';

/// Player-configurable settings, persisted locally.
class GameSettings {
  const GameSettings({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.musicEnabled = true,
    this.difficultyId = 'normal',
  });

  final bool soundEnabled;
  final bool hapticsEnabled;

  /// Background music toggle (see MusicService in services/).
  final bool musicEnabled;

  /// Persisted id of the selected [DifficultyLevel].
  final String difficultyId;

  DifficultyLevel get difficulty => DifficultyLevel.fromId(difficultyId);

  GameSettings copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? musicEnabled,
    DifficultyLevel? difficulty,
  }) {
    return GameSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      difficultyId: difficulty?.name ?? difficultyId,
    );
  }

  Map<String, dynamic> toJson() => {
        'soundEnabled': soundEnabled,
        'hapticsEnabled': hapticsEnabled,
        'musicEnabled': musicEnabled,
        'difficultyId': difficultyId,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      musicEnabled: json['musicEnabled'] as bool? ?? true,
      difficultyId: json['difficultyId'] as String? ?? 'normal',
    );
  }
}
