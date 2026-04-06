import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

// ============================================================
// NEON RACER: NFS — Pseudo-3D Racing Game
// ============================================================

class NeonRacerGame extends StatefulWidget {
  final Function(String, {String? english, String? emotion}) onSpeak;

  const NeonRacerGame({super.key, required this.onSpeak});

  @override
  State<NeonRacerGame> createState() => _NeonRacerGameState();
}

// --- Road Segment ---
class _RoadSegment {
  double curve; // -1 (hard left) to 1 (hard right)
  double hill;  // -1 (downhill) to 1 (uphill)
  int zoneType; // 0=city, 1=highway, 2=mountain
  _RoadSegment({this.curve = 0, this.hill = 0, this.zoneType = 0});
}

// --- Traffic Car ---
class _TrafficCar {
  double segmentIndex; // position along road
  int lane; // 0=left, 1=center, 2=right
  int type; // 0=sedan, 1=truck, 2=sports, 3=police
  double speed;
  Color color;
  _TrafficCar({
    required this.segmentIndex,
    required this.lane,
    required this.type,
    required this.speed,
    required this.color,
  });
}

// --- Roadside Object ---
class _RoadsideObject {
  double segmentIndex;
  double side; // -1 left, 1 right
  int type; // 0=tree, 1=building, 2=lamppost, 3=billboard
  _RoadsideObject({required this.segmentIndex, required this.side, required this.type});
}

class _NeonRacerGameState extends State<NeonRacerGame> with TickerProviderStateMixin {
  // --- Game State ---
  bool _showTutorial = true;
  bool _isPlaying = false;
  bool _crashed = false;

  // --- Player ---
  int _playerLane = 1; // 0, 1, 2
  double _targetLaneX = 0.0;
  double _playerX = 0.0; // smooth interpolated position
  double _speed = 0.0;
  double _maxSpeed = 320.0;
  int _gear = 1;
  double _nitroFuel = 100.0;
  bool _nitroActive = false;
  int _score = 0;
  int _combo = 0;
  int _bestCombo = 0;
  double _distance = 0.0;
  double _carTilt = 0.0;

  // --- Road ---
  final List<_RoadSegment> _road = [];
  double _roadPosition = 0.0; // current scroll along road
  int _currentZone = 0;

  // --- Traffic ---
  final List<_TrafficCar> _traffic = [];

  // --- Environment ---
  final List<_RoadsideObject> _roadside = [];
  double _skyOffset = 0.0;

  // --- Timers ---
  Timer? _gameTimer;
  final Random _rng = Random();

  // --- Animation ---
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _generateRoad();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSpeak("Engine primed. Hit the road, Master!", english: "Engine primed. Hit the road, Master!", emotion: "joy");
    });
  }

  void _generateRoad() {
    _road.clear();
    _traffic.clear();
    _roadside.clear();
    int zone = 0;
    for (int i = 0; i < 2000; i++) {
      // Every ~200 segments change zone
      if (i % 200 == 0 && i > 0) zone = (zone + 1) % 3;
      double curve = 0;
      double hill = 0;
      // Create varied curves
      if (i % 80 < 30) {
        curve = sin(i * 0.05) * (0.3 + _rng.nextDouble() * 0.4);
      }
      if (i % 120 < 40) {
        hill = sin(i * 0.03) * 0.3;
      }
      _road.add(_RoadSegment(curve: curve, hill: hill, zoneType: zone));

      // Roadside objects
      if (i % 8 == 0) {
        int objType = zone == 0 ? (_rng.nextBool() ? 1 : 3) : (zone == 2 ? 0 : 2);
        _roadside.add(_RoadsideObject(
          segmentIndex: i.toDouble(),
          side: _rng.nextBool() ? -1 : 1,
          type: objType,
        ));
      }
    }

    // Spawn initial traffic
    for (int i = 0; i < 15; i++) {
      _spawnTraffic(50.0 + i * 80.0 + _rng.nextDouble() * 40);
    }
  }

  void _spawnTraffic(double segIdx) {
    final colors = [Colors.red, Colors.blue, Colors.yellow, Colors.white, Colors.purple, Colors.orange];
    _traffic.add(_TrafficCar(
      segmentIndex: segIdx,
      lane: _rng.nextInt(3),
      type: _rng.nextInt(4),
      speed: 80 + _rng.nextDouble() * 120,
      color: colors[_rng.nextInt(colors.length)],
    ));
  }

  void _startGame() {
    setState(() {
      _showTutorial = false;
      _isPlaying = true;
      _crashed = false;
      _score = 0;
      _combo = 0;
      _bestCombo = 0;
      _speed = 0;
      _gear = 1;
      _playerLane = 1;
      _playerX = 0;
      _targetLaneX = 0;
      _nitroFuel = 100;
      _nitroActive = false;
      _distance = 0;
      _roadPosition = 0;
      _generateRoad();
    });

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_isPlaying || _crashed) return;
      _update();
    });

    widget.onSpeak("3... 2... 1... GO!", english: "3... 2... 1... GO!", emotion: "fun");
  }

  void _update() {
    setState(() {
      // --- Acceleration & Gear ---
      double accelFactor = _nitroActive ? 2.5 : 1.0;
      double targetMax = _nitroActive ? 450.0 : _maxSpeed;

      if (_speed < targetMax) {
        _speed += (0.8 * accelFactor) * (1.0 - _speed / targetMax);
      } else {
        _speed -= 0.3;
      }
      _speed = _speed.clamp(0, 500);

      // Auto gear
      if (_speed < 60) _gear = 1;
      else if (_speed < 120) _gear = 2;
      else if (_speed < 180) _gear = 3;
      else if (_speed < 250) _gear = 4;
      else if (_speed < 350) _gear = 5;
      else _gear = 6;

      // Nitro
      if (_nitroActive) {
        _nitroFuel = max(0, _nitroFuel - 0.8);
        if (_nitroFuel <= 0) _nitroActive = false;
      } else {
        _nitroFuel = min(100, _nitroFuel + 0.05);
      }

      // --- Move along road ---
      double moveAmount = _speed * 0.005;
      _roadPosition += moveAmount;
      _distance += moveAmount;
      _score = (_distance * 10).toInt();

      // --- Player lane interpolation ---
      _targetLaneX = (_playerLane - 1) * 0.35;
      _playerX += (_targetLaneX - _playerX) * 0.15;

      // Car tilt based on lane change
      _carTilt += (_targetLaneX - _playerX) * 2.0;
      _carTilt *= 0.85;

      // Sky parallax
      int segIdx = _roadPosition.toInt() % _road.length;
      _skyOffset += _road[segIdx].curve * _speed * 0.0001;
      _currentZone = _road[segIdx].zoneType;

      // --- Traffic movement ---
      for (var car in _traffic) {
        car.segmentIndex += car.speed * 0.003;
      }

      // Respawn traffic ahead
      double playerSeg = _roadPosition;
      _traffic.removeWhere((c) => c.segmentIndex < playerSeg - 20);
      while (_traffic.length < 15) {
        double farthest = _traffic.isEmpty ? playerSeg : _traffic.map((c) => c.segmentIndex).reduce(max);
        _spawnTraffic(farthest + 40 + _rng.nextDouble() * 60);
      }

      // --- Collision Detection ---
      for (var car in _traffic) {
        double relDist = car.segmentIndex - playerSeg;
        if (relDist > 0 && relDist < 3) {
          double carX = (car.lane - 1) * 0.35;
          if ((carX - _playerX).abs() < 0.18) {
            _gameOver();
            return;
          }
          // Near-miss combo
          if (relDist < 5 && (carX - _playerX).abs() < 0.28 && (carX - _playerX).abs() >= 0.18) {
            _combo++;
            if (_combo > _bestCombo) _bestCombo = _combo;
            _score += _combo * 50;
          }
        }
      }
    });
  }

  void _switchLane(int direction) {
    if (!_isPlaying || _crashed) return;
    setState(() {
      _playerLane = (_playerLane + direction).clamp(0, 2);
    });
  }

  void _toggleNitro(bool active) {
    if (!_isPlaying || _crashed) return;
    if (active && _nitroFuel > 10) {
      setState(() => _nitroActive = true);
    } else {
      setState(() => _nitroActive = false);
    }
  }

  void _gameOver() {
    _crashed = true;
    _isPlaying = false;
    _gameTimer?.cancel();
    widget.onSpeak("WRECKED! Score: $_score", english: "Wrecked! Final score: $_score", emotion: "sorrow");
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showTutorial = true);
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.keyA) {
            _switchLane(-1);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.keyD) {
            _switchLane(1);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.shiftLeft) {
            _toggleNitro(true);
            return KeyEventResult.handled;
          }
        } else if (event is KeyUpEvent) {
          if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.shiftLeft) {
            _toggleNitro(false);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return GestureDetector(
            onTapDown: (details) {
              if (details.localPosition.dx < w / 3) {
                _switchLane(-1);
              } else if (details.localPosition.dx > w * 2 / 3) {
                _switchLane(1);
              } else {
                _toggleNitro(true);
                Future.delayed(const Duration(milliseconds: 500), () => _toggleNitro(false));
              }
            },
            child: Stack(
              children: [
                // --- Game Canvas ---
                CustomPaint(
                  size: Size(w, h),
                  painter: _NfsRoadPainter(
                    road: _road,
                    roadPosition: _roadPosition,
                    playerX: _playerX,
                    playerTilt: _carTilt,
                    speed: _speed,
                    nitroActive: _nitroActive,
                    traffic: _traffic,
                    roadside: _roadside,
                    skyOffset: _skyOffset,
                    currentZone: _currentZone,
                    glowValue: _glowController.value,
                    crashed: _crashed,
                  ),
                ),

                // --- HUD ---
                if (_isPlaying || _crashed) ...[
                  // Score & Combo (top-left)
                  Positioned(
                    top: 20, left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("SCORE", style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 12)),
                        Text(_score.toString().padLeft(8, '0'),
                          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        if (_combo > 1)
                          Text("COMBO x$_combo", style: GoogleFonts.orbitron(color: Colors.orangeAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  // Nitro (top-right)
                  Positioned(
                    top: 20, right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("N₂O", style: GoogleFonts.orbitron(
                          color: _nitroActive ? Colors.redAccent : Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          width: 160, height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _nitroFuel / 100.0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: _nitroActive
                                    ? [Colors.red, Colors.orangeAccent]
                                    : [Colors.cyanAccent, Colors.blueAccent]),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [BoxShadow(color: _nitroActive ? Colors.red.withOpacity(0.5) : Colors.cyan.withOpacity(0.3), blurRadius: 8)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Speedometer (bottom-left)
                  Positioned(
                    bottom: 30, left: 30,
                    child: _buildTachometer(),
                  ),
                  // Gear (bottom-center)
                  Positioned(
                    bottom: 30,
                    left: w / 2 - 25,
                    child: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
                        color: Colors.black54,
                      ),
                      child: Center(
                        child: Text("$_gear", style: GoogleFonts.orbitron(
                          color: _nitroActive ? Colors.redAccent : Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ],

                // --- Crash Overlay ---
                if (_crashed)
                  Container(
                    color: Colors.red.withOpacity(0.4),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("WRECKED", style: GoogleFonts.orbitron(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold,
                            shadows: [const Shadow(color: Colors.red, blurRadius: 20)])),
                          const SizedBox(height: 10),
                          Text("SCORE: $_score", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 24)),
                          Text("BEST COMBO: x$_bestCombo", style: GoogleFonts.orbitron(color: Colors.orangeAccent, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),

                // --- Tutorial ---
                if (_showTutorial)
                  Container(
                    color: Colors.black.withOpacity(0.92),
                    child: Center(
                      child: Container(
                        width: min(w * 0.8, 500),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A15),
                          border: Border.all(color: Colors.cyanAccent, width: 2),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.15), blurRadius: 30)],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (rect) => const LinearGradient(
                                colors: [Colors.cyanAccent, Colors.purpleAccent],
                              ).createShader(rect),
                              child: Text("SHIFT: NEON PULSE", style: GoogleFonts.orbitron(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 4)),
                            ),
                            const SizedBox(height: 6),
                            Text("HIGH-SPEED NEON OVERDRIVE", style: GoogleFonts.orbitron(color: Colors.cyanAccent.withOpacity(0.5), fontSize: 14, letterSpacing: 8)),
                            const SizedBox(height: 30),
                            _controlRow("A / ← ", "Switch Left Lane"),
                            _controlRow("D / → ", "Switch Right Lane"),
                            _controlRow("SPACE", "Nitro Boost"),
                            _controlRow("MOBILE", "Tap Left/Right to steer, Center for nitro"),
                            const SizedBox(height: 10),
                            Text("Weave through traffic · Build combos on near-misses", textAlign: TextAlign.center,
                              style: GoogleFonts.notoSans(color: Colors.white38, fontSize: 12)),
                            const SizedBox(height: 30),
                            GestureDetector(
                              onTap: _startGame,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.4), blurRadius: 15)],
                                ),
                                child: Text("IGNITION", style: GoogleFonts.orbitron(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 3)),
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

  Widget _controlRow(String key, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            ),
            child: Text(key, style: GoogleFonts.sourceCodePro(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Text(desc, style: GoogleFonts.notoSans(color: Colors.white60, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTachometer() {
    return SizedBox(
      width: 130, height: 130,
      child: CustomPaint(
        painter: _TachometerPainter(
          speed: _speed,
          maxSpeed: 500,
          nitroActive: _nitroActive,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 15),
              Text("${_speed.toInt()}", style: GoogleFonts.orbitron(
                color: _nitroActive ? Colors.redAccent : Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              Text("KM/H", style: GoogleFonts.orbitron(color: Colors.white38, fontSize: 9)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TACHOMETER PAINTER
// ============================================================
class _TachometerPainter extends CustomPainter {
  final double speed;
  final double maxSpeed;
  final bool nitroActive;

  _TachometerPainter({required this.speed, required this.maxSpeed, required this.nitroActive});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.75, pi * 1.5, false, bgPaint,
    );

    // Speed arc
    final speedFraction = (speed / maxSpeed).clamp(0, 1);
    final speedPaint = Paint()
      ..shader = SweepGradient(
        startAngle: pi * 0.75,
        endAngle: pi * 2.25,
        colors: nitroActive
            ? [Colors.orange, Colors.redAccent, Colors.red]
            : [Colors.cyanAccent, Colors.blueAccent, Colors.purpleAccent],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.75, pi * 1.5 * speedFraction, false, speedPaint,
    );

    // Glow
    if (nitroActive) {
      final glowPaint = Paint()
        ..color = Colors.redAccent.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        pi * 0.75, pi * 1.5 * speedFraction, false, glowPaint,
      );
    }

    // Tick marks
    for (int i = 0; i <= 10; i++) {
      double angle = pi * 0.75 + (pi * 1.5) * (i / 10);
      double innerR = radius - 12;
      double outerR = radius - 4;
      canvas.drawLine(
        Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle)),
        Offset(center.dx + outerR * cos(angle), center.dy + outerR * sin(angle)),
        Paint()..color = Colors.white24..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TachometerPainter old) => true;
}

// ============================================================
// PSEUDO-3D ROAD + SCENE PAINTER
// ============================================================
class _NfsRoadPainter extends CustomPainter {
  final List<_RoadSegment> road;
  final double roadPosition;
  final double playerX;
  final double playerTilt;
  final double speed;
  final bool nitroActive;
  final List<_TrafficCar> traffic;
  final List<_RoadsideObject> roadside;
  final double skyOffset;
  final int currentZone;
  final double glowValue;
  final bool crashed;

  _NfsRoadPainter({
    required this.road,
    required this.roadPosition,
    required this.playerX,
    required this.playerTilt,
    required this.speed,
    required this.nitroActive,
    required this.traffic,
    required this.roadside,
    required this.skyOffset,
    required this.currentZone,
    required this.glowValue,
    required this.crashed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- Sky ---
    _drawSky(canvas, size);

    // --- Road segments (pseudo-3D projection) ---
    final int drawDist = 150;
    final double camHeight = 1200;
    final double camDepth = 0.8;
    final int startSeg = roadPosition.toInt();
    double x = 0.0;
    double dx = 0.0;
    final double horizonY = h * 0.38;

    // Collect projected points for road strip rendering
    List<_ProjectedSegment> projected = [];

    for (int n = 0; n < drawDist; n++) {
      int idx = (startSeg + n) % road.length;
      final seg = road[idx];
      dx += seg.curve * 0.015;
      x += dx;

      double perspective = camDepth / (n + 1.0);
      double projY = horizonY + (h - horizonY) * perspective * camHeight / (camHeight);
      double projW = w * perspective * 1.5;
      double projX = w / 2 + (x - playerX * 2.5) * projW - projW / 2;

      // Hill offset
      projY -= seg.hill * 80 * perspective;

      projected.add(_ProjectedSegment(
        x: projX,
        y: projY,
        w: projW,
        scale: perspective,
        segIndex: idx,
        depth: n,
      ));
    }

    // Draw from far to near
    for (int i = projected.length - 1; i > 0; i--) {
      final curr = projected[i];
      final prev = projected[i - 1];

      // Grass
      bool stripe = (curr.segIndex ~/ 4) % 2 == 0;
      Color grassColor;
      if (currentZone == 0) {
        grassColor = stripe ? const Color(0xFF1A2A10) : const Color(0xFF152208);
      } else if (currentZone == 2) {
        grassColor = stripe ? const Color(0xFF2A2520) : const Color(0xFF221E18);
      } else {
        grassColor = stripe ? const Color(0xFF0A1520) : const Color(0xFF081018);
      }

      canvas.drawRect(
        Rect.fromLTRB(0, prev.y, w, curr.y),
        Paint()..color = grassColor,
      );

      // Road surface
      Color roadColor = stripe ? const Color(0xFF333340) : const Color(0xFF2A2A35);
      final roadLeft = prev.x;
      final roadRight = prev.x + prev.w;
      final roadLeftN = curr.x;
      final roadRightN = curr.x + curr.w;

      final roadPath = Path()
        ..moveTo(roadLeft, prev.y)
        ..lineTo(roadRight, prev.y)
        ..lineTo(roadRightN, curr.y)
        ..lineTo(roadLeftN, curr.y)
        ..close();

      canvas.drawPath(roadPath, Paint()..color = roadColor);

      // Lane markings
      if (stripe) {
        for (int lane = 1; lane <= 2; lane++) {
          double laneT = lane / 3.0;
          double x1 = prev.x + prev.w * laneT;
          double x2 = curr.x + curr.w * laneT;
          canvas.drawLine(
            Offset(x1, prev.y), Offset(x2, curr.y),
            Paint()..color = Colors.white24..strokeWidth = max(1, prev.scale * 6),
          );
        }
      }

      // Road edges (neon)
      Color edgeColor = nitroActive
          ? Color.lerp(Colors.red, Colors.orange, glowValue)!
          : Color.lerp(Colors.cyanAccent, Colors.blueAccent, glowValue)!;

      for (int side = 0; side <= 1; side++) {
        double x1 = side == 0 ? roadLeft : roadRight;
        double x2 = side == 0 ? roadLeftN : roadRightN;
        canvas.drawLine(
          Offset(x1, prev.y), Offset(x2, curr.y),
          Paint()
            ..color = edgeColor.withOpacity(0.6)
            ..strokeWidth = max(1, prev.scale * 8)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }

    // --- Draw Roadside Objects (far to near) ---
    for (int i = projected.length - 1; i > 0; i--) {
      final seg = projected[i];
      for (var obj in roadside) {
        if (obj.segmentIndex.toInt() == seg.segIndex) {
          double objX = obj.side < 0
              ? seg.x - seg.w * 0.15
              : seg.x + seg.w + seg.w * 0.15;
          double objScale = seg.scale * 600;
          if (objScale < 2) continue;

          _drawRoadsideObject(canvas, obj.type, objX, seg.y, objScale, currentZone);
        }
      }
    }

    // --- Draw Traffic Cars (far to near) ---
    for (int i = projected.length - 1; i > 0; i--) {
      final seg = projected[i];
      for (var car in traffic) {
        int carSegIdx = car.segmentIndex.toInt() % road.length;
        if (carSegIdx == seg.segIndex && seg.depth > 2) {
          double laneT = (car.lane + 0.5) / 3.0;
          double carX = seg.x + seg.w * laneT;
          double carScale = seg.scale * 500;
          if (carScale < 3) continue;
          _drawTrafficCar(canvas, car, carX, seg.y, carScale);
        }
      }
    }

    // --- Draw Player Car ---
    _drawPlayerCar(canvas, size);

    // --- Speed lines ---
    if (speed > 200) {
      final linePaint = Paint()
        ..color = Colors.white.withOpacity((speed - 200) / 500 * 0.15)
        ..strokeWidth = 1;
      final rng = Random(42);
      for (int i = 0; i < 30; i++) {
        double lx = rng.nextDouble() * w;
        double ly = h * 0.4 + rng.nextDouble() * h * 0.6;
        double len = 20 + speed / 10;
        canvas.drawLine(Offset(lx, ly), Offset(lx, ly + len), linePaint);
      }
    }

    // Crash flash
    if (crashed) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.red.withOpacity(0.15));
    }
  }

  void _drawSky(Canvas canvas, Size size) {
    final w = size.width;
    final horizonY = size.height * 0.38;

    List<Color> skyColors;
    if (currentZone == 0) {
      // City night
      skyColors = [const Color(0xFF050510), const Color(0xFF151035), const Color(0xFF2A1550)];
    } else if (currentZone == 2) {
      // Mountain dusk
      skyColors = [const Color(0xFF0A0515), const Color(0xFF1A1030), const Color(0xFF352050)];
    } else {
      // Highway twilight
      skyColors = [const Color(0xFF020208), const Color(0xFF0A0820), const Color(0xFF1A1040)];
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, horizonY),
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: skyColors,
      ).createShader(Rect.fromLTWH(0, 0, w, horizonY)),
    );

    // Stars
    final rng = Random(123);
    for (int i = 0; i < 60; i++) {
      double sx = (rng.nextDouble() * w + skyOffset * 50) % w;
      double sy = rng.nextDouble() * horizonY * 0.8;
      double brightness = 0.3 + rng.nextDouble() * 0.5;
      canvas.drawCircle(
        Offset(sx, sy), 0.5 + rng.nextDouble(),
        Paint()..color = Colors.white.withOpacity(brightness),
      );
    }

    // Mountains/Buildings silhouette
    final silhPaint = Paint()..color = const Color(0xFF0A0A18);
    final silhPath = Path();
    silhPath.moveTo(0, horizonY);
    double silhSeed = skyOffset * 100;
    for (double x = 0; x <= w; x += 8) {
      double sh = 20 + sin(x * 0.01 + silhSeed) * 30 + sin(x * 0.03 + silhSeed * 0.5) * 15;
      if (currentZone == 0) {
        // City: jagged buildings
        sh = 10 + ((sin(x * 0.05 + silhSeed) * 40).abs()) + ((cos(x * 0.08) * 20).abs());
      }
      silhPath.lineTo(x, horizonY - sh);
    }
    silhPath.lineTo(w, horizonY);
    silhPath.close();
    canvas.drawPath(silhPath, silhPaint);
  }

  void _drawRoadsideObject(Canvas canvas, int type, double x, double y, double scale, int zone) {
    if (scale < 3) return;
    switch (type) {
      case 0: // Tree
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y - scale * 0.3), width: scale * 0.1, height: scale * 0.6),
          Paint()..color = const Color(0xFF3A2A1A),
        );
        canvas.drawCircle(Offset(x, y - scale * 0.6), scale * 0.25, Paint()..color = const Color(0xFF1A4A1A));
        break;
      case 1: // Building
        double bw = scale * 0.4;
        double bh = scale * 0.8;
        canvas.drawRect(
          Rect.fromLTWH(x - bw / 2, y - bh, bw, bh),
          Paint()..color = const Color(0xFF1A1A2A),
        );
        // Windows
        for (double wy = y - bh + scale * 0.08; wy < y - scale * 0.1; wy += scale * 0.12) {
          for (double wx = x - bw / 2 + scale * 0.04; wx < x + bw / 2 - scale * 0.04; wx += scale * 0.1) {
            canvas.drawRect(
              Rect.fromLTWH(wx, wy, scale * 0.06, scale * 0.06),
              Paint()..color = Colors.yellow.withOpacity(0.3 + Random(wx.toInt() + wy.toInt()).nextDouble() * 0.4),
            );
          }
        }
        break;
      case 2: // Lamppost
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y - scale * 0.4), width: scale * 0.03, height: scale * 0.8),
          Paint()..color = Colors.grey.shade700,
        );
        canvas.drawCircle(
          Offset(x, y - scale * 0.8), scale * 0.06,
          Paint()..color = Colors.yellow.withOpacity(0.8)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        break;
      case 3: // Billboard
        double bw = scale * 0.5;
        double bh = scale * 0.25;
        canvas.drawRect(Rect.fromLTWH(x - bw / 2, y - scale * 0.7 - bh, bw, bh),
          Paint()..color = Colors.cyanAccent.withOpacity(0.15),
        );
        canvas.drawRect(Rect.fromLTWH(x - bw / 2, y - scale * 0.7 - bh, bw, bh),
          Paint()..color = Colors.cyanAccent.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 1,
        );
        break;
    }
  }

  void _drawTrafficCar(Canvas canvas, _TrafficCar car, double x, double y, double scale) {
    double cw = scale * 0.14;
    double ch = scale * 0.22;
    // Body
    final bodyRect = Rect.fromCenter(center: Offset(x, y - ch / 2), width: cw, height: ch);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(scale * 0.02)),
      Paint()..color = car.color.withOpacity(0.9),
    );
    // Windshield
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, y - ch * 0.6), width: cw * 0.7, height: ch * 0.2),
      Paint()..color = Colors.lightBlue.withOpacity(0.4),
    );
    // Tail lights
    double tlSize = max(1, scale * 0.015);
    canvas.drawCircle(Offset(x - cw * 0.35, y), tlSize, Paint()..color = Colors.red..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawCircle(Offset(x + cw * 0.35, y), tlSize, Paint()..color = Colors.red..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

    // Police lights
    if (car.type == 3) {
      Color policeColor = (roadPosition * 10).toInt() % 2 == 0 ? Colors.red : Colors.blue;
      canvas.drawCircle(Offset(x, y - ch * 0.8), max(1, scale * 0.02),
        Paint()..color = policeColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }
  }

  void _drawPlayerCar(Canvas canvas, Size size) {
    final cx = size.width / 2 + playerX * size.width * 0.3;
    final cy = size.height * 0.82;
    final carW = 70.0;
    final carH = 110.0;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(playerTilt * 0.2);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 50), width: carW + 20, height: 20),
      Paint()..color = Colors.black.withOpacity(0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Body
    final bodyPath = Path()
      ..moveTo(-carW * 0.35, carH * 0.5)
      ..lineTo(-carW * 0.4, -carH * 0.1)
      ..lineTo(-carW * 0.3, -carH * 0.45)
      ..lineTo(carW * 0.3, -carH * 0.45)
      ..lineTo(carW * 0.4, -carH * 0.1)
      ..lineTo(carW * 0.35, carH * 0.5)
      ..close();

    canvas.drawPath(bodyPath, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF2A2A3A), Color(0xFF0A0A15)],
      ).createShader(Rect.fromCenter(center: Offset.zero, width: carW, height: carH)));

    // Windshield
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, -carH * 0.2), width: carW * 0.5, height: carH * 0.18),
      Paint()..color = Colors.lightBlue.withOpacity(0.25),
    );

    // Headlights
    canvas.drawCircle(Offset(-carW * 0.25, -carH * 0.42), 4,
      Paint()..color = Colors.white..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawCircle(Offset(carW * 0.25, -carH * 0.42), 4,
      Paint()..color = Colors.white..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Tail lights
    canvas.drawRect(Rect.fromLTWH(-carW * 0.35, carH * 0.4, carW * 0.15, 6),
      Paint()..color = Colors.red.withOpacity(0.9)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawRect(Rect.fromLTWH(carW * 0.2, carH * 0.4, carW * 0.15, 6),
      Paint()..color = Colors.red.withOpacity(0.9)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

    // Neon underglow
    Color glowColor = nitroActive ? Colors.redAccent : Colors.cyanAccent;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, carH * 0.3), width: carW * 0.6, height: 6),
      Paint()..color = glowColor.withOpacity(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Nitro exhaust flames
    if (nitroActive && speed > 100) {
      final rng = Random();
      for (int i = 0; i < 3; i++) {
        double flameH = 15 + rng.nextDouble() * 25;
        double flameW = 4 + rng.nextDouble() * 6;
        double fx = -8 + rng.nextDouble() * 16;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(fx, carH * 0.5 + flameH / 2 + 4), width: flameW, height: flameH),
          Paint()
            ..color = Color.lerp(Colors.orange, Colors.red, rng.nextDouble())!.withOpacity(0.7)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NfsRoadPainter old) => true;
}

class _ProjectedSegment {
  final double x, y, w, scale;
  final int segIndex, depth;
  _ProjectedSegment({required this.x, required this.y, required this.w, required this.scale, required this.segIndex, required this.depth});
}
