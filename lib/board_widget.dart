import 'package:flutter/material.dart';
import 'chess_logic.dart';

/// Unicode glyphs for rendering pieces without needing image assets yet.
/// Swap this out for real 3D models / sprites later — the board layout
/// and interaction logic underneath stays the same.
const Map<String, String> _pieceGlyphs = {
  'P': '♙', 'N': '♘', 'B': '♗', 'R': '♖', 'Q': '♕', 'K': '♔',
  'p': '♟', 'n': '♞', 'b': '♝', 'r': '♜', 'q': '♛', 'k': '♚',
};

class BoardWidget extends StatelessWidget {
  final ChessLogic logic;
  final String? selectedSquare;
  final List<String> legalTargets;
  final String? hintSource;
  final String? hintDest;
  final void Function(String square) onSquareTap;
  final bool flipped; // true = render from Black's perspective

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
    final grid = logic.boardGrid; // row 0 = rank 8 ... row 7 = rank 1
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
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
                  ? const Color(0xFF769656)
                  : const Color(0xFFEEEED2);
              if (isSelected) bg = const Color(0xFFF6F669);
              if (isHintSource) bg = const Color(0xFF66B2FF);
              if (isHintDest) bg = const Color(0xFF66FF99);

              return GestureDetector(
                onTap: () => onSquareTap(square),
                child: Container(
                  color: bg,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (piece != null)
                        Text(
                          _pieceGlyphs[piece] ?? '',
                          style: const TextStyle(fontSize: 28),
                        ),
                      if (isLegalTarget)
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
