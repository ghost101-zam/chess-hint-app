import 'package:flutter/material.dart';
import 'chess_logic.dart';

const Map<String, String> _pieceGlyphs = {
  'P': '♙',
  'N': '♘',
  'B': '♗',
  'R': '♖',
  'Q': '♕',
  'K': '♔',
  'p': '♟',
  'n': '♞',
  'b': '♝',
  'r': '♜',
  'q': '♛',
  'k': '♚',
};

enum DotHintStage {
  hidden,
  source,
  destination,
}

const double _borderThickness = 22;

class BoardWidget extends StatelessWidget {
  final ChessLogic logic;
  final String? selectedSquare;
  final List<String> legalTargets;

  final String? hintSource;
  final String? hintDest;
  final DotHintStage hintStage;

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
    this.hintStage = DotHintStage.hidden,
    this.flipped = false,
  });

  @override
  Widget build(BuildContext context) {
    final grid = logic.boardGrid;
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

    final activeHintSquare = hintStage == DotHintStage.source
        ? hintSource
        : hintStage == DotHintStage.destination
            ? hintDest
            : null;

    final fileIndex = activeHintSquare == null
        ? null
        : files.indexOf(activeHintSquare[0]) + 1;

    final rankNumber = activeHintSquare == null
        ? null
        : int.tryParse(activeHintSquare[1]);

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B3F1D),
              Color(0xFF4A2A12),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(_borderThickness),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = constraints.maxWidth / 8;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
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

                    Color bg = isDark
                        ? const Color(0xFFB07C4F)
                        : const Color(0xFFF0D9B5);

                    if (isSelected) {
                      bg = const Color(0xFFF6EE6B);
                    }

                    return GestureDetector(
                      onTap: () => onSquareTap(square),
                      child: Container(
                        color: bg,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (piece != null)
                              _StyledPiece(piece: piece),

                            if (isLegalTarget)
                              Container(
                                width: cellSize * 0.25,
                                height: cellSize * 0.25,
                                decoration: const BoxDecoration(
                                  color: Colors.black38,
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

                // LEFT SIDE: FILE DOTS
                if (fileIndex != null)
                  Positioned(
                    left: -18,
                    top: 0,
                    bottom: 0,
                    child: _DotColumn(
                      count: fileIndex,
                      cellSize: cellSize,
                    ),
                  ),

                // RIGHT SIDE: RANK DOTS
                if (rankNumber != null)
                  Positioned(
                    right: -18,
                    top: 0,
                    bottom: 0,
                    child: _DotColumn(
                      count: rankNumber,
                      cellSize: cellSize,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DotColumn extends StatelessWidget {
  final int count;
  final double cellSize;

  const _DotColumn({
    required this.count,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD166),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB703).withOpacity(0.8),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StyledPiece extends StatelessWidget {
  final String piece;

  const _StyledPiece({
    required this.piece,
  });

  @override
  Widget build(BuildContext context) {
    final glyph = _pieceGlyphs[piece] ?? '';
    final isWhite = piece == piece.toUpperCase();

    final fillColor = isWhite
        ? const Color(0xFFFFFDF5)
        : const Color(0xFF171717);

    final outlineColor = isWhite
        ? const Color(0xFF6B4A2A)
        : const Color(0xFFE0E0E0);

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
              Shadow(
                color: Colors.black54,
                blurRadius: 3,
                offset: Offset(1, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
