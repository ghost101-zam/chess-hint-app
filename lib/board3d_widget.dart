import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'chess_logic.dart';

/// Renders the 3D chess board via a local (offline) Three.js scene.
/// Same external interface as the old 2D BoardWidget, so main.dart barely
/// changes: pass in selection/hint state, get square taps back out.
class Board3DWidget extends StatefulWidget {
  final ChessLogic logic;
  final String? selectedSquare;
  final List<String> legalTargets;
  final String? hintSource;
  final String? hintDest;
  final void Function(String square) onSquareTap;
  final bool flipped;

  const Board3DWidget({
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
  State<Board3DWidget> createState() => _Board3DWidgetState();
}

class _Board3DWidgetState extends State<Board3DWidget> {
  late final WebViewController _controller;
  bool _pageReady = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'BoardChannel',
        onMessageReceived: (message) {
          try {
            final data = jsonDecode(message.message) as Map<String, dynamic>;
            if (data['type'] == 'tap' && data['square'] is String) {
              widget.onSquareTap(data['square'] as String);
            }
          } catch (_) {
            // Ignore malformed messages from the WebView.
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _pageReady = true;
            _pushState();
          },
        ),
      )
      ..loadFlutterAsset('assets/board3d.html');
  }

  @override
  void didUpdateWidget(covariant Board3DWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pushState();
  }

  void _pushState() {
    if (!_pageReady) return;
    final boardMap = <String, String>{};
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    for (int rank = 1; rank <= 8; rank++) {
      for (int f = 0; f < 8; f++) {
        final square = '${files[f]}$rank';
        final piece = widget.logic.pieceAt(square);
        if (piece != null) boardMap[square] = piece;
      }
    }

    final state = {
      'board': boardMap,
      'selectedSquare': widget.selectedSquare,
      'legalTargets': widget.legalTargets,
      'hintSource': widget.hintSource,
      'hintDest': widget.hintDest,
      'flipped': widget.flipped,
    };

    final json = jsonEncode(state).replaceAll(r'\', r'\\').replaceAll("'", r"\'");
    _controller.runJavaScript("window.updateBoard('$json');");
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: WebViewWidget(controller: _controller),
    );
  }
}
