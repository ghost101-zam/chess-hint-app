import 'dart:async';
import 'package:stockfish/stockfish.dart';

/// Wraps the local (on-device, offline) Stockfish engine.
/// No network access is used at any point.
class StockfishService {
  Stockfish? _stockfish;
  bool _ready = false;

  Future<void> init() async {
    _stockfish = Stockfish();
    final completer = Completer<void>();

    void listener() {
      if (_stockfish!.state.value == StockfishState.ready) {
        _ready = true;
        if (!completer.isCompleted) completer.complete();
      }
    }

    _stockfish!.state.addListener(listener);
    listener(); // in case it's already ready
    await completer.future;
  }

  bool get isReady => _ready;

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
      onTimeout: () {
        sub.cancel();
        return null;
      },
    );
  }

  void dispose() {
    _stockfish?.dispose();
  }
}
