# Local Two-Player Chess with Shared Hints

Offline, face-to-face 2-player chess for a single phone laid on a table.
Either player can request a hint at any time — it renders as plain text
in one shared panel, visible to both players, with no hidden or coded
elements.

## What's included

| File | Purpose |
|---|---|
| `lib/chess_logic.dart` | Rules engine wrapper (legal moves, check/mate/stalemate, FEN export) |
| `lib/stockfish_service.dart` | Local, offline Stockfish binding — no network calls |
| `lib/hint_service.dart` | Converts an engine move into plain-language hint text |
| `lib/hint_bar.dart` | The one visible hint UI surface (shared, same for both players) |
| `lib/board_widget.dart` | Tap-to-move board (2D placeholder — see "Going 3D" below) |
| `lib/main.dart` | Start screen + game screen, wires everything together |

## Setup

1. Install Flutter (stable channel): https://docs.flutter.dev/get-started/install
2. From the project root:
   ```
   flutter pub get
   ```
3. Add Stockfish native binaries. `flutter_stockfish` needs the engine
   binary bundled per-platform:
   - Follow the package's install instructions: https://pub.dev/packages/flutter_stockfish
   - For Android this typically means adding the prebuilt `.so` files under
     `android/app/src/main/jniLibs/<abi>/` for each ABI you target
     (arm64-v8a, armeabi-v7a, x86_64).
   - No internet access is required at runtime — the engine runs as a
     local native process once bundled.
4. Run on a connected device or emulator:
   ```
   flutter run
   ```
5. Build a release APK:
   ```
   flutter build apk --release
   ```
   Output lands in `build/app/outputs/flutter-apk/app-release.apk`.

## How the hint system works (by design)

- There is exactly **one** hint display (`HintBar`), rendered once per
  screen, not per player and not per camera angle.
- Hints are **plain text** ("Move your Knight from g1 to f3"), not
  coded symbols, dot counts, or anything requiring a decode step.
- Hints appear **immediately** on request — no timed multi-stage reveal.
- Either player can tap "Show Hint" on their turn; there's no
  asymmetry in who has access to it.
- Three text tiers are available (`HintTier` in `hint_service.dart`):
  `simple`, `beginner`, `explained` — pick per your teaching needs.

If you want to change how strong/instant the suggestions are, adjust
`thinkTimeMs` in `stockfish_service.dart`'s `bestMove()` call — shorter
times keep it snappy for casual/beginner play.

## 3D board (now included)

The app now ships with a working 3D board: `assets/board3d.html` is a
Three.js scene rendered inside a `webview_flutter` WebView
(`lib/board3d_widget.dart`), fully offline — it loads as a bundled
Flutter asset, not from any CDN or network URL. Pieces are built from
primitive geometry (cones/cylinders) so no external 3D model files are
needed, and each piece type is visually distinct (pawn = small cone,
rook = squat cylinder, knight = tall narrow cone, bishop = tall cone,
queen/king = tallest, king has a small cross topper).

**One manual step required:** you need to supply `three.min.js`
yourself and place it at `assets/three.min.js`, since it wasn't
downloaded as part of generating this project (keeping the app free of
any network dependency, including at build time, was intentional).
Get an official release build from https://github.com/mrdoob/three.js/
(the `build/three.min.js` file from a tagged release, r128 or similar
is plenty for this scene) and drop it in `assets/` next to
`board3d.html`. Once it's there, `flutter pub get` will bundle it as
declared in `pubspec.yaml`.

**How it talks to the rest of the app:**
- Flutter → JS: `Board3DWidget` calls `window.updateBoard(jsonState)`
  whenever the board, selection, legal-move dots, or hint highlights
  change. The JSON just has `board`, `selectedSquare`, `legalTargets`,
  `hintSource`, `hintDest`, `flipped`.
- JS → Flutter: tapping a square raycasts against the board meshes and
  posts `{"type":"tap","square":"e4"}` back through the
  `BoardChannel` JavaScript channel, which calls your existing
  `onSquareTap` callback — same as the old 2D board, so none of the
  game logic, move validation, or hint code had to change.
- The camera flips to face the other direction based on `flipped`,
  matching the manual/automatic view-flip already in `main.dart`.

**Hint text still renders natively in Flutter** (`HintBar`), not inside
the 3D scene — it sits below the WebView exactly as before. Only the
*board itself* moved into 3D; the one shared hint surface stays a
plain overlay widget so it's simple to keep consistent and legible for
both players regardless of camera angle.

**Old 2D board:** `lib/board_widget.dart` is left in the project
unused, in case you want a lightweight fallback (e.g., for very old
devices where the WebView/GL path is slow) — just swap the import back
in `main.dart` if needed.

**Performance note:** WebView + Three.js is the fastest way to get a
real 3D board working without native build complexity, but if you
later want tighter integration (haptics, native camera controls, etc.)
the alternative is dropping the HTML/JS approach for `flutter_gl` or a
Unity module — the interface (`Board3DWidget`'s constructor) is small
enough that swapping the internals later won't require changes
anywhere else in the app.

## Notes

- Camera/view "flip" is currently a manual button plus an automatic
  flip after each move — this just reorients the board so it's easier
  to read from either side of the table, matching how you'd physically
  rotate a real board. It does not change what information either
  player can see.
