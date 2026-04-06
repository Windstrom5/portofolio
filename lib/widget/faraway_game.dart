import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FarawayGame extends StatefulWidget {
  const FarawayGame({super.key});

  @override
  State<FarawayGame> createState() => _FarawayGameState();
}

class FarawayCard {
  final int id;
  final String biome;
  final Color color;
  final String condition;
  final String icon; // The icon this card PROVIDES
  final String? req; // Prerequisites (e.g., '2 BLUE')
  final int Function(List<String> icons) scoreCalc;

  FarawayCard({
    required this.id,
    required this.biome,
    required this.color,
    required this.condition,
    required this.icon,
    this.req,
    required this.scoreCalc,
  });
}

class _FarawayGameState extends State<FarawayGame> {
  final List<FarawayCard> _deck = [
    FarawayCard(
        id: 1,
        biome: 'Forest',
        color: Colors.green,
        icon: '🌲',
        condition: '2 pts per 🌲',
        scoreCalc: (icons) => icons.where((v) => v == '🌲').length * 2),
    FarawayCard(
        id: 2,
        biome: 'Desert',
        color: Colors.orange,
        icon: '☀️',
        condition: '3 pts per ☀️',
        scoreCalc: (icons) => icons.where((v) => v == '☀️').length * 3,
        req: '☀️'),
    FarawayCard(
        id: 3,
        biome: 'Ocean',
        color: Colors.blue,
        icon: 'Waves',
        condition: '10 pts',
        scoreCalc: (icons) => 10,
        req: 'WavesWaves'),
    FarawayCard(
        id: 4,
        biome: 'Mountain',
        color: Colors.grey,
        icon: '⛰️',
        condition: '4 pts per 💎',
        scoreCalc: (icons) => icons.where((v) => v == '💎').length * 4),
    FarawayCard(
        id: 5,
        biome: 'Forest',
        color: Colors.green,
        icon: '☀️',
        condition: '6 pts',
        scoreCalc: (icons) => 6,
        req: '🌲'),
    FarawayCard(
        id: 6,
        biome: 'Desert',
        color: Colors.orange,
        icon: '💎',
        condition: '2 pts per 🏜️',
        scoreCalc: (icons) => icons.where((v) => v == '🏜️').length * 2),
    FarawayCard(
        id: 7,
        biome: 'Ocean',
        color: Colors.blue,
        icon: 'Waves',
        condition: '3 pts per Waves',
        scoreCalc: (icons) => icons.where((v) => v == 'Waves').length * 3),
    FarawayCard(
        id: 8,
        biome: 'Mountain',
        color: Colors.grey,
        icon: '💎',
        condition: '8 pts',
        scoreCalc: (icons) => 8,
        req: '⛰️⛰️'),
    FarawayCard(
        id: 9,
        biome: 'Field',
        color: Colors.yellow,
        icon: '🌾',
        condition: '5 pts per 🌾',
        scoreCalc: (icons) => icons.where((v) => v == '🌾').length * 5,
        req: '💎'),
    FarawayCard(
        id: 10,
        biome: 'Field',
        color: Colors.yellow,
        icon: '🌾',
        condition: '15 pts',
        scoreCalc: (icons) => 15,
        req: '🌾🌾🌾'),
    FarawayCard(
        id: 11,
        biome: 'Mystic',
        color: Colors.purple,
        icon: '✨',
        condition: '20 pts',
        scoreCalc: (icons) => 20,
        req: '✨✨'),
  ];

  List<FarawayCard> _playerHand = [];
  List<FarawayCard?> _playerTableau = List.filled(8, null);
  List<FarawayCard?> _sakuraTableau = List.filled(8, null);
  List<FarawayCard> _sakuraHand = [];

  int _currentSlot = 0;
  bool _gameOver = false;
  int _playerScore = 0;
  int _sakuraScore = 0;
  List<bool> _playerScored = List.filled(8, false);
  List<bool> _sakuraScored = List.filled(8, false);
  bool _isSakuraThinking = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      _deck.shuffle();
      _playerHand = _deck.take(3).toList();
      _sakuraHand = _deck.skip(3).take(3).toList();
      _playerTableau = List.filled(8, null);
      _sakuraTableau = List.filled(8, null);
      _currentSlot = 0;
      _gameOver = false;
      _playerScore = 0;
      _sakuraScore = 0;
      _playerScored = List.filled(8, false);
      _sakuraScored = List.filled(8, false);
      _isSakuraThinking = false;
    });
  }

  void _playCard(FarawayCard card) {
    if (_currentSlot >= 8 || _gameOver || _isSakuraThinking) return;

    setState(() {
      _playerTableau[_currentSlot] = card;
      _playerHand.remove(card);

      // Draw new cards from deck for next turn
      if (_deck.length > 10) {
        _playerHand.add(_deck[Random().nextInt(_deck.length)]);
      }

      _isSakuraThinking = true;
    });

    // Sakura plays after a short delay
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _sakuraTurn();
    });
  }

  void _sakuraTurn() {
    setState(() {
      // Simple AI: Sakura picks a card from her hand randomly
      final card = _sakuraHand[Random().nextInt(_sakuraHand.length)];
      _sakuraTableau[_currentSlot] = card;
      _sakuraHand.remove(card);

      if (_deck.length > 10) {
        _sakuraHand.add(_deck[Random().nextInt(_deck.length)]);
      }

      _currentSlot++;
      _isSakuraThinking = false;

      if (_currentSlot == 8) {
        _gameOver = true;
        _calculateScores();
      }
    });
  }

  Future<void> _calculateScores() async {
    int pTotal = 0;
    int sTotal = 0;
    List<String> pIcons = [];
    List<String> sIcons = [];

    for (int i = 7; i >= 0; i--) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      final pCard = _playerTableau[i]!;
      final sCard = _sakuraTableau[i]!;
      pIcons.add(pCard.icon);
      sIcons.add(sCard.icon);

      // Scoring logic (Simplified)
      bool pReqMet = _checkReq(pCard, pIcons);
      bool sReqMet = _checkReq(sCard, sIcons);

      setState(() {
        if (pReqMet) {
          pTotal += pCard.scoreCalc(pIcons);
          _playerScored[i] = true;
        }
        if (sReqMet) {
          sTotal += sCard.scoreCalc(sIcons);
          _sakuraScored[i] = true;
        }
        _playerScore = pTotal;
        _sakuraScore = sTotal;
      });
    }
  }

  bool _checkReq(FarawayCard card, List<String> icons) {
    if (card.req == null) return true;
    final r = card.req!;
    if (r == '☀️' && icons.contains('☀️')) return true;
    if (r == 'WavesWaves' && icons.where((v) => v == 'Waves').length >= 2)
      return true;
    if (r == '🌲' && icons.contains('🌲')) return true;
    if (r == '⛰️⛰️' && icons.where((v) => v == '⛰️').length >= 2) return true;
    if (r == '💎' && icons.contains('💎')) return true;
    if (r == '🌾🌾🌾' && icons.where((v) => v == '🌾').length >= 3) return true;
    if (r == '✨✨' && icons.where((v) => v == '✨').length >= 2) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _scoreBoard("VISITOR", _playerScore, Colors.cyanAccent),
              Text("VS",
                  style: GoogleFonts.pressStart2p(
                      color: Colors.white, fontSize: 18.sp)),
              _scoreBoard("SAKURA", _sakuraScore, Colors.pinkAccent),
            ],
          ),

          SizedBox(height: 15.h),

          // Sakura's Area
          Text("SAKURA'S TABLEAU",
              style: GoogleFonts.orbitron(
                  color: Colors.pinkAccent.withValues(alpha: 0.7), fontSize: 12.sp)),
          SizedBox(height: 5.h),
          _buildTableau(_sakuraTableau, _sakuraScored, isOpponent: true),

          if (_isSakuraThinking)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text("Sakura is thinking... ♡",
                  style: GoogleFonts.vt323(
                      color: Colors.pinkAccent, fontSize: 14.sp)),
            )
          else
            SizedBox(height: 25.h),

          // Player's Area
          Text("YOUR TABLEAU",
              style: GoogleFonts.orbitron(
                  color: Colors.cyanAccent.withValues(alpha: 0.7), fontSize: 12.sp)),
          SizedBox(height: 5.h),
          _buildTableau(_playerTableau, _playerScored),

          const Spacer(),

          // Hand / Game Over UI
          if (!_gameOver)
            Column(
              children: [
                Text("YOUR HAND",
                    style: GoogleFonts.vt323(
                        color: Colors.white54, fontSize: 14.sp)),
                SizedBox(height: 8.h),
                _buildHand(),
              ],
            )
          else
            _buildGameOver(),
        ],
      ),
    );
  }

  Widget _scoreBoard(String name, int score, Color color) {
    return Column(
      children: [
        Text(name,
            style: GoogleFonts.orbitron(
                color: color, fontSize: 14.sp, fontWeight: FontWeight.bold)),
        Text("$score",
            style:
                GoogleFonts.pressStart2p(color: Colors.white, fontSize: 22.sp)),
      ],
    );
  }

  Widget _buildTableau(List<FarawayCard?> tableau, List<bool> scored,
      {bool isOpponent = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(8, (index) {
        final card = tableau[index];
        bool isNext = index == _currentSlot && !isOpponent;
        return Container(
          width: 45.w,
          height: 70.h,
          margin: EdgeInsets.all(2.r),
          decoration: BoxDecoration(
            color: card == null
                ? (isNext
                    ? Colors.cyanAccent.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.05))
                : card.color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(
              color: _gameOver && scored[index]
                  ? Colors.yellowAccent
                  : (isNext ? Colors.cyanAccent : Colors.white10),
              width: _gameOver && scored[index] ? 2 : 1,
            ),
          ),
          child: card == null
              ? null
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(card.icon, style: TextStyle(fontSize: 16.sp)),
                    if (!isOpponent)
                      Text(card.condition,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 6.sp,
                              fontWeight: FontWeight.bold)),
                  ],
                ),
        );
      }),
    );
  }

  Widget _buildHand() {
    return Wrap(
      spacing: 10,
      children: _playerHand
          .map((card) => GestureDetector(
                onTap: () => _playCard(card),
                child: Container(
                  width: 70.w,
                  height: 100.h,
                  decoration: BoxDecoration(
                    color: card.color,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: Colors.white24),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black45,
                          blurRadius: 4,
                          offset: Offset(2, 2))
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(card.icon, style: TextStyle(fontSize: 22.sp)),
                      Padding(
                        padding: EdgeInsets.all(4.r),
                        child: Text(card.condition,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold)),
                      ),
                      if (card.req != null)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          color: Colors.black26,
                          child: Text("REQ: ${card.req}",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 8.sp)),
                        ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildGameOver() {
    bool win = _playerScore >= _sakuraScore;
    return Column(
      children: [
        Text(win ? "YOU WIN! ♡" : "SAKURA WINS! ♪",
            style: GoogleFonts.pressStart2p(
                color: win ? Colors.cyanAccent : Colors.pinkAccent,
                fontSize: 18.sp)),
        SizedBox(height: 10.h),
        Text(
            win
                ? "Visitor, you're amazing! I'll win next time! ♡"
                : "Fufu~ Better luck next time, Visitor! ♪",
            style: GoogleFonts.vt323(color: Colors.white70, fontSize: 16.sp)),
        SizedBox(height: 20.h),
        ElevatedButton(
          onPressed: _startNewGame,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent.shade700,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h)),
          child: Text("REMATCH",
              style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
        )
      ],
    );
  }
}
