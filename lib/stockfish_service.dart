import 'dart:async';
import 'package:stockfish/stockfish.dart';

/// Wraps the local (on-device, offline) Stockfish engine.
/// No network access is used at any point — flutter_stockfish bundles
/// the engine binary natively and runs it fully offline.
class StockfishService {
  Stockfish? _stockfish;
  bool _ready = false;

  Future<void> init() async {
    _stockfish = Stockfish();
    // Wait for the engine process to report it's ready for commands.
    await for (final state in _stockfish!.state.stream) {
      if (state == StockfishState.ready) {
        _ready = true;
        break;
      }
    }
  }

  bool get isReady => _ready;

  /// Asks the engine for its best move given a FEN position.
  /// [thinkTimeMs] controls how long the engine searches — shorter is
  /// snappier for a casual/beginner-friendly game, longer plays stronger.
  /// Returns the move in UCI form, e.g. "g1f3" or "e7e8q".
  Future<String?> bestMove(String fen, {int thinkTimeMs = 800}) async {
    if (_stockfish == null || !_ready) return null;

    final completer = Completer<String?>();
    late StreamSubscription sub;

    sub = _stockfish!.stdout.listen((line) {
      if (line.startsWith('bestmove')) {
        final parts = line.split(' ');
        final move = parts.length > 1 ? parts[1] : null;
        if (!completer.isCompleted) completer.complete(move);
        sub.cancel();
      }
    });

    _stockfish!.stdin = 'position fen $fen';
    _stockfish!.stdin = 'go movetime $thinkTimeMs';

    return completer.future.timeout(
      Duration(milliseconds: thinkTimeMs + 2000),
      onTimeout: () => null,
    );
  }

  void dispose() {
    _stockfish?.dispose();
  }
}
