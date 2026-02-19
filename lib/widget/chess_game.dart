import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_pkg;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sakura_particles.dart';
import 'dart:math';
import 'dart:async';
import 'crt_overlay.dart';

enum Difficulty { Normal, Hard, Magnus }

class MoveInfo {
  final String san;
  final chess_pkg.Piece piece;
  final String from;
  final String to;
  final bool isAI;

  MoveInfo({
    required this.san,
    required this.piece,
    required this.from,
    required this.to,
    required this.isAI,
  });
}

class ChessGame extends StatefulWidget {
  final VoidCallback onClose;
  final Function(String, {String? english, String? emotion})? onSpeak;

  const ChessGame({super.key, required this.onClose, this.onSpeak});

  @override
  State<ChessGame> createState() => _ChessGameState();
}

class _ChessGameState extends State<ChessGame> {
  late chess_pkg.Chess game;
  int? selectedIndex;
  Difficulty _difficulty = Difficulty.Normal;
  bool isAiThinking = false;
  bool isGameStarted = false;
  bool showSummary = false;
  List<MoveInfo> moveHistory = [];
  List<int> validMoveIndices = [];
  bool isVrmReady = false;

  // Professional features
  List<chess_pkg.Piece> capturedWhite = [];
  List<chess_pkg.Piece> capturedBlack = [];
  int userBestMoves = 0;
  int userMistakes = 0;
  int userBlunders = 0;
  String lastMoveQuality = "";

  // Timers
  int whiteTimeSeconds = 600;
  int blackTimeSeconds = 600;
  Timer? gameTimer;

  @override
  void initState() {
    super.initState();
    game = chess_pkg.Chess();

    // Simulate VRM ready/greeting since controller is external
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => isVrmReady = true);
        widget.onSpeak?.call("お待たせしました、ご主人様！チェスのエンジンと Sakura の準備ができました！",
            english:
                "System Online. Chess Engine & Sakura Ready! Good luck, Master!",
            emotion: "joy");
        if (isGameStarted) {
          _startTimer();
        }
      }
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // If game is over, stop timer
      if (game.game_over) {
        timer.cancel();
        return;
      }
      // Only count down if game is started
      if (!isGameStarted) {
        return;
      }

      setState(() {
        if (game.turn == chess_pkg.Color.WHITE) {
          if (whiteTimeSeconds > 0) whiteTimeSeconds--;
        } else {
          if (blackTimeSeconds > 0) blackTimeSeconds--;
        }
      });
    });
  }

  void onSquareTap(int index) {
    if (!isGameStarted ||
        isAiThinking ||
        game.game_over ||
        game.turn != chess_pkg.Color.WHITE) {
      return;
    }

    if (selectedIndex == null) {
      final piece = game.get(indexToSquare(index));
      if (piece != null && piece.color == chess_pkg.Color.WHITE) {
        setState(() {
          selectedIndex = index;
          // Map grid index to package 0x88 index
          int pkgIndex = (index ~/ 8) * 16 + (index % 8);
          validMoveIndices = game
              .generate_moves()
              .where((m) => m.from == pkgIndex)
              .map((m) => (m.to ~/ 16) * 8 + (m.to % 16))
              .toList();
        });
      }
    } else {
      final from = indexToSquare(selectedIndex!);
      final to = indexToSquare(index);

      int beforeEval = _evaluateBoard();
      final targetPiece = game.get(to);

      final success = game.move({'from': from, 'to': to, 'promotion': 'q'});
      if (success) {
        if (targetPiece != null) {
          setState(() => capturedBlack.add(targetPiece));
        }

        _analyzeUserMove(beforeEval, from: from, to: to, piece: game.get(to)!);

        final history = game.getHistory();
        setState(() {
          if (history.isNotEmpty) {
            final lastMove = game.history.last;
            moveHistory.add(MoveInfo(
              san: history.last,
              piece: chess_pkg.Piece(lastMove.move.piece, lastMove.move.color),
              from: from,
              to: to,
              isAI: false,
            ));
          }
          selectedIndex = null;
          validMoveIndices = [];
        });

        if (game.game_over) {
          _finishGame();
        } else {
          makeAiMove();
        }
      } else {
        setState(() {
          selectedIndex = null;
          validMoveIndices = [];
        });
      }
    }
  }

  void _analyzeUserMove(int beforeEval,
      {required String from,
      required String to,
      required chess_pkg.Piece piece}) {
    int afterEval = _evaluateBoard();
    int diff = afterEval - beforeEval;

    setState(() {
      if (diff > 50) {
        userBestMoves++;
        lastMoveQuality = "BEST";
      } else if (diff < -150) {
        userBlunders++;
        lastMoveQuality = "BLUNDER";
      } else if (diff < -50) {
        userMistakes++;
        lastMoveQuality = "MISTAKE";
      } else {
        lastMoveQuality = "GOOD";
      }

      _triggerVrmReaction(lastMoveQuality, from: from, to: to, piece: piece);
    });
  }

  DateTime? lastReactionTime;

  void _triggerVrmReaction(String quality,
      {String? from, String? to, chess_pkg.Piece? piece}) {
    // Prevent spam: only react every 1.5 seconds unless it's a major event (check/mate)
    if (lastReactionTime != null &&
        DateTime.now().difference(lastReactionTime!) <
            const Duration(milliseconds: 1500) &&
        !game.in_check &&
        !game.in_checkmate) {
      return;
    }

    String ja = "";
    String en = "";
    String emotion = "neutral";

    String pieceName = _getPieceName(piece);

    if (game.in_checkmate) {
      emotion = game.turn == chess_pkg.Color.BLACK ? "sorrow" : "joy";
      ja = game.turn == chess_pkg.Color.BLACK
          ? "負けました…。お見事です、ご主人様。"
          : "まいりましたか？Sakura の勝ちですね！";
      en = game.turn == chess_pkg.Color.BLACK
          ? "I lost... impressive, Master."
          : "GG! Sakura wins this time!";
    } else if (game.in_check) {
      emotion = "angry";
      ja = "チェックです！逃がしませんよ？";
      en = "Check! I won't let you escape!";
    } else {
      if (quality == "BLUNDER") {
        emotion = "fun";
        ja = "あらら、$pieceName を $to に？ それは大きな失策ですよ？ふふっ。";
        en = "Oh? Moving your $pieceName to $to? That was a blunder! Fufufu...";
      } else if (quality == "MISTAKE") {
        emotion = "neutral";
        ja = "$pieceName を $to に動かしたのは…あまり良くない手ですね。";
        en = "Moving your $pieceName to $to... that wasn't a very good move.";
      } else if (quality == "BEST") {
        emotion = "sorrow";
        ja = "$pieceName を $to ですか…。素晴らしい一手ですね、ご主人様。";
        en = "Your $pieceName to $to... that's a brilliant move, Master.";
      } else if (quality == "GOOD") {
        // 100% chance to praise a normal good move as requested
        List<Map<String, String>> praises = [
          {
            "ja": "$pieceName を動かしましたね。なかなかやります。",
            "en": "You moved your $pieceName. Not bad..."
          },
          {
            "ja": "$to への一手、悪くないですよ。",
            "en": "That move to $to is actually decent."
          },
          {
            "ja": "ふむ、ご主人様の $pieceName が気になりますね。",
            "en": "Hmm, your $pieceName is bothering me..."
          },
          {
            "ja": "調子が出てきましたか？ $pieceName が躍動しています。",
            "en": "Getting into the rhythm? Your $pieceName is active!"
          },
          {
            "ja": "油断できませんね、$pieceName を狙ってきましたか。",
            "en": "I can't let my guard down, aiming with your $pieceName?"
          },
        ];
        var p = praises[Random().nextInt(praises.length)];
        ja = p["ja"]!;
        en = p["en"]!;
        emotion = "neutral";
      }
    }

    if (ja.isNotEmpty) {
      lastReactionTime = DateTime.now();
      widget.onSpeak?.call(ja, english: en, emotion: emotion);
    }
  }

  String _getPieceName(chess_pkg.Piece? piece) {
    if (piece == null) return "Piece";
    switch (piece.type) {
      case chess_pkg.PieceType.PAWN:
        return "Pawn";
      case chess_pkg.PieceType.KNIGHT:
        return "Knight";
      case chess_pkg.PieceType.BISHOP:
        return "Bishop";
      case chess_pkg.PieceType.ROOK:
        return "Rook";
      case chess_pkg.PieceType.QUEEN:
        return "Queen";
      case chess_pkg.PieceType.KING:
        return "King";
      default:
        return "Piece";
    }
  }

  void _finishGame() {
    gameTimer?.cancel();
    setState(() => showSummary = true);
    if (game.in_checkmate) {
      bool userWon = game.turn == chess_pkg.Color.BLACK;
      widget.onSpeak?.call(
          userWon ? "負けました…。お見事です、ご主人様。" : "まいりましたか？Sakura の勝ちですね！",
          english: userWon
              ? "I lost... impressive, Master."
              : "GG! Sakura wins this time!",
          emotion: userWon ? "sorrow" : "joy");
    }
  }

  int _calculatePredictedElo() {
    int base = _difficulty == Difficulty.Normal
        ? 800
        : (_difficulty == Difficulty.Hard ? 1500 : 2200);
    base += (userBestMoves * 25);
    base -= (userBlunders * 60);
    base -= (userMistakes * 25);

    if (game.game_over) {
      if (game.in_checkmate && game.turn == chess_pkg.Color.BLACK) {
        base += 250;
      } else if (game.in_checkmate && game.turn == chess_pkg.Color.WHITE) {
        base -= 150;
      }
    }
    return base.clamp(400, 2900);
  }

  void makeAiMove() {
    setState(() => isAiThinking = true);
    // Wait if she is speaking, then wait 1s thinking time
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      timer.cancel();

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        try {
          final move = _getBestMove();
          if (move != null) {
            // Robust parsing for move.from and move.to
            var fromRaw = move.from;
            var toRaw = move.to;

            if (fromRaw == null || toRaw == null) {
              debugPrint("AI move error: 'from' or 'to' is null");
              return;
            }

            // Map indices carefully, ensuring they are integers
            int fromIdx = (fromRaw is int)
                ? fromRaw
                : int.tryParse(fromRaw.toString()) ?? 0;
            int toIdx =
                (toRaw is int) ? toRaw : int.tryParse(toRaw.toString()) ?? 0;

            final fromGrid = (fromIdx ~/ 16) * 8 + (fromIdx % 16);
            final toGrid = (toIdx ~/ 16) * 8 + (toIdx % 16);

            final targetPiece = game.get(indexToSquare(toGrid));
            if (targetPiece != null) {
              setState(() => capturedWhite.add(targetPiece));
            }

            final san = game.move_to_san(move);
            final pieceNode = game.get(indexToSquare(fromGrid));
            if (pieceNode == null) {
              debugPrint("AI move error: piece at $fromGrid is null");
              return;
            }
            final piece = pieceNode;
            final fromStr = indexToSquare(fromGrid);
            final toStr = indexToSquare(toGrid);

            game.make_move(move);

            moveHistory.add(MoveInfo(
              san: san,
              piece: piece,
              from: fromStr,
              to: toStr,
              isAI: true,
            ));

            _triggerAiComment(move, san);

            if (game.game_over) {
              _finishGame();
            }
          }
        } catch (e, stack) {
          debugPrint("AI error: $e\n$stack");
        } finally {
          if (mounted) setState(() => isAiThinking = false);
        }
      });
    });
  }

  void _triggerAiComment(dynamic move, String san, {bool isAIMove = false}) {
    // React more often, 80% chance for AI moves, 50% for player moves
    double reactionChance = isAIMove ? 0.8 : 0.5;
    if (Random().nextDouble() > reactionChance) return;

    final List<String> phrases = [
      "How about this?",
      "Take this!",
      "I see a path...",
      "Calculated.",
      "You won't like this one.",
      "Fufufu...",
      "Are you watching closely?",
      "Sakura's specialty!",
      "Don't blink!",
      "Check this move~",
    ];

    if (san.contains('+')) {
      widget.onSpeak?.call("王手！", english: "Check!", emotion: "fun");
    } else if (san.contains('#')) {
      // Handled in _finishGame usually, but just in case
    } else {
      final List<String> jaPhrases = [
        "どうですか？",
        "これならどうです？",
        "道が見えました…。",
        "計算通りです。",
        "これは嫌なはずですよ？",
        "ふふふっ…。",
        "よく見ててくださいね？",
        "Sakuraの特等席ですよ！",
        "瞬きしちゃダメですよ？",
        "この一手、どうですか？",
      ];
      int r = Random().nextInt(jaPhrases.length);
      widget.onSpeak
          ?.call(jaPhrases[r], english: phrases[r], emotion: "neutral");
    }
  }

  dynamic _getBestMove() {
    final moves = game.generate_moves();
    if (moves.isEmpty) return null;
    if (_difficulty == Difficulty.Normal) {
      return moves[Random().nextInt(moves.length)];
    }
    return _minimaxRoot(moves);
  }

  dynamic _minimaxRoot(List<dynamic> moves) {
    int bestValue = 99999;
    dynamic bestMove;
    int depth = _difficulty == Difficulty.Magnus ? 3 : 2;

    for (var move in moves) {
      game.make_move(move);
      int boardValue = _minimax(depth - 1, -10000, 10000, true);
      game.undo_move();
      if (boardValue < bestValue) {
        bestValue = boardValue;
        bestMove = move;
      }
    }
    return bestMove;
  }

  int _minimax(int depth, int alpha, int beta, bool isMaximizing) {
    if (depth == 0) return _evaluateBoard();
    final moves = game.generate_moves();
    if (moves.isEmpty) {
      if (game.in_checkmate) return isMaximizing ? -9999 : 9999;
      return 0;
    }
    if (isMaximizing) {
      int bestValue = -9999;
      for (var move in moves) {
        game.make_move(move);
        bestValue =
            max(bestValue, _minimax(depth - 1, alpha, beta, !isMaximizing));
        game.undo_move();
        alpha = max(alpha, bestValue);
        if (beta <= alpha) break;
      }
      return bestValue;
    } else {
      int bestValue = 9999;
      for (var move in moves) {
        game.make_move(move);
        bestValue =
            min(bestValue, _minimax(depth - 1, alpha, beta, !isMaximizing));
        game.undo_move();
        beta = min(beta, bestValue);
        if (beta <= alpha) break;
      }
      return bestValue;
    }
  }

  int _evaluateBoard() {
    int totalEvaluation = 0;
    for (int i = 0; i < 64; i++) {
      totalEvaluation += _getPieceValue(game.get(indexToSquare(i)));
    }
    return totalEvaluation;
  }

  int _getPieceValue(chess_pkg.Piece? piece) {
    if (piece == null) return 0;
    int value = 0;
    switch (piece.type) {
      case chess_pkg.PieceType.PAWN:
        value = 10;
        break;
      case chess_pkg.PieceType.ROOK:
        value = 50;
        break;
      case chess_pkg.PieceType.KNIGHT:
        value = 30;
        break;
      case chess_pkg.PieceType.BISHOP:
        value = 30;
        break;
      case chess_pkg.PieceType.QUEEN:
        value = 90;
        break;
      case chess_pkg.PieceType.KING:
        value = 900;
        break;
    }
    return piece.color == chess_pkg.Color.WHITE ? value : -value;
  }

  int _calculateAccuracy() {
    if (moveHistory.isEmpty) return 100;
    int total = moveHistory.where((m) => !m.isAI).length;
    if (total == 0) return 100;
    double score =
        (userBestMoves * 1.0 + (total - userMistakes - userBlunders) * 0.7) /
            total;
    return (score * 100).toInt().clamp(0, 100);
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.vt323(color: Colors.white54, fontSize: 10.sp)),
          Text(value,
              style: GoogleFonts.vt323(
                  color: color, fontSize: 11.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String indexToSquare(int index) {
    int file = index % 8;
    int rank = 8 - (index ~/ 8);
    return '${String.fromCharCode(97 + file)}$rank';
  }

  @override
  Widget build(BuildContext context) {
    return CrtOverlay(
      child: Container(
        width: 1000.w,
        height: 700.h,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16.r),
          // Removed border and shadow for cleaner "Linux Box" look
        ),
        child: Stack(
          children: [
            const IgnorePointer(child: SakuraParticles()),
            Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildBoardArea(),
                      _buildSidebar(),
                    ],
                  ),
                ),
              ],
            ),
            if (!isGameStarted) _buildPreGameMenu(),
            if (showSummary) _buildGameSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardArea() {
    return Expanded(
      flex: 3,
      child: Column(
        children: [
          _buildPlayerBar(isAI: true),
          Expanded(child: Center(child: _buildBoard())),
          _buildPlayerBar(isAI: false),
        ],
      ),
    );
  }

  Widget _buildPlayerBar({required bool isAI}) {
    final time = isAI ? blackTimeSeconds : whiteTimeSeconds;
    final minutes = (time ~/ 60).toString().padLeft(2, '0');
    final seconds = (time % 60).toString().padLeft(2, '0');
    final pieces = isAI ? capturedWhite : capturedBlack;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12.r,
                backgroundColor: isAI
                    ? Colors.pinkAccent.withOpacity(0.2)
                    : Colors.cyanAccent.withOpacity(0.2),
                child: Icon(isAI ? Icons.auto_awesome : Icons.bolt,
                    size: 14.r,
                    color: isAI ? Colors.pinkAccent : Colors.cyanAccent),
              ),
              SizedBox(width: 16.w),
              ...pieces.map((p) => Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: _buildMiniPiece(p))),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4.r)),
            child: Text("$minutes:$seconds",
                style: GoogleFonts.vt323(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return Container(
      padding: EdgeInsets.all(24.r),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.cyanAccent.withOpacity(0.2), width: 4),
              borderRadius: BorderRadius.circular(4.r)),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8),
            itemCount: 64,
            itemBuilder: (context, index) {
              bool isDark = ((index ~/ 8) + (index % 8)) % 2 != 0;
              bool isSelected = selectedIndex == index;
              bool isValid = validMoveIndices.contains(index);
              final piece = game.get(indexToSquare(index));
              final isWhite = piece?.color == chess_pkg.Color.WHITE;

              return GestureDetector(
                onTap: () => onSquareTap(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.pinkAccent.withOpacity(0.3)
                        : (isDark
                            ? const Color(0xFF1a1c2c).withOpacity(0.7)
                            : const Color(0xFF2d314d).withOpacity(0.7)),
                    border: isSelected
                        ? Border.all(color: Colors.pinkAccent, width: 2)
                        : (isValid
                            ? Border.all(
                                color: Colors.cyanAccent.withOpacity(0.3))
                            : null),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Opacity(
                          opacity: (game.turn == chess_pkg.Color.WHITE &&
                                      !isWhite) ||
                                  (game.turn == chess_pkg.Color.BLACK &&
                                      isWhite)
                              ? 0.8
                              : 1.0,
                          child: _buildVectorPiece(piece),
                        ),
                      ),
                      if (isValid)
                        Center(
                          child: Container(
                            width: 12.r,
                            height: 12.r,
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withOpacity(0.5),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyanAccent.withOpacity(0.4),
                                  blurRadius: 6,
                                )
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVectorPiece(chess_pkg.Piece? piece) {
    if (piece == null) return const SizedBox();
    double size = 45.sp;
    bool isWhite = piece.color == chess_pkg.Color.WHITE;
    switch (piece.type) {
      case chess_pkg.PieceType.PAWN:
        return isWhite ? WhitePawn(size: size) : BlackPawn(size: size);
      case chess_pkg.PieceType.ROOK:
        return isWhite ? WhiteRook(size: size) : BlackRook(size: size);
      case chess_pkg.PieceType.KNIGHT:
        return isWhite ? WhiteKnight(size: size) : BlackKnight(size: size);
      case chess_pkg.PieceType.BISHOP:
        return isWhite ? WhiteBishop(size: size) : BlackBishop(size: size);
      case chess_pkg.PieceType.QUEEN:
        return isWhite ? WhiteQueen(size: size) : BlackQueen(size: size);
      case chess_pkg.PieceType.KING:
        return isWhite ? WhiteKing(size: size) : BlackKing(size: size);
    }
    return const SizedBox();
  }

  Widget _buildMiniPiece(chess_pkg.Piece piece) {
    double size = 18.sp;
    bool isWhite = piece.color == chess_pkg.Color.WHITE;
    switch (piece.type) {
      case chess_pkg.PieceType.PAWN:
        return isWhite ? WhitePawn(size: size) : BlackPawn(size: size);
      case chess_pkg.PieceType.ROOK:
        return isWhite ? WhiteRook(size: size) : BlackRook(size: size);
      case chess_pkg.PieceType.KNIGHT:
        return isWhite ? WhiteKnight(size: size) : BlackKnight(size: size);
      case chess_pkg.PieceType.BISHOP:
        return isWhite ? WhiteBishop(size: size) : BlackBishop(size: size);
      case chess_pkg.PieceType.QUEEN:
        return isWhite ? WhiteQueen(size: size) : BlackQueen(size: size);
      case chess_pkg.PieceType.KING:
        return isWhite ? WhiteKing(size: size) : BlackKing(size: size);
    }
    return const SizedBox();
  }

  Widget _buildSidebar() {
    return Container(
      width: 280.w,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withOpacity(0.9),
        border:
            Border(left: BorderSide(color: Colors.pinkAccent.withOpacity(0.2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10.h),
          Text("TACTICAL DATA",
              style: GoogleFonts.orbitron(
                  color: Colors.cyanAccent,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
          SizedBox(height: 8.h),
          _analysisBadge(),
          SizedBox(height: 12.h),
          _buildStatRow(
              "ACCURACY", "${_calculateAccuracy()}%", Colors.greenAccent),
          const Divider(color: Colors.white10),
          Expanded(
            child: ListView.builder(
              itemCount: moveHistory.length,
              itemBuilder: (context, i) {
                final move = moveHistory[i];
                return Container(
                  margin: EdgeInsets.only(bottom: 6.h),
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: move.isAI
                        ? Colors.pinkAccent.withOpacity(0.05)
                        : Colors.cyanAccent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: (move.isAI ? Colors.pinkAccent : Colors.cyanAccent)
                          .withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text("${i + 1}.",
                          style: GoogleFonts.vt323(
                              color: Colors.white38, fontSize: 10.sp)),
                      SizedBox(width: 8.w),
                      _buildMiniPiece(move.piece),
                      SizedBox(width: 4.w),
                      Text(move.san,
                          style: GoogleFonts.vt323(
                              color: Colors.white, fontSize: 12.sp)),
                      const Spacer(),
                      Text("${move.from}→${move.to}",
                          style: GoogleFonts.vt323(
                              color: Colors.white38, fontSize: 10.sp)),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12.h),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: BorderSide(color: Colors.pinkAccent.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                minimumSize: Size(double.infinity, 40.h)),
            onPressed: () => setState(() {
              game = chess_pkg.Chess();
              isGameStarted = false;
              moveHistory.clear();
              capturedWhite.clear();
              capturedBlack.clear();
              userBestMoves = 0;
              userMistakes = 0;
              userBlunders = 0;
              lastMoveQuality = "";
            }),
            child: Text("REBOOT ENGINE",
                style: GoogleFonts.vt323(
                    fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
          ),
        ],
      ),
    );
  }

  Widget _analysisBadge() {
    if (lastMoveQuality.isEmpty) {
      return const SizedBox();
    }
    Color c = Colors.greenAccent;
    if (lastMoveQuality == "BLUNDER") {
      c = Colors.redAccent;
    } else if (lastMoveQuality == "MISTAKE") {
      c = Colors.orangeAccent;
    }

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          border: Border.all(color: c),
          borderRadius: BorderRadius.circular(8.r)),
      child: Center(
          child: Text(lastMoveQuality,
              style: TextStyle(color: c, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildPreGameMenu() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          width: 400.w,
          padding: EdgeInsets.all(32.r),
          decoration: BoxDecoration(
            color: const Color(0xFF282A36),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.pinkAccent.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("SELECT DIFFICULTY",
                  style: TextStyle(
                      color: Colors.pinkAccent,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tenada')),
              SizedBox(height: 30.h),
              _lobbyBtn(
                  Difficulty.Normal, "NORMAL", "800 ELO", Colors.greenAccent),
              _lobbyBtn(
                  Difficulty.Hard, "ELITE", "1500 ELO", Colors.orangeAccent),
              _lobbyBtn(
                  Difficulty.Magnus, "KAMI", "2600 ELO", Colors.redAccent),
              SizedBox(height: 40.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    minimumSize: Size(double.infinity, 60.h)),
                onPressed: () {
                  setState(() => isGameStarted = true);
                  _startTimer();
                },
                child: const Text("START DUEL",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lobbyBtn(Difficulty d, String label, String sub, Color color) {
    bool isSel = _difficulty == d;
    return GestureDetector(
      onTap: () => setState(() => _difficulty = d),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSel ? color.withOpacity(0.2) : Colors.black,
          border: Border.all(
            color: isSel ? color : color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: isSel
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    offset: const Offset(4, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              isSel ? Icons.radio_button_checked : Icons.radio_button_off,
              color: color,
              size: 20.sp,
            ),
            SizedBox(width: 15.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.vt323(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  sub,
                  style: GoogleFonts.vt323(
                    color: Colors.white70,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameSummary() {
    int elo = _calculatePredictedElo();
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Container(
          width: 500.w,
          padding: EdgeInsets.all(40.r),
          decoration: BoxDecoration(
              color: const Color(0xFF1a1c2c),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.cyanAccent, width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 20)
              ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("MATCH ANALYSIS",
                  style: GoogleFonts.vt323(
                      color: Colors.cyanAccent,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              SizedBox(height: 30.h),
              _statRow("COMBAT LEVEL (ELO)", "$elo", Colors.amberAccent),
              const Divider(color: Colors.white10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniStat("CRITICAL", "$userBestMoves", Colors.greenAccent),
                  _miniStat("ERRORS", "$userMistakes", Colors.orangeAccent),
                  _miniStat("FATAL", "$userBlunders", Colors.redAccent),
                ],
              ),
              SizedBox(height: 40.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                    side: const BorderSide(color: Colors.cyanAccent),
                    minimumSize: Size(double.infinity, 50.h)),
                onPressed: () => setState(() {
                  game = chess_pkg.Chess();
                  isGameStarted = false;
                  showSummary = false;
                  moveHistory.clear();
                  capturedWhite.clear();
                  capturedBlack.clear();
                  userBestMoves = 0;
                  userMistakes = 0;
                  userBlunders = 0;
                }),
                child: Text("RE-DEPLOY",
                    style: GoogleFonts.vt323(
                        fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Column(children: [
      Text(label,
          style: GoogleFonts.vt323(color: Colors.white70, fontSize: 12.sp)),
      Text(value,
          style: GoogleFonts.vt323(
              color: color,
              fontSize: 40.sp,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(blurRadius: 10, color: color)])),
    ]);
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(children: [
      Text(label,
          style: GoogleFonts.vt323(color: Colors.white54, fontSize: 9.sp)),
      Text(value,
          style: GoogleFonts.vt323(
              color: color, fontSize: 22.sp, fontWeight: FontWeight.bold)),
    ]);
  }
}
