import 'chess_logic.dart';

enum HintTier { simple, beginner, explained }

class HintResult {
  final String sourceSquare;
  final String destSquare;
  final String pieceCode;
  final String displayText;
  const HintResult({
    required this.sourceSquare,
    required this.destSquare,
    required this.pieceCode,
    required this.displayText,
  });
}

/// Turns a raw UCI move ("g1f3") into a plain-language hint string.
/// This is the ONLY hint surface in the app: it renders identically for
/// whichever player's turn it is, with no per-viewer variation, no coded
/// symbols, and no time-delayed reveal. Anyone looking at the screen sees
/// the same thing.
class HintService {
  final ChessLogic logic;
  HintService(this.logic);

  HintResult? buildHint(String uciMove, {HintTier tier = HintTier.beginner}) {
    if (uciMove.length < 4) return null;
    final from = uciMove.substring(0, 2);
    final to = uciMove.substring(2, 4);
    final pieceCode = logic.pieceAt(from) ?? 'p';
    final pieceName = logic.pieceFullName(pieceCode);
    final isCapture = logic.pieceAt(to) != null;

    String text;
    switch (tier) {
      case HintTier.simple:
        text = '$from → $to';
        break;
      case HintTier.beginner:
        text = 'Move your $pieceName from $from to $to';
        break;
      case HintTier.explained:
        final reasonTag = isCapture
            ? 'captures a piece on $to'
            : _positionalTag(from, to, pieceCode);
        text = 'Move your $pieceName from $from to $to — $reasonTag';
        break;
    }

    return HintResult(
      sourceSquare: from,
      destSquare: to,
      pieceCode: pieceCode,
      displayText: text,
    );
  }

  /// Very lightweight heuristic tagging for the "explained" tier.
  /// Not a substitute for real engine annotation, just enough to make
  /// hints feel instructive rather than robotic for a beginner.
  String _positionalTag(String from, String to, String pieceCode) {
    final backRanks = {'1', '8'};
    final centerSquares = {'d4', 'd5', 'e4', 'e5'};
    if (pieceCode.toLowerCase() != 'p' &&
        backRanks.contains(from.substring(1)) &&
        !backRanks.contains(to.substring(1))) {
      return 'this develops a piece off the back rank';
    }
    if (centerSquares.contains(to)) {
      return 'this helps control the center';
    }
    if (pieceCode.toLowerCase() == 'k' && (from == 'e1' || from == 'e8')) {
      return 'this improves king safety';
    }
    return 'this is the engine\'s recommended move here';
  }
}
