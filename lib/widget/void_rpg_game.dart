import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// VOID RPG: DARK SOULS — Pseudo-3D First-Person Boss Combat
// ============================================================

class VoidRpgGame extends StatefulWidget {
  final Function(String, {String? english, String? emotion}) onSpeak;

  const VoidRpgGame({super.key, required this.onSpeak});

  @override
  State<VoidRpgGame> createState() => _VoidRpgGameState();
}

enum _BossAttack { none, sweep, slam, thrust, aoe }
enum _BossPhase { one, two }
enum _PlayerAction { idle, lightAttack, heavyAttack, dodging, blocking, healing, staggered }

class _VoidRpgGameState extends State<VoidRpgGame> with TickerProviderStateMixin {
  // --- Game State ---
  bool _showTutorial = true;
  bool _isPlaying = false;
  bool _isDead = false;
  bool _victory = false;

  // --- Player Stats ---
  double _heroHp = 100;
  double _heroMaxHp = 100;
  double _heroStamina = 100;
  double _heroMaxStamina = 100;
  int _estusFlasks = 5;
  int _deathCount = 0;
  _PlayerAction _playerAction = _PlayerAction.idle;
  Timer? _actionTimer;

  // --- Boss Stats ---
  double _bossHp = 500;
  double _bossMaxHp = 500;
  String _bossName = "ABYSSAL WATCHER";
  _BossPhase _bossPhase = _BossPhase.one;
  _BossAttack _currentBossAttack = _BossAttack.none;
  String _bossStatus = "LURKING";
  Timer? _bossTimer;
  Timer? _gameLoopTimer;

  // --- Visual State ---
  double _screenShake = 0;
  double _flashOpacity = 0;
  Color _flashColor = Colors.red;
  double _bossBreathAnim = 0;
  double _fogOffset = 0;
  late AnimationController _ambientController;
  late AnimationController _bossAnimController;

  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _bossAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSpeak("A dark presence awaits...", english: "A dark presence awaits...", emotion: "sorrow");
    });
  }

  void _startGame() {
    setState(() {
      _showTutorial = false;
      _isPlaying = true;
      _isDead = false;
      _victory = false;
      _heroHp = _heroMaxHp;
      _heroStamina = _heroMaxStamina;
      _estusFlasks = 5;
      _bossHp = _bossMaxHp;
      _bossPhase = _BossPhase.one;
      _bossStatus = "LURKING";
      _currentBossAttack = _BossAttack.none;
      _playerAction = _PlayerAction.idle;
      _screenShake = 0;
      _flashOpacity = 0;
    });

    widget.onSpeak("Steel yourself, Master.", english: "Steel yourself, Master.", emotion: "sorrow");

    _gameLoopTimer?.cancel();
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_isPlaying || _isDead || _victory) return;
      _gameLoop();
    });

    _startBossAI();
  }

  void _gameLoop() {
    setState(() {
      // Stamina regen
      if (_playerAction == _PlayerAction.idle) {
        _heroStamina = min(_heroMaxStamina, _heroStamina + 1.2);
      }

      // Screen shake decay
      _screenShake *= 0.85;
      _flashOpacity *= 0.9;

      // Boss breath animation
      _bossBreathAnim += 0.05;
      _fogOffset += 0.3;

      // Boss phase transition
      if (_bossHp <= _bossMaxHp * 0.5 && _bossPhase == _BossPhase.one) {
        _bossPhase = _BossPhase.two;
        _bossName = "ABYSSAL WATCHER (ENRAGED)";
        _flashColor = Colors.deepPurple;
        _flashOpacity = 0.6;
        _screenShake = 15;
        widget.onSpeak("It's getting stronger!", english: "It's getting stronger! Phase two!", emotion: "sorrow");
      }
    });
  }

  void _startBossAI() {
    _bossTimer?.cancel();
    double interval = _bossPhase == _BossPhase.two ? 1500 : 2500;
    _bossTimer = Timer.periodic(Duration(milliseconds: interval.toInt()), (_) {
      if (!_isPlaying || _isDead || _victory) return;
      _bossAttack();
    });
  }

  void _bossAttack() {
    if (_currentBossAttack != _BossAttack.none) return;

    // Pick attack
    List<_BossAttack> attacks = [_BossAttack.sweep, _BossAttack.slam, _BossAttack.thrust];
    if (_bossPhase == _BossPhase.two) attacks.add(_BossAttack.aoe);

    _BossAttack attack = attacks[_rng.nextInt(attacks.length)];
    double windupTime = _bossPhase == _BossPhase.two ? 600 : 900;
    double damage = 0;

    switch (attack) {
      case _BossAttack.sweep:
        _bossStatus = "SWEEPS!";
        damage = 25;
        break;
      case _BossAttack.slam:
        _bossStatus = "SLAMS!";
        damage = 40;
        windupTime += 200;
        break;
      case _BossAttack.thrust:
        _bossStatus = "THRUSTS!";
        damage = 30;
        windupTime -= 200;
        break;
      case _BossAttack.aoe:
        _bossStatus = "VOID ERUPTION!";
        damage = 50;
        windupTime += 400;
        break;
      default:
        break;
    }

    setState(() {
      _currentBossAttack = attack;
    });

    // Animate windup
    _bossAnimController.reset();
    _bossAnimController.duration = Duration(milliseconds: windupTime.toInt());
    _bossAnimController.forward();

    // Register hit after windup
    Future.delayed(Duration(milliseconds: windupTime.toInt()), () {
      if (!mounted || !_isPlaying || _isDead || _victory) return;
      setState(() {
        if (_playerAction == _PlayerAction.dodging) {
          // Dodged!
          _bossStatus = "MISSED!";
        } else if (_playerAction == _PlayerAction.blocking) {
          // Blocked (reduced damage, still costs stamina)
          double blocked = damage * 0.3;
          _heroHp -= blocked;
          _heroStamina -= 25;
          _bossStatus = "BLOCKED!";
          _screenShake = 5;
          if (_heroStamina < 0) {
            _heroStamina = 0;
            _playerAction = _PlayerAction.staggered;
            _bossStatus = "GUARD BREAK!";
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) setState(() => _playerAction = _PlayerAction.idle);
            });
          }
        } else {
          // Hit!
          _heroHp -= damage;
          _flashColor = Colors.red;
          _flashOpacity = 0.4;
          _screenShake = 10;
        }

        _currentBossAttack = _BossAttack.none;

        if (_heroHp <= 0) {
          _die();
        }

        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && _isPlaying) {
            setState(() {
              _bossStatus = _bossPhase == _BossPhase.two ? "ENRAGED" : "LURKING";
            });
          }
        });
      });
    });
  }

  // --- Player Actions ---
  void _lightAttack() {
    if (!_canAct() || _heroStamina < 15) return;
    setState(() {
      _playerAction = _PlayerAction.lightAttack;
      _heroStamina -= 15;
      _bossHp -= 20;
      _flashColor = Colors.white;
      _flashOpacity = 0.1;
      _screenShake = 2;
    });
    if (_bossHp <= 0) { _bossSlain(); return; }
    _endAction(300);
  }

  void _heavyAttack() {
    if (!_canAct() || _heroStamina < 30) return;
    setState(() {
      _playerAction = _PlayerAction.heavyAttack;
      _heroStamina -= 30;
      _bossHp -= 45;
      _flashColor = Colors.orangeAccent;
      _flashOpacity = 0.15;
      _screenShake = 4;
    });
    if (_bossHp <= 0) { _bossSlain(); return; }
    _endAction(600);
  }

  void _dodge() {
    if (!_canAct() || _heroStamina < 20) return;
    setState(() {
      _playerAction = _PlayerAction.dodging;
      _heroStamina -= 20;
    });
    _endAction(500);
  }

  void _block(bool active) {
    if (!_isPlaying || _isDead || _victory) return;
    if (active && _playerAction == _PlayerAction.idle && _heroStamina > 5) {
      setState(() => _playerAction = _PlayerAction.blocking);
    } else if (!active && _playerAction == _PlayerAction.blocking) {
      setState(() => _playerAction = _PlayerAction.idle);
    }
  }

  void _heal() {
    if (!_canAct() || _estusFlasks <= 0) return;
    setState(() {
      _playerAction = _PlayerAction.healing;
      _estusFlasks--;
      _heroHp = min(_heroMaxHp, _heroHp + 40);
      _flashColor = Colors.amberAccent;
      _flashOpacity = 0.2;
    });
    _endAction(800);
  }

  bool _canAct() {
    return _isPlaying && !_isDead && !_victory &&
        (_playerAction == _PlayerAction.idle || _playerAction == _PlayerAction.blocking);
  }

  void _endAction(int ms) {
    _actionTimer?.cancel();
    _actionTimer = Timer(Duration(milliseconds: ms), () {
      if (mounted) setState(() => _playerAction = _PlayerAction.idle);
    });
  }

  void _die() {
    setState(() {
      _isDead = true;
      _isPlaying = false;
      _heroHp = 0;
      _deathCount++;
    });
    _gameLoopTimer?.cancel();
    _bossTimer?.cancel();
    widget.onSpeak("YOU DIED...", english: "You died...", emotion: "sorrow");

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showTutorial = true);
    });
  }

  void _bossSlain() {
    setState(() {
      _victory = true;
      _isPlaying = false;
      _bossHp = 0;
      _bossStatus = "SLAIN";
      _flashColor = Colors.amberAccent;
      _flashOpacity = 0.5;
    });
    _gameLoopTimer?.cancel();
    _bossTimer?.cancel();
    widget.onSpeak("HEIR OF FIRE DESTROYED!", english: "You did it! Victory achieved!", emotion: "joy");

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showTutorial = true);
    });
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    _bossTimer?.cancel();
    _actionTimer?.cancel();
    _ambientController.dispose();
    _bossAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.keyJ || event.logicalKey == LogicalKeyboardKey.keyZ) {
            _lightAttack();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyK || event.logicalKey == LogicalKeyboardKey.keyX) {
            _heavyAttack();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.space) {
            _dodge();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.keyC) {
            _block(true);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyR || event.logicalKey == LogicalKeyboardKey.keyE) {
            _heal();
            return KeyEventResult.handled;
          }
        } else if (event is KeyUpEvent) {
          if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.keyC) {
            _block(false);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return Transform.translate(
            offset: _screenShake > 0.5
                ? Offset((_rng.nextDouble() - 0.5) * _screenShake, (_rng.nextDouble() - 0.5) * _screenShake)
                : Offset.zero,
            child: Stack(
              children: [
                // --- Arena Canvas ---
                AnimatedBuilder(
                  animation: _ambientController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: Size(w, h),
                      painter: _DungeonArenaPainter(
                        ambientValue: _ambientController.value,
                        bossHpFraction: _bossHp / _bossMaxHp,
                        bossPhase: _bossPhase,
                        bossAttack: _currentBossAttack,
                        bossWindup: _bossAnimController.value,
                        bossBreath: _bossBreathAnim,
                        playerAction: _playerAction,
                        fogOffset: _fogOffset,
                        isDead: _isDead,
                        isVictory: _victory,
                      ),
                    );
                  },
                ),

                // --- Flash overlay ---
                if (_flashOpacity > 0.01)
                  IgnorePointer(
                    child: Container(color: _flashColor.withOpacity(_flashOpacity.clamp(0, 0.6))),
                  ),

                // --- Boss HP bar (top) ---
                if ((_isPlaying || _isDead || _victory) && !_showTutorial)
                  Positioned(
                    top: 20, left: w * 0.15, right: w * 0.15,
                    child: Column(
                      children: [
                        Text(_bossName, style: GoogleFonts.cinzel(
                          color: _bossPhase == _BossPhase.two ? Colors.deepPurpleAccent : Colors.white70,
                          fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 3)),
                        const SizedBox(height: 6),
                        Container(
                          height: 8, width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (_bossHp / _bossMaxHp).clamp(0, 1),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: _bossPhase == _BossPhase.two
                                    ? [Colors.deepPurple, Colors.purpleAccent]
                                    : [Colors.red.shade900, Colors.redAccent]),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_bossStatus, style: GoogleFonts.cinzel(
                          color: _currentBossAttack != _BossAttack.none ? Colors.redAccent : Colors.white38,
                          fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      ],
                    ),
                  ),

                // --- Player HUD (bottom) ---
                if ((_isPlaying || _isDead || _victory) && !_showTutorial)
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Stats
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("ASHEN ONE", style: GoogleFonts.cinzel(color: Colors.white, fontSize: 14, letterSpacing: 2)),
                                const SizedBox(height: 8),
                                _statBar("HP", _heroHp, _heroMaxHp, Colors.red.shade800),
                                const SizedBox(height: 6),
                                _statBar("STAMINA", _heroStamina, _heroMaxStamina, Colors.green.shade700),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    ...List.generate(5, (i) => Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(Icons.local_drink,
                                        color: i < _estusFlasks ? Colors.amber.shade700 : Colors.white12, size: 18),
                                    )),
                                    const SizedBox(width: 12),
                                    if (_deathCount > 0)
                                      Text("DEATHS: $_deathCount", style: GoogleFonts.cinzel(color: Colors.red.shade900, fontSize: 11)),
                                  ],
                                ),
                                if (_playerAction == _PlayerAction.dodging)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text("◈ EVADING", style: GoogleFonts.cinzel(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                if (_playerAction == _PlayerAction.blocking)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text("◈ BLOCKING", style: GoogleFonts.cinzel(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ),

                          // Action buttons
                          Expanded(
                            flex: 5,
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              alignment: WrapAlignment.end,
                              children: [
                                _actionBtn("LIGHT\n[J]", _lightAttack, _heroStamina < 15, Colors.white70),
                                _actionBtn("HEAVY\n[K]", _heavyAttack, _heroStamina < 30, Colors.orangeAccent),
                                _actionBtn("DODGE\n[SPACE]", _dodge, _heroStamina < 20, Colors.cyanAccent),
                                _actionBtn("BLOCK\n[SHIFT]", () => _block(true), _heroStamina < 5, Colors.blueAccent),
                                _actionBtn("ESTUS\n[R]", _heal, _estusFlasks <= 0, Colors.amber),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // --- Death overlay ---
                if (_isDead)
                  Container(
                    color: Colors.black.withOpacity(0.88),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("YOU DIED", style: GoogleFonts.cinzel(
                            color: Colors.red.shade900, fontSize: 56, letterSpacing: 14,
                            fontWeight: FontWeight.bold, shadows: [const Shadow(color: Colors.black, blurRadius: 30)])),
                          const SizedBox(height: 20),
                          Text("Deaths: $_deathCount", style: GoogleFonts.cinzel(color: Colors.white24, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),

                // --- Victory overlay ---
                if (_victory)
                  Container(
                    color: Colors.black.withOpacity(0.8),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("HEIR OF FIRE", style: GoogleFonts.cinzel(
                            color: Colors.amberAccent, fontSize: 40, letterSpacing: 8, fontWeight: FontWeight.bold)),
                          Text("DESTROYED", style: GoogleFonts.cinzel(
                            color: Colors.amber.shade800, fontSize: 52, letterSpacing: 12, fontWeight: FontWeight.bold,
                            shadows: [const Shadow(color: Colors.orange, blurRadius: 30)])),
                          const SizedBox(height: 20),
                          Text("Deaths: $_deathCount", style: GoogleFonts.cinzel(color: Colors.white30, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),

                // --- Tutorial ---
                if (_showTutorial)
                  Container(
                    color: Colors.black.withOpacity(0.93),
                    child: Center(
                      child: Container(
                        width: min(w * 0.85, 520),
                        padding: const EdgeInsets.all(36),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          color: const Color(0xFF0E0E12),
                          boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.1), blurRadius: 40)],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("ABYSSAL REMNANT", style: GoogleFonts.cinzel(color: Colors.white, fontSize: 36, letterSpacing: 6, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text("FIRST-PERSON BOSS COMBAT", style: GoogleFonts.cinzel(color: Colors.red.shade900, fontSize: 14, letterSpacing: 6)),
                            const SizedBox(height: 24),
                            _tutorialRow("J / Z", "Light Attack (-15 STM)"),
                            _tutorialRow("K / X", "Heavy Attack (-30 STM)"),
                            _tutorialRow("SPACE", "Dodge Roll (-20 STM)"),
                            _tutorialRow("SHIFT / C", "Block (hold)"),
                            _tutorialRow("R / E", "Estus Flask (heal)"),
                            const SizedBox(height: 16),
                            Text("Watch the boss telegraph · Time your dodges · Manage stamina",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSans(color: Colors.white30, fontSize: 11)),
                            if (_deathCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text("Total Deaths: $_deathCount", style: GoogleFonts.cinzel(color: Colors.red.shade900, fontSize: 12)),
                              ),
                            const SizedBox(height: 28),
                            GestureDetector(
                              onTap: _startGame,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white60),
                                ),
                                child: Text("BEGIN TRIAL", style: GoogleFonts.cinzel(color: Colors.white, letterSpacing: 4, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tutorialRow(String key, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(border: Border.all(color: Colors.white24), color: Colors.white10),
            child: Center(child: Text(key, style: GoogleFonts.sourceCodePro(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Text(desc, style: GoogleFonts.notoSans(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _statBar(String label, double current, double max, Color color) {
    return Row(
      children: [
        SizedBox(width: 56, child: Text(label, style: GoogleFonts.cinzel(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (current / max).clamp(0, 1),
              child: Container(
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(String text, VoidCallback onTap, bool disabled, Color color) {
    bool isActive = !disabled && _canAct();
    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Container(
        width: 80, height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.black87 : Colors.black45,
          border: Border.all(color: isActive ? color.withOpacity(0.6) : Colors.white12),
          boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 6)] : null,
        ),
        child: Text(text, textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(color: isActive ? color : Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ============================================================
// DUNGEON ARENA PAINTER
// ============================================================
class _DungeonArenaPainter extends CustomPainter {
  final double ambientValue;
  final double bossHpFraction;
  final _BossPhase bossPhase;
  final _BossAttack bossAttack;
  final double bossWindup;
  final double bossBreath;
  final _PlayerAction playerAction;
  final double fogOffset;
  final bool isDead;
  final bool isVictory;

  _DungeonArenaPainter({
    required this.ambientValue,
    required this.bossHpFraction,
    required this.bossPhase,
    required this.bossAttack,
    required this.bossWindup,
    required this.bossBreath,
    required this.playerAction,
    required this.fogOffset,
    required this.isDead,
    required this.isVictory,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- Background: dark dungeon walls ---
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF08080C));

    // Distant wall
    double wallY = h * 0.28;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, wallY),
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [const Color(0xFF0A0A10), const Color(0xFF151518)],
      ).createShader(Rect.fromLTWH(0, 0, w, wallY)));

    // Wall bricks texture
    final rng = Random(42);
    for (double y = 0; y < wallY; y += 18) {
      for (double x = 0; x < w; x += 35) {
        double offset = (y ~/ 18) % 2 == 0 ? 0 : 17;
        canvas.drawRect(
          Rect.fromLTWH(x + offset, y, 33, 16),
          Paint()..color = Color.fromRGBO(20 + rng.nextInt(10), 18 + rng.nextInt(8), 22 + rng.nextInt(8), 1)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          Rect.fromLTWH(x + offset, y, 33, 16),
          Paint()..color = Colors.black.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 0.5,
        );
      }
    }

    // --- Floor (perspective grid) ---
    final floorTop = wallY;
    canvas.drawRect(Rect.fromLTWH(0, floorTop, w, h - floorTop),
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [const Color(0xFF12121A), const Color(0xFF1A1A22)],
      ).createShader(Rect.fromLTWH(0, floorTop, w, h - floorTop)));

    // Floor tiles
    final tilePaint = Paint()..color = Colors.white.withOpacity(0.03)..style = PaintingStyle.stroke..strokeWidth = 0.5;
    double centerX = w / 2;
    for (int row = 0; row < 20; row++) {
      double t = row / 20.0;
      double y = floorTop + (h - floorTop) * pow(t, 1.5);
      canvas.drawLine(Offset(0, y), Offset(w, y), tilePaint);
    }
    for (int col = -8; col <= 8; col++) {
      double bottomX = centerX + col * w * 0.1;
      canvas.drawLine(Offset(centerX, floorTop), Offset(bottomX, h), tilePaint);
    }

    // --- Torches ---
    _drawTorch(canvas, w * 0.1, wallY * 0.6, ambientValue);
    _drawTorch(canvas, w * 0.9, wallY * 0.6, 1 - ambientValue);

    // --- Boss ---
    if (bossHpFraction > 0 && !isVictory) {
      _drawBoss(canvas, size);
    }

    // --- Attack telegraph on floor ---
    if (bossAttack != _BossAttack.none) {
      _drawTelegraph(canvas, size);
    }

    // --- Fog ---
    for (int i = 0; i < 5; i++) {
      double fx = (i * w * 0.3 + fogOffset * (2 + i)) % (w + 200) - 100;
      double fy = h * 0.5 + sin(fogOffset * 0.02 + i) * 30;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(fx, fy), width: 250, height: 40),
        Paint()..color = (bossPhase == _BossPhase.two ? Colors.deepPurple : Colors.blueGrey).withOpacity(0.04)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
      );
    }

    // --- Player sword slash visual ---
    if (playerAction == _PlayerAction.lightAttack || playerAction == _PlayerAction.heavyAttack) {
      _drawSlash(canvas, size, playerAction == _PlayerAction.heavyAttack);
    }

    // Dodge visual
    if (playerAction == _PlayerAction.dodging) {
      canvas.drawRect(Rect.fromLTWH(0, h * 0.7, w, h * 0.3),
        Paint()..color = Colors.cyanAccent.withOpacity(0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
    }

    // Block visual
    if (playerAction == _PlayerAction.blocking) {
      canvas.drawCircle(Offset(w / 2, h * 0.75), 80,
        Paint()..color = Colors.blueAccent.withOpacity(0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));
      canvas.drawCircle(Offset(w / 2, h * 0.75), 80,
        Paint()..color = Colors.blueAccent.withOpacity(0.15)..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  void _drawTorch(Canvas canvas, double x, double y, double flicker) {
    // Post
    canvas.drawRect(Rect.fromCenter(center: Offset(x, y + 20), width: 4, height: 40),
      Paint()..color = const Color(0xFF3A2A1A));
    // Flame
    double fh = 12 + flicker * 8;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y - fh / 2), width: 10, height: fh),
      Paint()..color = Colors.orange.withOpacity(0.8)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y - fh / 2 - 3), width: 6, height: fh * 0.6),
      Paint()..color = Colors.yellow.withOpacity(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Light glow
    canvas.drawCircle(Offset(x, y), 60,
      Paint()..color = Colors.orange.withOpacity(0.03 + flicker * 0.02)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30));
  }

  void _drawBoss(Canvas canvas, Size size) {
    final cx = size.width / 2;
    double baseY = size.height * 0.28;
    double bossScale = 1.0 + (1.0 - bossHpFraction) * 0.1;
    if (bossPhase == _BossPhase.two) bossScale += 0.1;

    double breathOffset = sin(bossBreath) * 3;

    // --- Boss body (dark knight silhouette) ---
    double bodyW = 100 * bossScale;
    double bodyH = 160 * bossScale;
    double bodyY = baseY + breathOffset;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, baseY + bodyH * 0.5 + 10), width: bodyW * 1.4, height: 20),
      Paint()..color = Colors.black.withOpacity(0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Main body
    final bodyPath = Path()
      ..moveTo(cx - bodyW * 0.4, bodyY + bodyH * 0.5)
      ..lineTo(cx - bodyW * 0.3, bodyY - bodyH * 0.2)
      ..quadraticBezierTo(cx - bodyW * 0.15, bodyY - bodyH * 0.5, cx, bodyY - bodyH * 0.45)
      ..quadraticBezierTo(cx + bodyW * 0.15, bodyY - bodyH * 0.5, cx + bodyW * 0.3, bodyY - bodyH * 0.2)
      ..lineTo(cx + bodyW * 0.4, bodyY + bodyH * 0.5)
      ..close();

    Color bodyColor = bossPhase == _BossPhase.two
        ? Color.lerp(const Color(0xFF1A0A2A), Colors.deepPurple.shade900, ambientValue * 0.3)!
        : const Color(0xFF1A1A20);

    canvas.drawPath(bodyPath, Paint()..color = bodyColor);

    // Horns
    double hornScale = 1 + (bossPhase == _BossPhase.two ? 0.3 : 0);
    for (int side = -1; side <= 1; side += 2) {
      canvas.drawLine(
        Offset(cx + side * bodyW * 0.15, bodyY - bodyH * 0.42),
        Offset(cx + side * bodyW * 0.35 * hornScale, bodyY - bodyH * 0.7),
        Paint()..color = bossPhase == _BossPhase.two ? Colors.deepPurpleAccent : Colors.grey.shade800
          ..strokeWidth = 3..strokeCap = StrokeCap.round,
      );
    }

    // Eyes
    Color eyeColor = bossPhase == _BossPhase.two ? Colors.purpleAccent : Colors.red.shade900;
    if (bossAttack != _BossAttack.none) eyeColor = Colors.redAccent;

    double eyeSize = 4 * bossScale;
    for (int side = -1; side <= 1; side += 2) {
      canvas.drawCircle(
        Offset(cx + side * bodyW * 0.1, bodyY - bodyH * 0.3),
        eyeSize,
        Paint()..color = eyeColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Weapon (sword) — shifts with attack
    if (bossAttack != _BossAttack.none) {
      _drawBossWeapon(canvas, cx, bodyY, bodyW, bodyH, bossScale);
    }

    // Phase 2 aura
    if (bossPhase == _BossPhase.two) {
      canvas.drawCircle(
        Offset(cx, bodyY), bodyW * 0.8,
        Paint()..color = Colors.deepPurple.withOpacity(0.06 + ambientValue * 0.03)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
      );
    }
  }

  void _drawBossWeapon(Canvas canvas, double cx, double bodyY, double bodyW, double bodyH, double scale) {
    double weaponAngle = 0;
    double weaponLen = bodyH * 0.8;
    double ox = cx + bodyW * 0.4;
    double oy = bodyY - bodyH * 0.1;

    switch (bossAttack) {
      case _BossAttack.sweep:
        weaponAngle = -pi / 4 + bossWindup * pi / 2;
        break;
      case _BossAttack.slam:
        weaponAngle = -pi / 2 + bossWindup * pi / 2;
        ox = cx;
        break;
      case _BossAttack.thrust:
        weaponAngle = pi / 6;
        weaponLen *= (0.6 + bossWindup * 0.6);
        break;
      case _BossAttack.aoe:
        weaponAngle = -pi / 2;
        ox = cx;
        break;
      default:
        break;
    }

    double endX = ox + cos(weaponAngle) * weaponLen;
    double endY = oy + sin(weaponAngle) * weaponLen;

    canvas.drawLine(Offset(ox, oy), Offset(endX, endY),
      Paint()..color = bossPhase == _BossPhase.two ? Colors.purpleAccent : Colors.grey.shade600
        ..strokeWidth = 3..strokeCap = StrokeCap.round);

    // Glow at tip
    canvas.drawCircle(Offset(endX, endY), 6,
      Paint()..color = Colors.redAccent.withOpacity(0.4 * bossWindup)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  }

  void _drawTelegraph(Canvas canvas, Size size) {
    double cx = size.width / 2;
    double cy = size.height * 0.65;
    Color telegraphColor = Colors.red.withOpacity(0.1 + bossWindup * 0.15);

    switch (bossAttack) {
      case _BossAttack.sweep:
        // Horizontal arc
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, cy), width: size.width * 0.6, height: 60),
          0, pi, true,
          Paint()..color = telegraphColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        break;
      case _BossAttack.slam:
        // Center circle
        canvas.drawCircle(Offset(cx, cy), 50 + bossWindup * 30,
          Paint()..color = telegraphColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        break;
      case _BossAttack.thrust:
        // Forward line
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy), width: 40, height: 100),
          Paint()..color = telegraphColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        break;
      case _BossAttack.aoe:
        // Full floor
        canvas.drawCircle(Offset(cx, cy), 100 + bossWindup * 80,
          Paint()..color = Colors.deepPurple.withOpacity(0.08 + bossWindup * 0.1)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));
        break;
      default:
        break;
    }
  }

  void _drawSlash(Canvas canvas, Size size, bool isHeavy) {
    final cx = size.width / 2;
    final cy = size.height * 0.5;

    final slashPaint = Paint()
      ..color = (isHeavy ? Colors.orangeAccent : Colors.white).withOpacity(0.3)
      ..strokeWidth = isHeavy ? 4 : 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    double arc = isHeavy ? pi * 0.8 : pi * 0.5;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy), width: 200, height: 120),
      -pi / 2 - arc / 2, arc, false, slashPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DungeonArenaPainter old) => true;
}
