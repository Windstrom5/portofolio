import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:project_test/widget/hud_components.dart';

class PremierLeagueTable extends StatefulWidget {
  final bool isMinimized;
  final VoidCallback onToggleMinimize;

  const PremierLeagueTable({
    super.key,
    required this.isMinimized,
    required this.onToggleMinimize,
  });

  @override
  State<PremierLeagueTable> createState() => _PremierLeagueTableState();
}

class _PremierLeagueTableState extends State<PremierLeagueTable>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> teams = [];
  bool isLoading = true;
  String? errorMessage;
  String lastUpdated = "Fetching...";
  Timer? _refreshTimer;
  late AnimationController _pulseController;

  static const Map<String, Map<String, String>> leagues = {
    "PREMIER LEAGUE": {
      "id": "1",
      "season": "777",
      "name_jp": "イングランド・プレミアリーグ",
      "color": "0xFFDA291C"
    },
    "LA LIGA": {
      "id": "4",
      "season":
          "730", // Example ID, might need verification but good for structure
      "name_jp": "スペイン・ラ・リーガ",
      "color": "0xFFDE002B"
    },
    "SERIE A": {
      "id": "5",
      "season": "731",
      "name_jp": "イタリア・セリエA",
      "color": "0xFF00529B"
    },
    "BUNDESLIGA": {
      "id": "2",
      "season": "732",
      "name_jp": "ドイツ・ブンデスリーガ",
      "color": "0xFFD71920"
    },
  };

  String currentLeague = "PREMIER LEAGUE";

  @override
  void initState() {
    super.initState();
    _fetchStandings();
    _refreshTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _fetchStandings();
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchStandings() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final leagueData = leagues[currentLeague]!;
      final url =
          'https://api.codetabs.com/v1/proxy?quest=https://footballapi.pulselive.com/football/standings?compSeasons=${leagueData["season"]}&competitions=${leagueData["id"]}&pageSize=20';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List entries = data['tables'][0]['entries'];

        final List<Map<String, dynamic>> fetchedTeams = entries.map((entry) {
          final teamData = entry['team'];
          final overall = entry['overall'];
          final annotations = entry['annotations'] as List?;

          String zone = "";
          if (annotations != null && annotations.isNotEmpty) {
            zone = annotations[0]['type'] ?? "";
          }

          return {
            "pos": entry['position'],
            "name": teamData['shortName'] ?? teamData['name'],
            "p": overall['played'],
            "pts": overall['points'],
            "zone": zone,
          };
        }).toList();

        if (mounted) {
          setState(() {
            teams = fetchedTeams;
            isLoading = false;
            lastUpdated = data['timestamp'] != null
                ? data['timestamp']['label']
                : "Updated Just Now";
          });
        }
      } else {
        throw Exception('Failed to load standings');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "SYNC ERROR";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMinimized) {
      return _buildMinimizedState();
    }

    final leagueColor = Color(int.parse(leagues[currentLeague]!["color"]!));

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.clamp(200.0, 400.0);
        return HUDContainer(
          width: w,
          height:
              (MediaQuery.of(context).size.height * 0.55).clamp(400.0, 520.0),
          padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 12.r),
          accentColor: leagueColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderWidget(leagueColor),
              SizedBox(height: 8.h),
              if (isLoading)
                _buildLoadingState(leagueColor)
              else if (errorMessage != null)
                _buildErrorState()
              else ...[
                _buildTableHeader(leagueColor),
                SizedBox(height: 4.h),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: teams
                          .take(10)
                          .map((team) => _buildTeamRow(team))
                          .toList(),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                _buildFooter(leagueColor),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderWidget(Color leagueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) => Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        color: Colors.redAccent
                            .withOpacity(_pulseController.value * 0.8 + 0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent
                                .withOpacity(_pulseController.value * 0.5),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "LIVE DATA STREAM",
                    style: GoogleFonts.vt323(
                      color: Colors.redAccent,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              _buildLeagueSelector(leagueColor),
              Text(
                leagues[currentLeague]!["name_jp"]!,
                style: GoogleFonts.notoSansJp(
                  color: leagueColor.withOpacity(0.8),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: widget.onToggleMinimize,
              icon: Icon(Icons.remove, color: Colors.white60, size: 20.sp),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: "MINIMIZE",
            ),
            SizedBox(width: 12.w),
            if (!isLoading)
              IconButton(
                onPressed: _fetchStandings,
                icon: Icon(Icons.refresh, color: leagueColor, size: 22.sp),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                hoverColor: leagueColor.withOpacity(0.1),
                tooltip: "SYNC",
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeagueSelector(Color leagueColor) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: const Color(0xFF1a1a1a),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLeague,
          dropdownColor: const Color(0xFF0D0D0D),
          icon:
              Icon(Icons.keyboard_arrow_down, color: leagueColor, size: 18.sp),
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
          onChanged: (String? newValue) {
            if (newValue != null && newValue != currentLeague) {
              setState(() {
                currentLeague = newValue;
                _fetchStandings();
              });
            }
          },
          items: leagues.keys.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color leagueColor) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40.w,
              height: 40.w,
              child: CircularProgressIndicator(
                  color: leagueColor, strokeWidth: 2.w),
            ),
            SizedBox(height: 24.h),
            Text(
              "ESTABLISHING SATELLITE LINK...",
              style: GoogleFonts.vt323(color: leagueColor, fontSize: 18.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 40.sp),
            SizedBox(height: 16.h),
            Text(
              "CONNECTION FAILED: $errorMessage",
              style:
                  GoogleFonts.vt323(color: Colors.redAccent, fontSize: 18.sp),
            ),
            SizedBox(height: 16.h),
            OutlinedButton(
              onPressed: _fetchStandings,
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.cyanAccent)),
              child: Text("RETRY BROADCAST",
                  style: GoogleFonts.vt323(
                      color: Colors.cyanAccent, fontSize: 16.sp)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(Color leagueColor) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: leagueColor.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: leagueColor, width: 1.h)),
      ),
      child: Row(
        children: [
          SizedBox(width: 28.w, child: _headerCell("#", null)),
          Expanded(
              child: _headerCell("CLUB / チーム", null, align: TextAlign.left)),
          SizedBox(width: 30.w, child: _headerCell("P", null)),
          SizedBox(width: 36.w, child: _headerCell("PTS", null)),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double? width,
      {TextAlign align = TextAlign.center}) {
    return Text(
      text,
      textAlign: align,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.vt323(
        color: Colors.white,
        fontSize: 13.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTeamRow(Map<String, dynamic> team) {
    bool isUcl = team['zone'] == 'Q';
    bool isRel = team['zone'] == 'R';
    bool isTop = team['pos'] == 1;

    Color accentColor = isUcl
        ? Colors.cyanAccent
        : isRel
            ? Colors.redAccent
            : Colors.white;
    if (isTop) accentColor = Colors.yellowAccent;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        border: Border(left: BorderSide(color: accentColor, width: 3.w)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28.w,
            child: _cell("${team['pos']}", null,
                color: accentColor, isBold: isTop),
          ),
          Expanded(
            child: _cell(team['name'].toString().toUpperCase(), null,
                align: TextAlign.left, color: Colors.white, isBold: isTop),
          ),
          SizedBox(
            width: 30.w,
            child: _cell("${team['p']}", null, color: Colors.white70),
          ),
          SizedBox(
            width: 36.w,
            child:
                _cell("${team['pts']}", null, color: accentColor, isBold: true),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, double? width,
      {TextAlign align = TextAlign.center,
      Color color = Colors.white,
      bool isBold = false}) {
    return Text(
      text,
      textAlign: align,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: GoogleFonts.orbitron(
        color: color,
        fontSize: 12.sp,
        fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
      ),
    );
  }

  Widget _buildFooter(Color leagueColor) {
    return Column(
      children: [
        Divider(color: leagueColor.withOpacity(0.3)),
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(color: leagueColor),
              child: Text(
                "V3.5",
                style: GoogleFonts.vt323(
                    color: Colors.black,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                "SYNC: ${lastUpdated.toUpperCase()}",
                style: GoogleFonts.vt323(
                  color: Colors.white38,
                  fontSize: 10.sp,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMinimizedState() {
    final leagueColor = Color(int.parse(leagues[currentLeague]!["color"]!));

    return GestureDetector(
      onTap: widget.onToggleMinimize,
      child: HUDContainer(
        width: 140.w,
        height: 60.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        accentColor: leagueColor,
        child: Row(
          children: [
            Icon(Icons.sports_soccer, color: leagueColor, size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "FOOTBALL STANDINGS",
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currentLeague.toUpperCase(),
                    style: GoogleFonts.vt323(
                      color: leagueColor.withOpacity(0.7),
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Container(
                width: 6.w,
                height: 6.w,
                decoration: BoxDecoration(
                  color: Colors.redAccent
                      .withOpacity(_pulseController.value * 0.8 + 0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
