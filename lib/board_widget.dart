import 'package:flutter/material.dart';
import 'chess_logic.dart';

const Map<String, String> _pieceGlyphs = {
  'P': '♙', 'N': '♘', 'B': '♗', 'R': '♖', 'Q': '♕', 'K': '♔',
  'p': '♟', 'n': '♞', 'b': '♝', 'r': '♜', 'q': '♛', 'k': '♚',
};

const double _borderThickness = 22;

class BoardWidget extends StatelessWidget {
  final ChessLogic logic;
  final String? selectedSquare;
  final List<String> legalTargets;
  final String? hintSource;
  final String? hintDest;
  final void Function(String square) onSquareTap;
  final bool flipped;

  const BoardWidget({
    super.key,
    required this.logic,
    required this.onSquareTap,
    this.selectedSquare,
    this.legalTargets = const [],
    this.hintSource,
    this.hintDest,
    this.flipped = false,
  });

  @override
  Widget build(BuildContext context) {
    final grid = logic.boardGrid;
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B3F1D), Color(0xFF4A2A12)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(_borderThickness),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = constraints.maxWidth / 8;
            return Stack(
              children: [
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                  ),
                  itemCount: 64,
                  itemBuilder: (context, index) {
                    int row = index ~/ 8;
                    int col = index % 8;
                    if (flipped) {
                      row = 7 - row;
                      col = 7 - col;
                    }
                    final rank = 8 - row;
                    final file = files[col];
                    final square = '$file$rank';
                    final piece = grid[row][col];
                    final isDark = (row + col) % 2 == 1;
                    final isSelected = square == selectedSquare;
                    final isLegalTarget = legalTargets.contains(square);
                    final isHintSource = square == hintSource;
                    final isHintDest = square == hintDest;

                    Color bg = isDark
                        ? const Color(0xFFB07C4F)
                        : const Color(0xFFF0D9B5);
                    if (isSelected) bg = const Color(0xFFF6EE6B);
                    if (isHintSource) bg = const Color(0xFF7EC8FF);
                    if (isHintDest) bg = const Color(0xFF8CE99A);

                    return GestureDetector(
                      onTap: () => onSquareTap(square),
                      child: Container(
                        color: bg,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (piece != null) _StyledPiece(piece: piece),
                            if (isLegalTarget)
                              Container(
                                width: cellSize * 0.28,
                                height: cellSize * 0.28,
                                decoration: const BoxDecoration(
                                  color: Colors.black26,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (row == 7)
                              Positioned(
                                bottom: 2,
                                right: 3,
                                child: Text(
                                  file,
                                  style: TextStyle(
                                    fontSize: cellSize * 0.16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? const Color(0xFFF0D9B5)
                                        : const Color(0xFFB07C4F),
                                  ),
                                ),
                              ),
                            if (col == 0)
                              Positioned(
                                top: 2,
                                left: 3,
                                child: Text(
                                  '$rank',
                                  style: TextStyle(
                                    fontSize: cellSize * 0.16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? const Color(0xFFF0D9B5)
                                        : const Color(0xFFB07C4F),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Renders a piece glyph with a subtle outline + shadow so it reads as a
/// more polished, glossy piece rather than flat plain text.
class _StyledPiece extends StatelessWidget {
  final String piece;
  const _StyledPiece({required this.piece});

  @override
  Widget build(BuildContext context) {
    final glyph = _pieceGlyphs[piece] ?? '';
    final isWhite = piece == piece.toUpperCase();
    final fillColor = isWhite ? const Color(0xFFFFFDF5) : const Color(0xFF1A1A1A);
    final outlineColor = isWhite ? const Color(0xFF6B4A2A) : const Color(0xFFDDDDDD);

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          glyph,
          style: TextStyle(
            fontSize: 38,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4
              ..color = outlineColor,
          ),
        ),
        Text(
          glyph,
          style: TextStyle(
            fontSize: 38,
            color: fillColor,
            shadows: const [
              Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(1, 2)),
            ],
          ),
        ),
      ],
    );
  }
}
