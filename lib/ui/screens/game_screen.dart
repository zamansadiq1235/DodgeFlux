// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums.dart';
import '../../game/neon_dodge_game.dart';
import '../../game/run_session.dart';
import '../../models/player_skin.dart';
import '../../models/zone_data.dart';
import '../../providers/providers.dart';
import '../../services/music_service.dart';
import 'game_hud.dart';

/// Factory used by the main menu so screens stay decoupled.
Widget buildGameScreen({required String zoneId, required String skinId}) =>
    GameScreen(zoneId: zoneId, skinId: skinId);

/// Hosts the Flame game, captures input (drag + keyboard) and shows the
/// HUD / pause / game-over layers on top.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.zoneId, required this.skinId});

  final String zoneId;
  final String skinId;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final NeonDodgeGame game;
  final FocusNode _focusNode = FocusNode();
  bool _keyLeft = false;
  bool _keyRight = false;

  // Cached notifier reference so dispose() can safely reset game status
  // without touching `ref` (its BuildContext is deactivated on unmount).
  late final GameStatusNotifier _gameStatus;

  @override
  void initState() {
    super.initState();
    _gameStatus = ref.read(gameStatusProvider.notifier);
    final settings = ref.read(gameSettingsProvider);
    MusicService.instance.setEnabled(settings.musicEnabled);
    MusicService.instance.playGameMusic();
    game = NeonDodgeGame(
      zone: ZoneData.byId(widget.zoneId),
      skin: PlayerSkin.byId(widget.skinId),
      difficulty: settings.difficulty,
    );
    game.onReady = _beginRun;
    game.onRunEnded = _handleRunEnded;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    // Reset the game status after the frame: `dispose()` runs while the
    // widget tree is being torn down (inside Flutter's build phase), and
    // Riverpod forbids modifying a provider during a build. The cached
    // notifier + `ref.mounted` guard ensure we only act on a still-live
    // provider and never do so mid-build. Most exit paths (`_exitToMenu`) already set
    // `menu` first, so this is just a safety net for system back gestures.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_gameStatus.ref.mounted) _gameStatus.toMenu();
    });
    // Return to the chill menu loop when leaving the run.
    MusicService.instance.playMenuMusic();
    _focusNode.dispose();
    super.dispose();
  }

  // ---------------- Run lifecycle ----------------

  void _beginRun() {
    if (!mounted) return;
    final progress = ref.read(playerProgressProvider);
    game.highScoreToBeat = progress.highScore;
    game.hapticsEnabled = ref.read(gameSettingsProvider).hapticsEnabled;
    ref.read(lastRunProvider.notifier).state = null;
    ref.read(runCelebrationsProvider.notifier).state = const [];
    ref.read(gameStatusProvider.notifier).toPlaying();
    game.startRun();
  }

  void _handleRunEnded(RunResult result) {
    if (!mounted) return;
    final celebrations = ref
        .read(playerProgressProvider.notifier)
        .applyRunResult(result);
    ref.read(lastRunProvider.notifier).state = result;
    ref.read(runCelebrationsProvider.notifier).state = celebrations;
    ref.read(gameStatusProvider.notifier).gameOver();
  }

  void _pause() {
    game.pauseRun();
    ref.read(gameStatusProvider.notifier).pause();
  }

  void _resume() {
    game.resumeRun();
    ref.read(gameStatusProvider.notifier).resume();
  }

  void _exitToMenu() {
    ref.read(gameStatusProvider.notifier).toMenu();
    if (mounted) Navigator.of(context).maybePop();
  }

  // ---------------- Keyboard (desktop testing) ----------------

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final down = event is KeyDownEvent || event is KeyRepeatEvent;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _keyLeft = down;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _keyRight = down;
    } else if (down && event.logicalKey == LogicalKeyboardKey.space) {
      game.requestShift();
    } else if (down && event.logicalKey == LogicalKeyboardKey.escape) {
      final status = ref.read(gameStatusProvider);
      status == GameStatus.playing ? _pause() : _resume();
    } else {
      return KeyEventResult.ignored;
    }
    game.setKeyboardDirection(
      _keyLeft && !_keyRight
          ? -1
          : _keyRight && !_keyLeft
          ? 1
          : 0,
    );
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(gameStatusProvider);
    return PopScope(
      canPop: status != GameStatus.playing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _pause();
      },
      child: Scaffold(
        body: Focus(
          focusNode: _focusNode,
          onKeyEvent: _onKey,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) =>
                game.onPlayerDrag(details.delta.dx, details.delta.dy),
            child: Stack(
              fit: StackFit.expand,
              children: [
                GameWidget(game: game),
                // HUD stays visible under pause/game-over layers.
                if (status == GameStatus.playing || status == GameStatus.paused)
                  GameHud(
                    game: game,
                    onPause: _pause,
                    onShift: game.requestShift,
                  ),
                if (status == GameStatus.paused)
                  PauseOverlay(
                    onResume: _resume,
                    onRestart: _beginRun,
                    onMenu: _exitToMenu,
                  ),
                if (status == GameStatus.gameOver)
                  GameOverOverlay(onRetry: _beginRun, onMenu: _exitToMenu),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
