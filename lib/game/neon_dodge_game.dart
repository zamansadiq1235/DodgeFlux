// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/enums.dart';
import '../models/player_skin.dart';
import '../models/zone_data.dart';
import 'components/background_component.dart';
import 'components/coin_component.dart';
import 'components/obstacle_component.dart';
import 'components/player_component.dart';
import 'components/power_up_component.dart';
import 'run_session.dart';
import 'systems/difficulty_system.dart';
import 'systems/neon_shift_system.dart';
import 'systems/spawn_system.dart';

/// The Flame game.
///
/// Per the TDD state strategy, this class owns everything real-time:
/// positions, movement, collisions, timers, the active dimension and
/// spawn state. Persistent/meta state lives in Riverpod providers.
class NeonDodgeGame extends FlameGame {
  NeonDodgeGame({
    required this.zone,
    required this.skin,
    this.hapticsEnabled = true,
    this.difficulty = DifficultyLevel.normal,
  });

  final ZoneData zone;
  final PlayerSkin skin;
  bool hapticsEnabled;

  /// Affects hazard ramp speed and rewards (see [DifficultySystem]).
  final DifficultyLevel difficulty;

  // ---- Core systems ----
  final NeonShiftSystem shiftSystem = NeonShiftSystem();
  late final DifficultySystem difficultySystem = DifficultySystem(
    zoneModifier: zone.difficultyModifier,
    difficultyModifier: difficulty.rampModifier,
  );
  final SpawnSystem spawnSystem = SpawnSystem();
  late PlayerComponent player;

  /// Live run state for the HUD (read via ValueListenableBuilder).
  final ValueNotifier<RunSession> session = ValueNotifier(const RunSession());
  RunSession _pendingSession = const RunSession();
  bool _sessionUpdateScheduled = false;

  // ---- Run-scoped mutable state ----
  bool _running = false;
  bool runOver = false;

  /// -1/0/1 for keyboard steering (desktop testing).
  int keyboardDirection = 0;

  /// High score known before this run started (for NEW BEST detection).
  int highScoreToBeat = 0;

  double _score = 0;
  int _coins = 0;
  double _survival = 0;
  int _shifts = 0;
  bool _shield = false;
  double _slowMo = 0;
  double _magnet = 0;
  double _multiplier = 0;
  double _dash = 0;
  double _invuln = 0;
  // Combo prototype
  int _comboCount = 0;
  double _comboTimer = 0.0;
  static const double _comboWindow = 2.2; // seconds to continue combo

  // ---- Hooks for the Flutter/UI layer ----
  VoidCallback? onReady;
  void Function(RunResult result)? onRunEnded;
  RunResult? lastResult;

  // ---- Convenience getters used by components & HUD ----
  bool get shieldActive => _shield;
  bool get slowMotionActive => _slowMo > 0;
  bool get magnetActive => _magnet > 0;
  bool get multiplierActive => _multiplier > 0;
  bool get dashActive => _dash > 0;
  bool get isRunning => _running && !runOver;
  int get comboCount => _comboCount;

  /// Register a near-miss (prototype). Increments combo and resets combo timer.
  void registerNearMiss() {
    if (!isRunning) return;
    _comboCount++;
    _comboTimer = _comboWindow;
    // show combo floating text briefly
    add(
      _FloatingText(
        text: 'COMBO ×$_comboCount',
        color: NeonColors.pink,
        position: player.position.clone(),
        kind: _FloatingTextKind.combo,
      ),
    );
  }

  @override
  Future<void> onLoad() async {
    await add(BackgroundComponent(zone: zone));
    player = PlayerComponent(skin: skin);
    await add(player);
    onReady?.call();
  }

  // ---------------- Run lifecycle ----------------

  void startRun() {
    for (final c in children.whereType<ObstacleComponent>().toList()) {
      c.removeFromParent();
    }
    for (final c in children.whereType<CoinComponent>().toList()) {
      c.removeFromParent();
    }
    for (final c in children.whereType<PowerUpComponent>().toList()) {
      c.removeFromParent();
    }
    // start run: clear state and prepare
    for (final c in children.whereType<_ShiftFlash>().toList()) {
      c.removeFromParent();
    }

    shiftSystem.reset();
    difficultySystem.reset();
    spawnSystem.reset();

    _score = 0;
    _coins = 0;
    _survival = 0;
    _shifts = 0;
    _shield = false;
    _slowMo = _magnet = _multiplier = _dash = 0;
    _invuln = 0;
    runOver = false;
    _running = true;
    _pushSession();
  }

  void pauseRun() {
    if (!runOver) _running = false;
  }

  void resumeRun() {
    if (!runOver) _running = true;
  }

  // ---------------- Input ----------------

  /// Called by the Flutter GestureDetector for drag movement.
  /// Supports freeform XY movement, including horizontal, vertical, and diagonal drags.
  void onPlayerDrag(double dx, [double dy = 0]) {
    if (!isRunning) return;
    player.targetX += dx;
    player.targetY += dy;
  }

  void setKeyboardDirection(int direction) => keyboardDirection = direction;

  /// Neon Shift! Flips the active dimension if off cooldown.
  void requestShift() {
    if (!isRunning) return;
    if (shiftSystem.tryShift()) {
      _shifts++;
      add(
        _ShiftFlash(
          dimension: shiftSystem.activeDimension,
          gameSize: size.clone(),
        ),
      );
      if (hapticsEnabled) HapticFeedback.mediumImpact();
    }
  }

  // ---------------- Update loop ----------------

  @override
  void update(double dt) {
    super.update(dt);
    if (!_running || runOver) return;
    dt = min(dt, 0.05); // guard against tab-switch spikes

    if (keyboardDirection != 0) {
      player.targetX += keyboardDirection * 420.0 * dt;
    }

    difficultySystem.update(dt);
    shiftSystem.update(dt);
    _tickPowerUps(dt);

    // combo timer handling
    if (_comboTimer > 0) {
      _comboTimer = max(0, _comboTimer - dt);
      if (_comboTimer == 0 && _comboCount > 0) {
        // combo expired, reset
        _comboCount = 0;
      }
    }

    _survival += dt;
    _score +=
        GameTuning.scorePerSecond *
        dt *
        (multiplierActive ? GameTuning.scoreMultiplierValue : 1);

    if (_invuln > 0) _invuln -= dt;

    for (final req in spawnSystem.update(dt, difficultySystem)) {
      _spawnRequest(req);
    }

    _handleCollisions();
    _pushSession();
  }

  void _tickPowerUps(double dt) {
    _slowMo = max(0, _slowMo - dt);
    _magnet = max(0, _magnet - dt);
    _multiplier = max(0, _multiplier - dt);
    _dash = max(0, _dash - dt);
  }

  void _spawnRequest(SpawnRequest req) {
    switch (req.kind) {
      case SpawnKind.obstacle:
        add(
          ObstacleComponent(
            obstacleType: req.obstacleType!,
            dimension: req.dimension!,
            speed: difficultySystem.fallSpeed,
          )..position = Vector2(req.xFraction * size.x, -70),
        );
      case SpawnKind.coinLine:
        final count = 3 + Random().nextInt(3);
        for (var i = 0; i < count; i++) {
          add(
            CoinComponent(
                dimension: req.dimension!,
                speed: difficultySystem.fallSpeed,
              )
              ..position = Vector2(
                req.xFraction * size.x + (i.isEven ? -14.0 : 14.0),
                -30 - i * 34,
              ),
          );
        }
      case SpawnKind.powerUp:
        add(
          PowerUpComponent(
            powerUpType: req.powerUpType!,
            speed: difficultySystem.fallSpeed,
          )..position = Vector2(req.xFraction * size.x, -50),
        );
    }
  }

  // ---------------- Collisions ----------------

  void _handleCollisions() {
    final playerPos = player.position;
    final playerRadius = GameTuning.playerRadius;

    // Coins: only collectible while the player is in the coin's dimension
    // (Neon Shift rule) — move through every dimension to grab them all.
    for (final coin in children.whereType<CoinComponent>().toList()) {
      if (coin.hitsPlayer(playerPos, playerRadius) && coin.isCollectible) {
        coin.removeFromParent();
        _coins++;
        _score +=
            GameTuning.scorePerCoin *
            (multiplierActive ? GameTuning.scoreMultiplierValue : 1);
        // small floating text feedback on coin pickup
        add(
          _FloatingText(
            text: '+${GameTuning.scorePerCoin}',
            color: NeonColors.coin,
            position: coin.position.clone(),
            kind: _FloatingTextKind.coin,
          ),
        );
        if (hapticsEnabled) HapticFeedback.selectionClick();
      }
    }

    // Power-ups.
    for (final p in children.whereType<PowerUpComponent>().toList()) {
      if (p.hitsPlayer(playerPos, playerRadius)) {
        p.removeFromParent();
        _applyPowerUp(p.powerUpType);
      }
    }

    // Hazards: skipped entirely while dashing / post-hit invulnerable.
    if (dashActive || _invuln > 0) return;

    for (final o in children.whereType<ObstacleComponent>().toList()) {
      if (!o.hitsPlayer(playerPos, playerRadius)) continue;
      // Neon Shift rule: matching dimension = safe, pass through.
      if (shiftSystem.isHazardSafe(o.dimension)) continue;
      if (_shield) {
        _shield = false;
        o.removeFromParent();
        _invuln = 1.0;
        if (hapticsEnabled) HapticFeedback.heavyImpact();
      } else {
        _endRun();
        return;
      }
    }

    // Near-miss detection: obstacles that came very close but did not hit.
    for (final o in children.whereType<ObstacleComponent>().toList()) {
      if (o.nearMissRecorded) continue;
      if (o.hitsPlayer(playerPos, playerRadius)) continue; // already handled
      // approximate radius used in hitsPlayer
      final obstacleRadius = (max(o.size.x, o.size.y) / 2) * 0.82;
      final dist = (o.position - playerPos).length;
      final threshold =
          obstacleRadius + playerRadius * 1.6; // generous near-miss margin
      // only count near-miss when obstacle is roughly aligned vertically with player
      if (dist < threshold &&
          o.position.y > playerPos.y - 8 &&
          o.position.y < playerPos.y + 40) {
        o.nearMissRecorded = true;
        registerNearMiss();
      }
    }
  }

  void _applyPowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.shield:
        _shield = true;
      case PowerUpType.slowMotion:
        _slowMo = GameTuning.powerUpDuration;
      case PowerUpType.coinMagnet:
        _magnet = GameTuning.powerUpDuration;
      case PowerUpType.dash:
        _dash = GameTuning.dashDuration;
      case PowerUpType.scoreMultiplier:
        _multiplier = GameTuning.powerUpDuration;
    }
    if (hapticsEnabled) HapticFeedback.lightImpact();
  }

  // ---------------- Session push / run end ----------------

  void _pushSession() {
    final next = RunSession(
      score: _score.round(),
      coins: _coins,
      survivalTime: _survival,
      shiftsUsed: _shifts,
      shieldActive: _shield,
      slowMoRemaining: _slowMo,
      magnetRemaining: _magnet,
      multiplierRemaining: _multiplier,
      dashRemaining: _dash,
      activeDimension: shiftSystem.activeDimension,
      shiftCooldownProgress: shiftSystem.cooldownProgress,
      comboCount: _comboCount,
    );

    _pendingSession = next;
    if (_sessionUpdateScheduled) return;

    _sessionUpdateScheduled = true;
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sessionUpdateScheduled = false;
        session.value = _pendingSession;
      });
    } catch (_) {
      _sessionUpdateScheduled = false;
      session.value = _pendingSession;
    }
  }

  void _endRun() {
    runOver = true;
    _running = false;
    if (hapticsEnabled) HapticFeedback.heavyImpact();
    final result = RunResult(
      score: _score.round(),
      coinsCollected: _coins,
      survivalTime: _survival,
      shiftsUsed: _shifts,
      isNewHighScore: _score.round() > highScoreToBeat,
      rewardMultiplier: difficulty.rewardMultiplier,
      difficultyLabel: difficulty.label,
    );
    lastResult = result;
    onRunEnded?.call(result);
  }
}

/// Small floating text shown when collecting coins or XP.
enum _FloatingTextKind { coin, combo }

class _FloatingText extends PositionComponent
    with HasGameReference<NeonDodgeGame> {
  _FloatingText({
    required this.text,
    required this.color,
    required Vector2 position,
    this.kind = _FloatingTextKind.coin,
  }) {
    this.position = position;
    anchor = Anchor.center;
    _life = _maxLife;
    _startScale = kind == _FloatingTextKind.coin ? 1.35 : 1.6;
    size = Vector2.zero();
    priority = 200;
  }

  final String text;
  final Color color;
  final _FloatingTextKind kind;
  static const double _maxLife = 0.9;
  double _life = _maxLife;
  double _startScale = 1.0;

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    // faster rise for combo text
    position.add(
      Vector2(0, kind == _FloatingTextKind.coin ? -26.0 * dt : -48.0 * dt),
    );
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (1 - (_life / _maxLife)).clamp(0.0, 1.0).toDouble();
    final fade = (1 - t).clamp(0.0, 1.0);
    final scale = _startScale - (t * (_startScale - 1.0));
    final fontSize = kind == _FloatingTextKind.coin ? 14.0 : 18.0;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withOpacity(fade),
          fontSize: fontSize * scale,
          fontWeight: FontWeight.w900,
          shadows: kind == _FloatingTextKind.combo
              ? [const Shadow(color: Colors.white24, blurRadius: 8)]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    canvas.save();
    canvas.translate(-tp.width / 2, -tp.height / 2);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }
}

/// Full-screen colored pulse shown for a moment on each Neon Shift
/// (visual feedback required by the UX brief).
class _ShiftFlash extends PositionComponent
    with HasGameReference<NeonDodgeGame> {
  _ShiftFlash({required this.dimension, required Vector2 gameSize}) {
    size = gameSize;
    position = Vector2.zero();
    priority = 100;
  }

  final NeonDimension dimension;
  static const double _maxLife = 0.28;
  double _life = _maxLife;

  @override
  void update(double dt) {
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_life / _maxLife).clamp(0.0, 1.0).toDouble();
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()
        ..color = NeonColors.forDimension(
          dimension,
        ).withValues(alpha: 0.22 * t),
    );
  }
}
