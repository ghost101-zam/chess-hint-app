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
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Offline · Automatic hints shown to both players'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GameScreen(startFlipped: false),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                child: Text('Start Game (White view first)'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GameScreen(startFlipped: true),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
  const GameScreen({super.key, required this.startFlipped});

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
    setState(() => _engineReady = true);
    _autoHint(); // Show a hint for the very first move automatically.
  }

  Future<void> _autoHint() async {
    if (!_engineReady || _logic.isGameOver) return;
    setState(() => _thinking = true);
    final move = await _engine.bestMove(_logic.fen);
    if (!mounted) return;
    setState(() {
      _thinking = false;
      _currentHint = move != null ? _hintService.buildHint(move, tier: _tier) : null;
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
      _currentHint = null;
    });

    if (applied) {
      _checkGameEnd();
      setState(() => _flipped = _logic.turnColor == 'b');
      _autoHint(); // Automatically show the hint for whoever moves next.
    }
  }

  void _checkGameEnd() {
    if (_logic.isCheckmate) {
      _showEndDialog('Checkmate — ${_logic.turnColor == 'w' ? 'Black' : 'White'} wins!');
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
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2A2E),
      appBar: AppBar(
        title: Text(
          'Turn: ${_logic.turnColor == 'w' ? 'White' : 'Black'}'
          '${_logic.isCheck ? ' — Check!' : ''}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            tooltip: 'Flip board view',
            onPressed: () => setState(() => _flipped = !_flipped),
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
                    hintSource: _currentHint?.sourceSquare,
                    hintDest: _currentHint?.destSquare,
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
                  setState(() => _tier = t);
                  _autoHint();
                },
                onRequestHint: _autoHint,
                onClearHint: null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
