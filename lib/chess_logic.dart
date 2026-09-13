import 'package:chess/chess.dart' as lib_chess;

/// Thin wrapper around the `chess` package so the rest of the app
/// never has to touch the underlying library's API directly.
/// Handles move validation, turn tracking, check/checkmate/stalemate,
/// and exposes the board as an 8x8 grid the UI can render.
class ChessLogic {
  final lib_chess.Chess _game = lib_chess.Chess();

  /// Returns 'w' or 'b' for whose turn it currently is.
  String get turnColor => _game.turn == lib_chess.Color.WHITE ? 'w' : 'b';

  bool get isCheck => _game.in_check;
  bool get isCheckmate => _game.in_checkmate;
  bool get isStalemate => _game.in_stalemate;
  bool get isDraw => _game.in_draw;
  bool get isGameOver => _game.game_over;

  /// FEN string for the current position — used to pass state to Stockfish.
  String get fen => _game.fen;

  /// Attempts a move given in UCI-ish form, e.g. "e2e4" or "e7e8q" for promotion.
  /// Returns true if the move was legal and applied.
  bool applyMoveUci(String uciMove) {
    if (uciMove.length < 4) return false;
    final from = uciMove.substring(0, 2);
    final to = uciMove.substring(2, 4);
    final promotion = uciMove.length > 4 ? uciMove.substring(4, 5) : null;

    final move = <String, String>{
      'from': from,
      'to': to,
      if (promotion != null) 'promotion': promotion,
    };
    final result = _game.move(move);
    return result != null && result != false;
  }

  /// Returns all legal destination squares for a piece on [square], e.g. "e2".
  List<String> legalMovesFrom(String square) {
    final moves = _game.generate_moves({'square': square});
    return moves.map<String>((m) => m.toAlgebraic).toList();
  }

  /// Returns the piece code at a square, e.g. "N" for white knight, "p" for black pawn,
  /// or null if empty. Uppercase = white, lowercase = black.
  String? pieceAt(String square) {
    final piece = _game.get(square);
    if (piece == null) return null;
    final letter = piece.type.toString(); // e.g. 'n', 'p', 'k'
    return piece.color == lib_chess.Color.WHITE
        ? letter.toUpperCase()
        : letter.toLowerCase();
  }

  /// Full-name lookup for hint text, e.g. "N" -> "Knight".
  static const Map<String, String> pieceNames = {
    'p': 'Pawn',
    'n': 'Knight',
    'b': 'Bishop',
    'r': 'Rook',
    'q': 'Queen',
    'k': 'King',
  };

  String pieceFullName(String pieceCode) {
    return pieceNames[pieceCode.toLowerCase()] ?? 'Piece';
  }

  /// 8x8 board snapshot, row 0 = rank 8 (top, from White's view) down to row 7 = rank 1.
  /// Each cell is the piece code (see [pieceAt]) or null.
  List<List<String?>> get boardGrid {
    final grid = List.generate(8, (_) => List<String?>.filled(8, null));
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    for (int rank = 8; rank >= 1; rank--) {
      for (int fileIdx = 0; fileIdx < 8; fileIdx++) {
        final square = '${files[fileIdx]}$rank';
        grid[8 - rank][fileIdx] = pieceAt(square);
      }
    }
    return grid;
  }

  void reset() => _game.reset();
}
