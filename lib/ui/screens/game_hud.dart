// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../game/neon_dodge_game.dart';
import '../../game/run_session.dart';
import '../../providers/providers.dart';
import '../widgets/common.dart';
import 'shop_screen.dart';

/// In-run HUD: score, coins, timer, dimension indicator, power-up badges,
/// pause button and the Neon Shift button with its cooldown ring.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.game,
    required this.onPause,
    required this.onShift,
  });

  final NeonDodgeGame game;
  final VoidCallback onPause;
  final VoidCallback onShift;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RunSession>(
      valueListenable: game.session,
      builder: (context, session, _) {
        final dimensionColor = NeonColors.forDimension(session.activeDimension);
        return Stack(
          children: [
            Column(
              children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Column(
                  children: [
                    // Prominent score row with tappable coin pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: NeonColors.surface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: NeonColors.gridLine.withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'SCORE',
                            style: const TextStyle(
                              color: NeonColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${session.score}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: NeonColors.textPrimary,
                                shadows: [
                                  Shadow(
                                    color: NeonColors.blue,
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Tooltip(
                            message: 'Open Shop',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ShopScreen(),
                                  ),
                                );
                              },
                              child: Pill(
                                label: '🪙 ${session.coins}',
                                color: NeonColors.coin,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Secondary row: dimension + timer + pause
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: dimensionColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: dimensionColor),
                          ),
                          child: Text(
                            session.activeDimension == NeonDimension.blue
                                ? 'BLUE SAFE'
                                : 'PINK SAFE',
                            style: TextStyle(
                              color: dimensionColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '⏱ ${session.survivalTime.toStringAsFixed(0)}s',
                          style: const TextStyle(
                            color: NeonColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RoundIconButton(
                          icon: Icons.pause_rounded,
                          onPressed: onPause,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _PowerBadges(session: session),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // ---- Shift button ----
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _ShiftButton(
                    progress: session.shiftCooldownProgress,
                    color: dimensionColor,
                    onTap: onShift,
                  ),
                ),
              ),
            ),
            // Combo overlay
            if (session.comboCount > 1)
              Positioned(
                top: 14,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: session.comboCount > 1 ? 1.0 : 0.0,
                    child: NeonCard(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      child: Text(
                        'COMBO ×${session.comboCount}',
                        style: const TextStyle(
                          color: NeonColors.pink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        
          ] );
      },
    );
  }
}

class _PowerBadges extends StatelessWidget {
  const _PowerBadges({required this.session});

  final RunSession session;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (session.shieldActive)
          const _PowerBadge(icon: Icons.shield, color: NeonColors.shield),
        if (session.slowMoRemaining > 0)
          _PowerBadge(
            icon: Icons.hourglass_bottom,
            color: NeonColors.slowMo,
            seconds: session.slowMoRemaining,
          ),
        if (session.magnetRemaining > 0)
          _PowerBadge(
            icon: Icons.attractions,
            color: NeonColors.magnet,
            seconds: session.magnetRemaining,
          ),
        if (session.multiplierRemaining > 0)
          _PowerBadge(
            icon: Icons.close,
            color: NeonColors.multiplier,
            seconds: session.multiplierRemaining,
          ),
        if (session.dashRemaining > 0)
          _PowerBadge(
            icon: Icons.bolt,
            color: NeonColors.dash,
            seconds: session.dashRemaining,
          ),
      ],
    );
  }
}

class _PowerBadge extends StatelessWidget {
  const _PowerBadge({required this.icon, required this.color, this.seconds});

  final IconData icon;
  final Color color;
  final double? seconds;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            if (seconds != null) ...[
              const SizedBox(width: 4),
              Text(
                seconds!.ceil().toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: NeonColors.surface,
        border: Border.all(color: NeonColors.gridLine),
      ),
      child: IconButton(
        icon: Icon(icon, color: NeonColors.textPrimary),
        onPressed: onPressed,
      ),
    );
  }
}

/// Circular Neon Shift button with a radial cooldown ring.
class _ShiftButton extends StatelessWidget {
  const _ShiftButton({
    required this.progress,
    required this.color,
    required this.onTap,
  });

  final double progress;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _CooldownRingPainter(progress: progress, color: color),
        child: Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_horiz, color: color, size: 30),
              Text(
                'SHIFT',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CooldownRingPainter extends CustomPainter {
  _CooldownRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(
      center,
      radius - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white.withValues(alpha: 0.15),
    );
    final rect = Rect.fromCircle(center: center, radius: radius - 2);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_CooldownRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ---------------------------------------------------------------------------
// Pause overlay
// ---------------------------------------------------------------------------

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onMenu,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      alignment: Alignment.center,
      child: NeonCard(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: NeonColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: NeonButton(
                icon: Icons.play_arrow_rounded,
                label: 'RESUME',
                onPressed: onResume,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 220,
              child: NeonButton(
                icon: Icons.replay_rounded,
                label: 'RESTART',
                onPressed: onRestart,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 220,
              child: NeonButton(
                icon: Icons.home_rounded,
                label: 'MENU',
                onPressed: onMenu,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Game over overlay
// ---------------------------------------------------------------------------

class GameOverOverlay extends ConsumerWidget {
  const GameOverOverlay({
    super.key,
    required this.onRetry,
    required this.onMenu,
  });

  final VoidCallback onRetry;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(lastRunProvider);
    final celebrations = ref.watch(runCelebrationsProvider);
    if (result == null) return const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Colors.black.withValues(alpha: 0.8),
          alignment: Alignment.center,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: NeonCard(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    result.isNewHighScore ? 'NEW BEST!' : 'GAME OVER',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: result.isNewHighScore
                          ? NeonColors.coin
                          : NeonColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Pill(label: result.difficultyLabel, color: NeonColors.slowMo),
                  const SizedBox(height: 14),
                  _StatRow(label: 'SCORE', value: '${result.score}', big: true),
                  _StatRow(label: 'COINS', value: '+${result.coinsEarned} 🪙'),
                  _StatRow(
                    label: 'TIME',
                    value: '${result.survivalTime.toStringAsFixed(1)}s',
                  ),
                  _StatRow(label: 'SHIFTS', value: '${result.shiftsUsed}'),
                  if (celebrations.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    ...celebrations.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '✨ $c',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: NeonColors.coin,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 220,
                    child: NeonButton(
                      icon: Icons.replay_rounded,
                      label: 'PLAY AGAIN',
                      onPressed: onRetry,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 220,
                    child: NeonButton(
                      icon: Icons.home_rounded,
                      label: 'MENU',
                      onPressed: onMenu,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Aggressive CRT scanlines jittering in sync with the celebration.
        IgnorePointer(
          child: CrtScanlineOverlay(intense: result.isNewHighScore),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.big = false});

  final String label;
  final String value;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: NeonColors.textSecondary,
              fontSize: big ? 14 : 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: NeonColors.textPrimary,
              fontSize: big ? 32 : 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hardware-heavy CRT overlay for the Game Over screen.
///
/// Dense dark scanlines with a rolling refresh band. When [intense] (new best
/// score) the lines are deeper, the refresh band moves faster and the whole
/// layer flickers harder — echoing the celebration shake.
class CrtScanlineOverlay extends StatefulWidget {
  const CrtScanlineOverlay({super.key, required this.intense});

  final bool intense;

  @override
  State<CrtScanlineOverlay> createState() => _CrtScanlineOverlayState();
}

class _CrtScanlineOverlayState extends State<CrtScanlineOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _CrtScanlinePainter(
          t: _controller.value,
          intense: widget.intense,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _CrtScanlinePainter extends CustomPainter {
  _CrtScanlinePainter({required this.t, required this.intense});

  final double t;
  final bool intense;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = (t * (intense ? 3.0 : 1.4)).clamp(0.0, 1.0);

    // Rolling refresh band (top -> bottom).
    final bandY = phase * size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, bandY - 16, size.width, 30),
      Paint()
        ..color = Colors.white.withValues(alpha: intense ? 0.10 : 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Dense horizontal scanlines — darker and tighter when intense.
    final lineSpacing = 3.0;
    final darkAlpha = intense ? 0.52 : 0.34;
    final paint = Paint();
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var y = 0.0; y < size.height; y += lineSpacing) {
      paint.color = Colors.black.withValues(alpha: darkAlpha);
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, lineSpacing * 0.6),
        paint,
      );
    }
    canvas.restore();

    // Subtle RGB fringe / vignette tinting the edges like an old tube.
    final verticalGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.black.withValues(alpha: intense ? 0.5 : 0.28),
        Colors.transparent,
        Colors.transparent,
        Colors.black.withValues(alpha: intense ? 0.5 : 0.28),
      ],
      stops: const [0.0, 0.08, 0.92, 1.0],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = verticalGradient);

    // Brightness flicker synced to the same rhythm as the screen shake.
    final flicker = 0.04 * phase;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: flicker.clamp(0.0, 0.04)),
    );
  }

  @override
  bool shouldRepaint(_CrtScanlinePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.intense != intense;
}
