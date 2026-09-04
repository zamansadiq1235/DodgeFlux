import 'package:flutter/material.dart';

import '../core/enums.dart';

/// Cosmetic player skin, unlockable with coins. Every skin has a distinct
/// body color, silhouette ([SkinShape]) and trail so it reads differently
/// both in the shop and during a run.
class PlayerSkin {
  const PlayerSkin({
    required this.id,
    required this.name,
    required this.cost,
    required this.trailColor,
    required this.coreColor,
    required this.glowRadius,
    this.shape = SkinShape.orb,
    this.description = '',
  });

  final String id;
  final String name;
  final int cost;
  final Color trailColor;

  /// Body color blended with the active dimension colour while playing.
  final Color coreColor;
  final double glowRadius;
  final SkinShape shape;
  final String description;

  static const List<PlayerSkin> all = [
    PlayerSkin(
      id: 'orb',
      name: 'Orb',
      cost: 0,
      trailColor: Color(0xFFFFFFFF),
      coreColor: Color(0xFFF5F5FF),
      glowRadius: 18,
      description: 'The classic starter core.',
    ),
    PlayerSkin(
      id: 'comet',
      name: 'Comet',
      cost: 150,
      trailColor: Color(0xFFFFB300),
      coreColor: Color(0xFFFFB300),
      glowRadius: 26,
      description: 'Burns a blazing tail.',
    ),
    PlayerSkin(
      id: 'prism',
      name: 'Prism',
      cost: 300,
      trailColor: Color(0xFF7CFC00),
      coreColor: Color(0xFFB6FF9E),
      glowRadius: 30,
      shape: SkinShape.hexagon,
      description: 'Refracts the grid into pure light.',
    ),
    PlayerSkin(
      id: 'ghost',
      name: 'Ghost',
      cost: 500,
      trailColor: Color(0xFFB388FF),
      coreColor: Color(0xFFE0D7FF),
      glowRadius: 36,
      shape: SkinShape.ring,
      description: 'A hollow echo from another run.',
    ),
    PlayerSkin(
      id: 'cyber',
      name: 'Cyber',
      cost: 750,
      trailColor: Color(0xFF22D3EE),
      coreColor: Color(0xFF67E8F9),
      glowRadius: 28,
      shape: SkinShape.hexagon,
      description: 'Hex-encrypted, zero-latency.',
    ),
    PlayerSkin(
      id: 'blaze',
      name: 'Blaze',
      cost: 1000,
      trailColor: Color(0xFFFF5252),
      coreColor: Color(0xFFFF8A65),
      glowRadius: 32,
      shape: SkinShape.diamond,
      description: 'White-hot shard of the solar zone.',
    ),
    PlayerSkin(
      id: 'royal',
      name: 'Royal',
      cost: 1500,
      trailColor: Color(0xFFF472B6),
      coreColor: Color(0xFFF9A8D4),
      glowRadius: 34,
      shape: SkinShape.diamond,
      description: 'Cut for the grid\'s elite.',
    ),
    PlayerSkin(
      id: 'void',
      name: 'Void',
      cost: 2500,
      trailColor: Color(0xFF9D4EDD),
      coreColor: Color(0xFF5A189A),
      glowRadius: 42,
      shape: SkinShape.ring,
      description: 'Swallows light before the dive.',
    ),
  ];

  static PlayerSkin byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}
