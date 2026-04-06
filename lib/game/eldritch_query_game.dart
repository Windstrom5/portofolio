import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Data Models ──────────────────────────────────────────────

enum GamePhase { characterSelect, briefing, playing }

class Investigator {
  final String name;
  final String description;
  final String skill;
  final String skillDesc;
  final int startingSanity;
  final int startingHealth;

  Investigator({
    required this.name,
    required this.description,
    required this.skill,
    required this.skillDesc,
    required this.startingSanity,
    required this.startingHealth,
  });
}

class GameLog {
  final String query;
  final List<Map<String, dynamic>> results;
  final String? error;
  final DateTime timestamp;

  GameLog({required this.query, required this.results, this.error, DateTime? time})
      : timestamp = time ?? DateTime.now();
}

class EldritchGameState {
  Investigator? investigator;
  GamePhase phase = GamePhase.characterSelect;
  int tutorialStep = 0;
  int sanity = 100;
  int health = 100;
  int doom = 0;
  bool isGameOver = false;
  String message = "Welcome, Investigator. The archives are open.";
  List<GameLog> history = [];
  Set<String> discoveredClues = {};

  void selectInvestigator(Investigator inv) {
    investigator = inv;
    sanity = inv.startingSanity;
    health = inv.startingHealth;
    phase = GamePhase.briefing;
  }

  void reset() {
    investigator = null;
    phase = GamePhase.characterSelect;
    tutorialStep = 0;
    sanity = 100;
    health = 100;
    doom = 0;
    isGameOver = false;
    message = "Welcome, Investigator. The archives are open.";
    history = [];
    discoveredClues = {};
  }
}

// ─── Mock SQL Engine ──────────────────────────────────────────

class MockSqlEngine {
  final Map<String, List<Map<String, dynamic>>> tables = {
    'investigators': [
      {'id': 1, 'name': 'Thomas Malone', 'status': 'Active', 'location': 'New York', 'sanity': 85},
      {'id': 2, 'name': 'Harvey Walters', 'status': 'Missing', 'location': 'Arkham', 'sanity': 40},
      {'id': 3, 'name': 'Sister Mary', 'status': 'Active', 'location': 'London', 'sanity': 95},
    ],
    'locations': [
      {'id': 1, 'name': 'Arkham', 'country': 'USA', 'threat_level': 4, 'last_seen': '1926-03-15'},
      {'id': 2, 'name': 'London', 'country': 'UK', 'threat_level': 2, 'last_seen': '1926-03-20'},
      {'id': 3, 'name': 'Shanghai', 'country': 'China', 'threat_level': 5, 'last_seen': '1926-03-10'},
      {'id': 4, 'name': 'Buenos Aires', 'country': 'Argentina', 'threat_level': 1, 'last_seen': '1926-03-25'},
    ],
    'cult_logs': [
      {'id': 101, 'date': '1926-02-12', 'sender': 'Unknown', 'message': 'The stars are almost right.', 'location_id': 1},
      {'id': 102, 'date': '1926-02-28', 'sender': 'Black Pharoah', 'message': 'The ritual requires the Silver Key.', 'location_id': 3},
      {'id': 103, 'date': '1926-03-05', 'sender': 'Yellow King', 'message': 'Hastur awaits in the mist.', 'location_id': 2},
    ],
    'artifact_registry': [
      {'id': 501, 'name': 'Silver Key', 'owner': 'Missing', 'origin': 'Unknown', 'description': 'A key that unlocks the gate.'},
      {'id': 502, 'name': 'Necronomicon', 'owner': 'Miskatonic University', 'origin': 'Damascus', 'description': 'FORBIDDEN KNOWLEDGE. DO NOT READ.'},
      {'id': 503, 'name': 'Elder Sign', 'owner': 'Thomas Malone', 'origin': 'Arkham', 'description': 'A protective ward.'},
    ],
  };

  GameLog execute(String query) {
    String q = query.trim().toLowerCase();
    
    // Basic SQL Parsing Simulation
    if (!q.startsWith('select')) {
      return GameLog(query: query, results: [], error: "SQL Syntax Error: Only SELECT queries are permitted in the Read-Only Archives.");
    }

    try {
      // Very simple regex-based parser for simulation
      final fromMatch = RegExp(r'from\s+(\w+)').firstMatch(q);
      if (fromMatch == null) return GameLog(query: query, results: [], error: "SQL Syntax Error: FROM clause missing.");
      
      String tableName = fromMatch.group(1)!;
      if (!tables.containsKey(tableName)) {
        return GameLog(query: query, results: [], error: "SQL Error: Table '$tableName' not found.");
      }

      List<Map<String, dynamic>> results = List.from(tables[tableName]!);

      // Handle WHERE (very basic)
      final whereMatch = RegExp(r"where\s+(\w+)\s*=\s*(['\w\d\-]+)").firstMatch(q);
      if (whereMatch != null) {
        String column = whereMatch.group(1)!;
        String value = whereMatch.group(2)!.replaceAll("'", "");
        results = results.where((row) => row[column].toString().toLowerCase() == value).toList();
      }

      return GameLog(query: query, results: results);
    } catch (e) {
      return GameLog(query: query, results: [], error: "Database Error: Internal query execution failure.");
    }
  }
}

// ─── Main Game Widget ─────────────────────────────────────────

class EldritchQueryGame extends StatefulWidget {
  final VoidCallback? onClose;
  const EldritchQueryGame({super.key, this.onClose});

  @override
  State<EldritchQueryGame> createState() => _EldritchQueryGameState();
}

class _EldritchQueryGameState extends State<EldritchQueryGame> {
  final EldritchGameState _state = EldritchGameState();
  final MockSqlEngine _engine = MockSqlEngine();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _terminalScrollController = ScrollController();
  final FocusNode _terminalFocusNode = FocusNode();

  final List<Investigator> _investigators = [
    Investigator(
      name: "Leo Anderson",
      description: "Expedition Leader",
      skill: "Logistics",
      skillDesc: "Advanced planning slows the passage of time. Doom increases every 2 queries.",
      startingSanity: 80,
      startingHealth: 120,
    ),
    Investigator(
      name: "Diana Stanley",
      description: "Redeemed Cultist",
      skill: "Dark Insight",
      skillDesc: "Her past allows her to navigate the archives without fear. SQL errors do not drain Sanity.",
      startingSanity: 120,
      startingHealth: 80,
    ),
    Investigator(
      name: "Silas Marsh",
      description: "The Sailor",
      skill: "Global Reach",
      skillDesc: "He knows every port. SQL queries filtering by 'location' are free actions.",
      startingSanity: 90,
      startingHealth: 110,
    ),
    Investigator(
      name: "Norman Withers",
      description: "The Astronomer",
      skill: "Star Reading",
      skillDesc: "His charts predict the void. He can see the exact numerical threat level of locations.",
      startingSanity: 150,
      startingHealth: 50,
    ),
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _terminalScrollController.dispose();
    _terminalFocusNode.dispose();
    super.dispose();
  }

  void _processQuery(String query) {
    if (query.isEmpty || _state.isGameOver) return;

    setState(() {
      final log = _engine.execute(query);
      _state.history.add(log);
      
      // Affect Doom
      bool isFreeAction = false;
      if (_state.investigator?.name == "Silas Marsh" && query.toLowerCase().contains('where location')) {
        isFreeAction = true;
      }

      if (!isFreeAction) {
        if (_state.investigator?.name == "Leo Anderson") {
          if (_state.history.length % 2 == 0) _state.doom += 1;
        } else {
          _state.doom += 1;
        }
      }

      // Special Trigger Logic
      if (query.toLowerCase().contains('necronomicon')) {
        _state.sanity -= 20;
        _state.message = "You read passages from the Necronomicon... Your mind fractals.";
      } else if (query.toLowerCase().contains('silver key')) {
        _state.discoveredClues.add('Silver Key');
        _state.message = "You found information about the Silver Key! It seems to be in Shanghai.";
      } else if (query.toLowerCase().contains('black pharoah') && query.toLowerCase().contains('shanghai')) {
        _state.discoveredClues.add('Pharoah Location');
        _state.message = "CLUE FOUND: The Black Pharoah is preparing the ritual in a Shanghai warehouse.";
      }

      // Check Win/Loss
      if (_state.sanity <= 0) {
        _state.isGameOver = true;
        _state.message = "GAME OVER: You have lost your mind to the void.";
      } else if (_state.doom >= 15) {
        _state.isGameOver = true;
        _state.message = "GAME OVER: The Doom counter reached maximum. The Ancient One has awakened.";
      } else if (_state.discoveredClues.contains('Pharoah Location') && _state.discoveredClues.contains('Silver Key')) {
        _state.isGameOver = true;
        _state.message = "VICTORY: You identified the ritual site and the artifact. The MIU has transitioned to tactical containment.";
      }

      // Tutorial Progress
      if (_state.phase == GamePhase.playing && _state.tutorialStep < 3) {
        if (_state.tutorialStep == 0 && query.toLowerCase().contains('select * from investigators')) {
          _state.tutorialStep = 1;
        } else if (_state.tutorialStep == 1 && (query.toLowerCase().contains('location') || query.toLowerCase().contains('where'))) {
          _state.tutorialStep = 2;
        }
      }
    });

    _inputController.clear();
    Timer(const Duration(milliseconds: 100), () {
      _terminalScrollController.animateTo(
        _terminalScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _terminalFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget coreContent;
    switch (_state.phase) {
      case GamePhase.characterSelect:
        coreContent = _buildCharacterSelect();
        break;
      case GamePhase.briefing:
        coreContent = _buildBriefing();
        break;
      case GamePhase.playing:
        coreContent = Row(
          children: [
            Expanded(flex: 3, child: _buildTerminal()),
            Container(
              width: 300.w,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1B26),
                border: Border(left: BorderSide(color: Colors.cyanAccent.withOpacity(0.1))),
              ),
              child: _buildHUD(),
            ),
          ],
        );
        break;
    }

    return Container(color: const Color(0xFF0F111A), child: coreContent);
  }

  Widget _buildCharacterSelect() {
    return Column(
      children: [
        SizedBox(height: 60.h),
        Text("SELECT YOUR INVESTIGATOR",
            style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 28.sp, fontWeight: FontWeight.bold, letterSpacing: 4)),
        SizedBox(height: 10.h),
        Text("Only one can survive the archives.",
            style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 14.sp)),
        SizedBox(height: 50.h),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 100.w),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 30.w,
                mainAxisSpacing: 30.h,
                childAspectRatio: 1.8, // Adjusted to avoid overflow
              ),
              itemCount: _investigators.length,
              itemBuilder: (context, index) {
                final inv = _investigators[index];
                return GestureDetector(
                  onTap: () => setState(() => _state.selectInvestigator(inv)),
                  child: Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80.w,
                          height: 80.w,
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person, color: Colors.cyanAccent, size: 40.sp),
                        ),
                        SizedBox(width: 20.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(inv.name, style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                              Text(inv.description, style: GoogleFonts.shareTechMono(color: Colors.cyanAccent, fontSize: 12.sp)),
                              SizedBox(height: 8.h),
                              Text("SKILL: ${inv.skill}",
                                  style: GoogleFonts.shareTechMono(
                                      color: Colors.amber,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 4.h),
                              Expanded(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Text(inv.skillDesc,
                                      style: GoogleFonts.shareTechMono(
                                          color: Colors.white60,
                                          fontSize: 10.sp)),
                                ),
                              ),
                            ],
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
      ],
    );
  }

  Widget _buildBriefing() {
    return Center(
      child: Container(
        width: 800.w,
        padding: EdgeInsets.all(40.r),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
          boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 40)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ARCHIVAL BRIEFING: ${_state.investigator?.name.toUpperCase()}",
                style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 24.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 30.h),
            Text(
              "Welcome to the Miskatonic Investigatory Unit. You are here to prevent the Great Old One's return.\n\n"
              "HOW TO PLAY:\n"
              "1. Use the SQL Terminal to find clues in the archives.\n"
              "2. Syntax: SELECT * FROM <table> WHERE <column> = '<value>'\n"
              "3. Available Tables: 'investigators', 'locations', 'cult_logs', 'artifact_registry'.\n"
              "4. Every query advances the DOOM clock.\n"
              "5. Reading forbidden knowledge drains your SANITY.\n\n"
              "OBJECTIVE:\n"
              "Find the location of the ritual and the missing Silver Key artifact.",
              style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14.sp, height: 1.6),
            ),
            SizedBox(height: 40.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _state.phase = GamePhase.playing),
                  child: Text("BEGIN INVESTIGATION", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminal() {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          color: Colors.black,
          child: Row(
            children: [
              const Icon(Icons.terminal, color: Colors.cyanAccent, size: 16),
              SizedBox(width: 8.w),
              Text("MISKATONIC ARCHIVAL TERMINAL v4.2",
                  style: GoogleFonts.shareTechMono(color: Colors.cyanAccent, fontSize: 12.sp)),
              const Spacer(),
              if (widget.onClose != null)
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: Colors.white38, size: 16),
                ),
            ],
          ),
        ),
        // History
        Expanded(
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.all(16.r),
                child: ListView.builder(
                  controller: _terminalScrollController,
                  itemCount: _state.history.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildSystemMessage("SYSTEM INITIALIZED. STANDBY FOR ENCRYPTED ARCHIVE ACCESS...");
                    }
                    final log = _state.history[index - 1];
                    return _buildLogEntry(log);
                  },
                ),
              ),
              if (_state.tutorialStep < 3)
                Positioned(
                  top: 20.h,
                  right: 20.w,
                  child: _buildTutorialHint(),
                ),
            ],
          ),
        ),
        // Input
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          color: Colors.black.withOpacity(0.5),
          child: Row(
            children: [
              Text("investigator@miskatonic:~\$ ",
                  style: GoogleFonts.shareTechMono(color: Colors.cyanAccent, fontSize: 14.sp)),
              Expanded(
                child: TextField(
                  controller: _inputController,
                  focusNode: _terminalFocusNode,
                  onSubmitted: _processQuery,
                  style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14.sp),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  cursorColor: Colors.cyanAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTutorialHint() {
    String title = "";
    String desc = "";
    switch (_state.tutorialStep) {
      case 0:
        title = "TUTORIAL: THE BASICS";
        desc = "Type: SELECT * FROM investigators\n(Lists all personnel records)";
        break;
      case 1:
        title = "TUTORIAL: FILTERING";
        desc = "Type: SELECT * FROM locations WHERE name = 'Arkham'\n(Find specific data points)";
        break;
      case 2:
        title = "TUTORIAL: THE THREAT";
        desc = "Investigate the 'cult_logs' and 'artifact_registry'.\nWatch your Sanity!";
        break;
    }

    return Container(
      width: 250.w,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.cyanAccent.withOpacity(0.1),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 11.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 4.h),
          Text(desc, style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 10.sp)),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: () => setState(() => _state.tutorialStep = 3),
            child: Text("SKIP TUTORIAL", style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 9.sp, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(GameLog log) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Text("> ${log.query}", style: GoogleFonts.shareTechMono(color: Colors.white30, fontSize: 13.sp)),
        ),
        if (log.error != null)
          Text(log.error!, style: GoogleFonts.shareTechMono(color: Colors.redAccent, fontSize: 13.sp))
        else if (log.results.isEmpty)
          Text("0 rows returned.", style: GoogleFonts.shareTechMono(color: Colors.cyanAccent.withOpacity(0.5), fontSize: 13.sp))
        else
          _buildResultTable(log.results),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildResultTable(List<Map<String, dynamic>> results) {
    final columns = results.first.keys.toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 30.h,
        dataRowMinHeight: 25.h,
        horizontalMargin: 0,
        columnSpacing: 20.w,
        columns: columns.map((c) => DataColumn(label: Text(c.toUpperCase(), style: GoogleFonts.shareTechMono(color: Colors.cyanAccent, fontSize: 11.sp)))).toList(),
        rows: results.map((r) => DataRow(
          cells: columns.map((c) => DataCell(Text(r[c].toString(), style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 11.sp)))).toList(),
        )).toList(),
      ),
    );
  }

  Widget _buildSystemMessage(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(text, style: GoogleFonts.shareTechMono(color: Colors.cyanAccent, fontSize: 12.sp)),
    );
  }

  Widget _buildHUD() {
    return Padding(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.person, color: Colors.cyanAccent, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_state.investigator?.name ?? "UNKNOWN", style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                    Text(_state.investigator?.description ?? "Archival Unit", style: GoogleFonts.shareTechMono(color: Colors.cyanAccent, fontSize: 10.sp)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildStatBar("SANITY", _state.sanity, _state.investigator?.startingSanity ?? 100, Colors.purpleAccent),
          SizedBox(height: 12.h),
          _buildStatBar("HEALTH", _state.health, _state.investigator?.startingHealth ?? 100, Colors.redAccent),
          SizedBox(height: 12.h),
          _buildStatBar("DOOM", _state.doom, 15, Colors.amber),
          const Divider(color: Colors.white10, height: 40),
          Text("SPECIAL ABILITY: ${_state.investigator?.skill.toUpperCase() ?? ""}", style: GoogleFonts.orbitron(color: Colors.amber, fontSize: 10.sp, letterSpacing: 1.2)),
          SizedBox(height: 4.h),
          Text(_state.investigator?.skillDesc ?? "", style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 9.sp)),
          const Divider(color: Colors.white10, height: 40),
          Text("CURRENT OBJECTIVE", style: GoogleFonts.orbitron(color: Colors.white60, fontSize: 10.sp, letterSpacing: 1.2)),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4.r)),
            child: Text(
              _state.message,
              style: GoogleFonts.notoSans(color: Colors.cyanAccent.withOpacity(0.8), fontSize: 11.sp, height: 1.4),
            ),
          ),
          const Spacer(),
          // Evidence Board
          Text("DISCOVERED CLUES", style: GoogleFonts.orbitron(color: Colors.white60, fontSize: 10.sp, letterSpacing: 1.2)),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _state.discoveredClues.map((c) => _buildClueChip(c)).toList(),
          ),
          SizedBox(height: 20.h),
          if (_state.isGameOver)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => _state.reset()),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                child: const Text("RETRY INVESTIGATION"),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, int value, int max, Color color) {
    double progress = (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.shareTechMono(color: color, fontSize: 11.sp)),
            Text("$value / $max", style: GoogleFonts.shareTechMono(color: color, fontSize: 11.sp)),
          ],
        ),
        SizedBox(height: 4.h),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildClueChip(String clue) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(2.r),
        color: Colors.cyanAccent.withOpacity(0.05),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.vpn_key, color: Colors.cyanAccent, size: 10),
          SizedBox(width: 6.w),
          Text(clue.toUpperCase(), style: GoogleFonts.shareTechMono(color: Colors.cyanAccent, fontSize: 9.sp)),
        ],
      ),
    );
  }
}
