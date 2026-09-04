import 'package:flutter/material.dart';

/// A playable zone/world. Zones unlock with player level and slightly change
/// the visuals and difficulty of runs.
class ZoneData {
  const ZoneData({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredLevel,
    required this.backgroundColor,
    required this.gridColor,
    required this.accentColor,
    this.difficultyModifier = 1.0,
  });

  final String id;
  final String name;
  final String description;
  final int requiredLevel;
  final Color backgroundColor;
  final Color gridColor;
  final Color accentColor;

  /// Multiplier applied to fall speed / spawn rate. Higher = harder.
  final double difficultyModifier;

  static const List<ZoneData> all = [
    ZoneData(
      id: 'neon_city',
      name: 'Neon City',
      description: 'Where every runner starts. Balanced hazard flow.',
      requiredLevel: 1,
      backgroundColor: Color(0xFF050510),
      gridColor: Color(0xFF14142B),
      accentColor: Color(0xFF22D3EE),
      difficultyModifier: 0.5, // 1 star (0.5 * 2 = 1)
    ),
    ZoneData(
      id: 'cyber_grid',
      name: 'Cyber Grid',
      description: 'Tighter grid, faster hazards. Unlocks at level 5.',
      requiredLevel: 5,
      backgroundColor: Color(0xFF06060F),
      gridColor: Color(0xFF123A1E),
      accentColor: Color(0xFF7CFC00),
      difficultyModifier: 1.0, // 2 stars (1.0 * 2 = 2)
    ),
    ZoneData(
      id: 'plasma_void',
      name: 'Plasma Void',
      description: 'Unstable space, denser spawns. Unlocks at level 10.',
      requiredLevel: 10,
      backgroundColor: Color(0xFF0B0416),
      gridColor: Color(0xFF2B1445),
      accentColor: Color(0xFFB388FF),
      difficultyModifier: 1.5, // 3 stars (1.5 * 2 = 3)
    ),
    ZoneData(
      id: 'hyper_acid',
      name: 'Hyper Acid',
      description:
          'Corrosive obstacles and high wave speed. Unlocks at level 15.',
      requiredLevel: 15,
      backgroundColor: Color(0xFF06140B),
      gridColor: Color(0xFF0E3A1A),
      accentColor: Color(0xFF10B981),
      difficultyModifier: 2.0, // 4 stars (2.0 * 2 = 4)
    ),
    ZoneData(
      id: 'solar_rush',
      name: 'Solar Rush',
      description: 'Maximum velocity. For veterans only. Unlocks at level 20.',
      requiredLevel: 20,
      backgroundColor: Color(0xFF140705),
      gridColor: Color(0xFF3A1A0E),
      accentColor: Color(0xFFFFB300),
      difficultyModifier: 2.0, // 4 stars (2.0 * 2 = 4)
    ),
    ZoneData(
      id: 'quantum_rift',
      name: 'Quantum Rift',
      description:
          'Extreme distortion and chaotic hazards. Unlocks at level 25.',
      requiredLevel: 25,
      backgroundColor: Color(0xFF140510),
      gridColor: Color(0xFF3A0E28),
      accentColor: Color(0xFFF43F5E),
      difficultyModifier: 2.0, // 4 stars maxed out (2.0 * 2 = 4)
    ),
  ];
  static ZoneData byId(String id) =>
      all.firstWhere((z) => z.id == id, orElse: () => all.first);
}
