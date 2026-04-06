import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_test/service/espn_scraper.dart';
import 'package:project_test/service/official_league_scraper.dart';
import 'package:project_test/utils/cors_utils.dart';
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
  List<PlayerStat> scorers = [];
  List<PlayerStat> assists = [];
  bool isLoading = true;
  String? errorMessage;
  String lastUpdated = "Fetching...";
  String prediction = "Analyzing league table...";
  Timer? _refreshTimer;
  late AnimationController _pulseController;

  static const Map<String, Map<String, String>> leagues = {
    "PREMIER LEAGUE": {
      "name_jp": "イングランド・プレミアリーグ",
      "color": "0xFFDA291C"
    },
    "LA LIGA": {
      "name_jp": "スペイン・ラ・リーガ",
      "color": "0xFFDE002B"
    },
    "SERIE A": {
      "name_jp": "イタリア・セリエA",
      "color": "0xFF00529B"
    },
    "BUNDESLIGA": {
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
      // 1. Fetch Standings from ESPN (Scraper)
      final fetchedStandings = await ESPNScraper.fetchStandings(currentLeague);

      // 2. Map to expected list of maps
      final List<Map<String, dynamic>> fetchedTeams =
          fetchedStandings.map((s) => {
                "pos": s.pos,
                "name": s.name,
                "p": s.p,
                "pts": s.pts,
                "zone": s.zone,
                "logo": s.logoUrl,
              }).toList();

      // 3. Fetch Stats from ESPN
      final stats = await ESPNScraper.fetchStats(currentLeague);

      // 4. Generate Prediction
      String pred = "Competition ongoing...";
      if (fetchedTeams.isNotEmpty) {
        final first = fetchedTeams[0];
        final second = fetchedTeams.length > 1 ? fetchedTeams[1] : null;

        if (first['p'] >= 34) {
          // Near end of season
          if (second != null) {
            final gap = first['pts'] - second['pts'];
            final remainingGames = 38 - (first['p'] as int);
            if (gap > (remainingGames * 3)) {
              pred = "${first['name'].toString().toUpperCase()} ARE CHAMPIONS!";
            } else {
              pred =
                  "${first['name'].toString().toUpperCase()} FAVOURED TO WIN (${gap}pt lead)";
            }
          }
        } else {
          pred = "${first['name'].toString().toUpperCase()} LEADING THE RACE";
        }
      }

      if (mounted) {
        setState(() {
          teams = fetchedTeams;
          scorers = stats["scorers"] ?? [];
          assists = stats["assists"] ?? [];
          prediction = pred;
          isLoading = false;
          lastUpdated = "Updated Live from ESPN";
        });
      }

      // 5. Async-patch Official Logos for a "Premium" feel
      _patchOfficialLogos();
      
      // 6. Async-patch top player photos
      _patchOfficialPlayerPhotos();
    } catch (e) {
      print("Fetch Error: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "SYNC ERROR";
        });
      }
    }
  }

  Future<void> _patchOfficialLogos() async {
    try {
      final officialLogos = await OfficialLeagueScraper.fetchLeagueLogos(currentLeague);
      if (officialLogos.isNotEmpty && mounted) {
        setState(() {
          for (var team in teams) {
            final name = team['name'] as String;
            // Match team names loosely if possible, or direct match
            if (officialLogos.containsKey(name)) {
              team['logo'] = officialLogos[name];
            } else {
              // Try fuzzy match or partial if needed
              final match = officialLogos.keys.firstWhere(
                (k) => k.toLowerCase().contains(name.toLowerCase()) || name.toLowerCase().contains(k.toLowerCase()),
                orElse: () => "",
              );
              if (match.isNotEmpty) {
                team['logo'] = officialLogos[match];
              }
            }
          }
          lastUpdated = "Premium Data Stream Active";
        });
      }
    } catch (e) {
      print("Error patching official logos: $e");
    }
  }

  Future<void> _patchOfficialPlayerPhotos() async {
    if (currentLeague != "PREMIER LEAGUE" && currentLeague != "LA LIGA") return;

    // Only patch top 5 for performance
    final scorersToPatch = scorers.take(5).toList();
    final assistsToPatch = assists.take(5).toList();

    for (var player in scorersToPatch) {
      _patchSinglePlayer(player);
    }
    for (var player in assistsToPatch) {
      _patchSinglePlayer(player);
    }
  }

  Future<void> _patchSinglePlayer(PlayerStat player) async {
    String? officialUrl;
    if (currentLeague == "PREMIER LEAGUE") {
      officialUrl = await OfficialLeagueScraper.fetchPremierLeaguePlayerPhoto(player.name);
    } else if (currentLeague == "LA LIGA") {
      officialUrl = await OfficialLeagueScraper.fetchLaLigaPlayerPhoto(player.name);
    }

    if (officialUrl != null && mounted) {
      setState(() {
        player.imageUrl = officialUrl!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMinimized) {
      return _buildMinimizedState();
    }

    return AnimatedBuilder(
      key: const ValueKey('premier_league_table_root'),
      animation: _pulseController,
      builder: (context, child) {
        final leagueColor =
            Color(int.parse(leagues[currentLeague]!["color"]!));

        return HUDContainer(
          accentColor: leagueColor,
          pulse: _pulseController.value,
          child: Column(
            children: [
              _buildHeaderWidget(leagueColor),
              SizedBox(height: 12.h),
              if (isLoading)
                _buildLoadingState(leagueColor)
              else if (errorMessage != null)
                _buildErrorState()
              else ...[
                _buildPredictionBanner(leagueColor),
                SizedBox(height: 12.h),
                Expanded(
                  child: RepaintBoundary(
                    child: (MediaQuery.of(context).size.width > 800)
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  flex: 3,
                                  child: _buildStandingsSection(leagueColor)),
                              SizedBox(width: 20.w),
                              Expanded(
                                  flex: 2,
                                  child: _buildStatsSection(leagueColor)),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildStandingsSection(leagueColor),
                                SizedBox(height: 20.h),
                                _buildStatsSection(leagueColor),
                              ],
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 12.h),
                _buildFooter(leagueColor),
              ],
            ],
          ),
        );
      },
    );


  }

  Widget _buildPredictionBanner(Color leagueColor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: leagueColor.withOpacity(0.1),
        border: Border.all(color: leagueColor.withOpacity(0.5), width: 1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: leagueColor, size: 16.sp),
          SizedBox(width: 10.w),
          Text(
            "LEAGUE FORECAST:",
            style: GoogleFonts.orbitron(
              color: leagueColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              prediction,
              style: GoogleFonts.vt323(
                color: Colors.white,
                fontSize: 16.sp,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandingsSection(Color leagueColor) {
    return Column(
      children: [
        _buildTableHeader(leagueColor),
        SizedBox(height: 4.h),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: teams.length,
            itemBuilder: (context, index) => _buildTeamRow(teams[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(Color leagueColor) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            indicatorColor: leagueColor,
            labelStyle: GoogleFonts.orbitron(fontSize: 10.sp, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "TOP SCORERS"),
              Tab(text: "TOP ASSISTS"),
            ],
          ),
          SizedBox(height: 10.h),
          Expanded(
            child: TabBarView(
              children: [
                _buildStatsList(scorers, leagueColor, "G"),
                _buildStatsList(assists, leagueColor, "A"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsList(List<PlayerStat> stats, Color leagueColor, String unit) {
    if (stats.isEmpty) {
      return Center(
        child: Text(
          "NO DATA AVAILABLE",
          style: GoogleFonts.vt323(color: Colors.white38, fontSize: 14.sp),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final player = stats[index];
        return Container(
          margin: EdgeInsets.symmetric(vertical: 4.h),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: leagueColor.withOpacity(0.5), width: 2.w)),
          ),
          child: Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: CorsUtils.proxify(player.imageUrl),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.white10,
                    child: Center(
                      child: SizedBox(
                        width: 12.w,
                        height: 12.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 1,
                          color: leagueColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => CachedNetworkImage(
                    imageUrl: CorsUtils.proxify("https://ui-avatars.com/api/?name=${Uri.encodeComponent(player.name)}&background=0D0D0D&color=fff&size=128"),
                    placeholder: (context, url) => Container(color: Colors.white10),
                    errorWidget: (context, url, error) => Container(
                      padding: EdgeInsets.all(2.w),
                      child: Opacity(
                        opacity: 0.2,
                        child: Image.network(
                          "https://a.espncdn.com/i/headshots/nophoto.png",
                          color: leagueColor,
                          colorBlendMode: BlendMode.srcIn,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              SizedBox(
                width: 24.w,
                child: Text(player.rank, style: GoogleFonts.vt323(color: leagueColor, fontSize: 12.sp)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name.toUpperCase(),
                      style: GoogleFonts.orbitron(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      player.team,
                      style: GoogleFonts.vt323(color: Colors.white54, fontSize: 10.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                player.stat,
                style: GoogleFonts.orbitron(color: leagueColor, fontSize: 13.sp, fontWeight: FontWeight.w900),
              ),
              SizedBox(width: 4.w),
              Text(unit, style: GoogleFonts.vt323(color: Colors.white38, fontSize: 10.sp)),
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
                ).copyWith(fontFamilyFallback: [
                  'Hiragino Kaku Gothic ProN',
                  'MS Gothic',
                  'Noto Sans JP',
                  'sans-serif'
                ]),
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
          ).copyWith(fontFamilyFallback: [
            'Hiragino Kaku Gothic ProN',
            'MS Gothic',
            'Noto Sans JP',
            'sans-serif'
          ]),
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
            child: Row(
              children: [
                _buildTeamLogo(team['logo'] ?? "", team['name']?.toString() ?? ""),
                SizedBox(width: 8.w),
                Expanded(
                  child: _cell(team['name'].toString().toUpperCase(), null,
                      align: TextAlign.left, color: Colors.white, isBold: isTop),
                ),
              ],
            ),
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

  Widget _buildTeamLogo(String logoUrl, String teamName) {
    final proxiedUrl = CorsUtils.proxify(logoUrl);
    final isSvg = logoUrl.toLowerCase().contains('.svg');

    if (isSvg) {
      return SvgPicture.network(
        proxiedUrl,
        width: 18.w,
        height: 18.w,
        placeholderBuilder: (context) => Container(width: 18.w, height: 18.w, color: Colors.white10),
      );
    }

    return CachedNetworkImage(
      imageUrl: proxiedUrl,
      width: 18.w,
      height: 18.w,
      placeholder: (context, url) => Container(width: 18.w, height: 18.w, color: Colors.white10),
      errorWidget: (context, url, error) => CachedNetworkImage(
        imageUrl: CorsUtils.proxify("https://ui-avatars.com/api/?name=${Uri.encodeComponent(teamName)}&background=0D0D0D&color=fff&rounded=true"),
        errorWidget: (context, url, error) => Icon(Icons.shield, size: 16.sp, color: Colors.white24),
      ),
    );
  }
}
