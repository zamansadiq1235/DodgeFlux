import '../core/enums.dart';

/// Static metadata for a power-up type.
class PowerUpData {
  const PowerUpData({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
  });

  final PowerUpType type;
  final String name;
  final String description;

  /// Simple glyph used in HUD / pickups (keeps the build asset-free).
  final String icon;

  static const Map<PowerUpType, PowerUpData> catalog = {
    PowerUpType.shield: PowerUpData(
      type: PowerUpType.shield,
      name: 'Shield',
      description: 'Survive one deadly hit.',
      icon: '⛨',
    ),
    PowerUpType.slowMotion: PowerUpData(
      type: PowerUpType.slowMotion,
      name: 'Slow Motion',
      description: 'Hazards crawl for a few seconds.',
      icon: '⏱',
    ),
    PowerUpType.coinMagnet: PowerUpData(
      type: PowerUpType.coinMagnet,
      name: 'Coin Magnet',
      description: 'Coins fly toward you.',
      icon: '🧲',
    ),
    PowerUpType.dash: PowerUpData(
      type: PowerUpType.dash,
      name: 'Dash',
      description: 'Brief burst of invincible speed.',
      icon: '⚡',
    ),
    PowerUpType.scoreMultiplier: PowerUpData(
      type: PowerUpType.scoreMultiplier,
      name: 'Score x2',
      description: 'Double score for a short time.',
      icon: '✖',
    ),
  };

  static PowerUpData of(PowerUpType type) => catalog[type]!;
}
