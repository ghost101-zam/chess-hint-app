import 'dart:async';

import 'package:flutter/material.dart';

import 'chess_logic.dart';
import 'stockfish_service.dart';
import 'hint_service.dart';
import 'hint_bar.dart';
import 'board_widget.dart';

void main() {
  runApp(const ChessHintApp());
}

class ChessHintApp extends StatelessWidget {
  const ChessHintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Chess + Shared Hints',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6B3F1D),
        useMaterial3: true,
      ),
      home: const StartScreen(),
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Local Two-Player Chess',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Offline · Timed dot-based hints',
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GameScreen(
                    startFlipped: false,
                  ),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                child: Text('Start Game (White view first)'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GameScreen(
                    startFlipped: true,
                  ),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                child: Text('Start Game (Black view first)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final bool startFlipped;

  const GameScreen({
    super.key,
    required this.startFlipped,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final ChessLogic _logic = ChessLogic();
  final StockfishService _engine = StockfishService();

  late final HintService _hintService;

  String? _selectedSquare;
  List<String> _legalTargets = [];

  HintResult? _currentHint;

  bool _engineReady = false;
  bool _thinking = false;

  HintTier _tier = HintTier.beginner;

  bool _flipped = false;

  String? _hintSource;
  String? _hintDestination;

  DotHintStage _hintStage = DotHintStage.hidden;

  Timer? _sourceTimer;
  Timer? _destinationTimer;

  // Prevents old timers from affecting a new position.
  int _hintGeneration = 0;

  @override
  void initState() {
    super.initState();

    _flipped = widget.startFlipped;
    _hintService = HintService(_logic);

    _initEngine();
  }

  Future<void> _initEngine() async {
    await _engine.init();

    if (!mounted) return;

    setState(() {
      _engineReady = true;
    });

    _autoHint();
  }

  void _cancelHintTimers() {
    _sourceTimer?.cancel();
    _destinationTimer?.cancel();

    _sourceTimer = null;
    _destinationTimer = null;
  }

  void _clearDotHints() {
    _cancelHintTimers();

    _hintGeneration++;

    if (!mounted) return;

    setState(() {
      _hintSource = null;
      _hintDestination = null;
      _hintStage = DotHintStage.hidden;
      _currentHint = null;
    });
  }

  Future<void> _autoHint() async {
    if (!_engineReady || _logic.isGameOver) return;

    _clearDotHints();

    final generation = _hintGeneration;

    if (mounted) {
      setState(() {
        _thinking = true;
      });
    }

    final move = await _engine.bestMove(_logic.fen);

    if (!mounted || generation != _hintGeneration) return;

    if (move == null || move.length < 4) {
      setState(() {
        _thinking = false;
      });
      return;
    }

    final source = move.substring(0, 2);
    final destination = move.substring(2, 4);

    setState(() {
      _thinking = false;

      _hintSource = source;
      _hintDestination = destination;

      // IMPORTANT:
      // Do not reveal anything immediately.
      _hintStage = DotHintStage.hidden;

      // No direct text hint.
      _currentHint = null;
    });

    // FIRST CLUE: reveal source after 5 seconds.
    _sourceTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || generation != _hintGeneration) return;

      setState(() {
        _hintStage = DotHintStage.source;
      });
    });

    // SECOND CLUE: reveal destination after 10 seconds total.
    _destinationTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted || generation != _hintGeneration) return;

      setState(() {
        _hintStage = DotHintStage.destination;
      });
    });
  }

  void _onSquareTap(String square) {
    if (_selectedSquare == null) {
      final piece = _logic.pieceAt(square);

      if (piece == null) return;

      final isWhitePiece = piece == piece.toUpperCase();
      final isWhiteTurn = _logic.turnColor == 'w';

      if (isWhitePiece != isWhiteTurn) return;

      setState(() {
        _selectedSquare = square;
        _legalTargets = _logic.legalMovesFrom(square);
      });

      return;
    }

    if (square == _selectedSquare) {
      setState(() {
        _selectedSquare = null;
        _legalTargets = [];
      });

      return;
    }

    final uci = '$_selectedSquare$square';
    final applied = _logic.applyMoveUci(uci);

    setState(() {
      _selectedSquare = null;
      _legalTargets = [];
    });

    if (applied) {
      _clearDotHints();

      _checkGameEnd();

      if (!mounted || _logic.isGameOver) return;

      setState(() {
        _flipped = _logic.turnColor == 'b';
      });

      // Automatically calculate the next player's hint.
      _autoHint();
    }
  }

  void _checkGameEnd() {
    if (_logic.isCheckmate) {
      _showEndDialog(
        'Checkmate — '
        '${_logic.turnColor == 'w' ? 'Black' : 'White'} wins!',
      );
    } else if (_logic.isStalemate) {
      _showEndDialog('Stalemate — draw.');
    } else if (_logic.isDraw) {
      _showEndDialog('Draw.');
    }
  }

  void _showEndDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Game Over'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back to Start'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cancelHintTimers();
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2A2E),
      appBar: AppBar(
        title: Text(
          'Turn: '
          '${_logic.turnColor == 'w' ? 'White' : 'Black'}'
          '${_logic.isCheck ? ' — Check!' : ''}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            tooltip: 'Flip board view',
            onPressed: () {
              setState(() {
                _flipped = !_flipped;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: BoardWidget(
                    logic: _logic,
                    selectedSquare: _selectedSquare,
                    legalTargets: _legalTargets,
                    hintSource: _hintSource,
                    hintDest: _hintDestination,
                    hintStage: _hintStage,
                    flipped: _flipped,
                    onSquareTap: _onSquareTap,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              HintBar(
                hint: _currentHint,
                isThinking: _thinking,
                tier: _tier,
                onTierChanged: (t) {
                  setState(() {
                    _tier = t;
                  });

                  _autoHint();
                },
                onRequestHint: _autoHint,
                onClearHint: _clearDotHints,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
