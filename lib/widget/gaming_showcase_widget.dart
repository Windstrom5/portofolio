import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../service/showcase_scraper.dart';

class GamingShowcaseWidget extends StatefulWidget {
  final VoidCallback onClose;

  const GamingShowcaseWidget({
    super.key,
    required this.onClose,
  });

  @override
  State<GamingShowcaseWidget> createState() => _GamingShowcaseWidgetState();
}

class _GamingShowcaseWidgetState extends State<GamingShowcaseWidget>
    with SingleTickerProviderStateMixin {
  ShowcaseData? _data;
  bool _isLoading = true;
  String? _error;
  int _activeTab = 0; // 0 = Steam, 1 = MAL
  late AnimationController _pulseController;
  int _favCharIndex = 0;
  Timer? _charRotateTimer;

  // ─── Color Palette ─────────────────────────────────────────
  static const Color _bgDarker = Color(0xFF171A21);
  static const Color _steamAccent = Color(0xFF66C0F4);
  static const Color _malAccent = Color(0xFF4FC1E4);
  static const Color _textMuted = Color(0xFF8F98A0);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fetchData();
    _charRotateTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _data?.mal?.favoriteCharacters.isNotEmpty == true) {
        setState(() {
          _favCharIndex =
              (_favCharIndex + 1) % _data!.mal!.favoriteCharacters.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _charRotateTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ShowcaseScraper.fetchShowcase();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Color get _accentColor => _activeTab == 0 ? _steamAccent : _malAccent;

  Future<void> _launchSteamGame(String appId) async {
    final url = 'steam://run/$appId';
    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url);
      } else {
        await launchUrlString('https://store.steampowered.com/app/$appId');
      }
    } catch (_) {}
  }

  // ╔══════════════════════════════════════════════════════════╗
  // ║  BUILD                                                   ║
  // ╚══════════════════════════════════════════════════════════╝
  @override
  Widget build(BuildContext context) {
    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Column(
            children: [
              // ─── macOS-style Title Bar ──────────────────
              _buildTitleBar(),
              // ─── Tab Bar ────────────────────────────────
              _buildTabBar(),
              // ─── Content ────────────────────────────────
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _error != null
                        ? _buildErrorState()
                        : _buildDashboard(),
              ),
              // ─── Footer ─────────────────────────────────
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ╔══════════════════════════════════════════════════════════╗
  // ║  TITLE BAR (Pic 3 macOS style)                          ║
  // ╚══════════════════════════════════════════════════════════╝
  Widget _buildTitleBar() {
    return Container(
      height: 38.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: _bgDarker.withOpacity(0.95),
        border:
            Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          // Traffic light dots
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: 12.r,
              height: 12.r,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5F57),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            width: 12.r,
            height: 12.r,
            decoration: const BoxDecoration(
              color: Color(0xFFFFBD2E),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            width: 12.r,
            height: 12.r,
            decoration: const BoxDecoration(
              color: Color(0xFF28C840),
              shape: BoxShape.circle,
            ),
          ),
          // Center title
          Expanded(
            child: Center(
              child: Text(
                "user@windstrom5: ~/My Library",
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white60,
                  fontSize: 11.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 50.w),
        ],
      ),
    );
  }

  // ╔══════════════════════════════════════════════════════════╗
  // ║  TAB BAR                                                ║
  // ╚══════════════════════════════════════════════════════════╝
  Widget _buildTabBar() {
    return Container(
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      color: _bgDarker,
      child: Row(
        children: [
          _buildTab(0, "STEAM_OS", FontAwesomeIcons.steam),
          _buildTab(1, "MAL_GRID", Icons.grid_view_rounded),
          const Spacer(),
          IconButton(
            onPressed: _fetchData,
            icon: Icon(Icons.refresh_rounded,
                color: Colors.white38, size: 18.sp),
            tooltip: "Refresh data",
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    final isActive = _activeTab == index;
    final color = index == 0 ? _steamAccent : _malAccent;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? color : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            FaIcon(icon,
                size: 12.sp,
                color: isActive ? color : Colors.white38),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.notoSans(
                color: isActive ? color : Colors.white38,
                fontSize: 11.sp,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ╔══════════════════════════════════════════════════════════╗
  // ║  DASHBOARD                                              ║
  // ╚══════════════════════════════════════════════════════════╝
  Widget _buildDashboard() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
      child: _activeTab == 0 ? _buildSteamContent() : _buildMalContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
          SizedBox(height: 12.h),
          Text("ESTABLISHING_LINK...",
              style: GoogleFonts.jetBrainsMono(
                  color: _accentColor, fontSize: 11.sp)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber, color: Colors.redAccent, size: 32.sp),
          SizedBox(height: 8.h),
          Text("LINK_FAILED",
              style: GoogleFonts.jetBrainsMono(
                  color: Colors.redAccent, fontSize: 12.sp)),
          SizedBox(height: 4.h),
          Text(_error ?? "",
              style: GoogleFonts.notoSans(
                  color: _textMuted, fontSize: 9.sp),
              textAlign: TextAlign.center),
          SizedBox(height: 12.h),
          TextButton.icon(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh),
            label: Text("RETRY",
                style: GoogleFonts.notoSans(fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(foregroundColor: _accentColor),
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════════════════════════════════╗
  // ║  STEAM CONTENT                                          ║
  // ╚══════════════════════════════════════════════════════════╝
  Widget _buildSteamContent() {
    final steam = _data?.steam;
    if (steam == null) return const SizedBox();
    final isOnline = steam.onlineState == 'online' ||
        steam.onlineState == 'in-game';
    final statusColor = steam.onlineState == 'in-game'
        ? const Color(0xFF90BA3C)
        : (isOnline ? _steamAccent : Colors.grey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile card
        Container(
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: statusColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 64.r,
                height: 64.r,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  border:
                      Border.all(color: statusColor.withOpacity(0.6), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.network(steam.avatarUrl, fit: BoxFit.cover),
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(steam.personaName.toUpperCase(),
                      style: GoogleFonts.notoSans(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(steam.stateMessage.toUpperCase(),
                          style: GoogleFonts.notoSans(
                              color: statusColor, fontSize: 10.sp)),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              _statColumn(
                  "${steam.totalPlaytime.toInt()}", "HOURS", _steamAccent),
              SizedBox(width: 20.w),
              _statColumn("${steam.games.length}", "GAMES", _steamAccent),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        // Top Games
        Text("TOP GAMES",
            style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 12.h),
        ...steam.games.take(5).map((game) => _buildGameItem(game)),
      ],
    );
  }

  Widget _statColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.notoSans(
                color: color,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: GoogleFonts.notoSans(
                color: _textMuted, fontSize: 8.sp)),
      ],
    );
  }

  Widget _buildGameItem(SteamGame game) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchSteamGame(game.appId),
        hoverColor: _steamAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6.r),
        child: Container(
          margin: EdgeInsets.only(bottom: 6.h),
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: Image.network(game.imageUrl,
                    width: 90.w, height: 42.h, fit: BoxFit.cover),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(game.name,
                        style: GoogleFonts.notoSans(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500)),
                    Text("${game.playtimeTotal.toInt()} hours played",
                        style: GoogleFonts.notoSans(
                            color: _textMuted, fontSize: 9.sp)),
                  ],
                ),
              ),
              Icon(Icons.play_arrow_rounded,
                  color: _steamAccent, size: 22.sp),
            ],
          ),
        ),
      ),
    );
  }

  // ╔══════════════════════════════════════════════════════════╗
  // ║  MAL CONTENT                                            ║
  // ╚══════════════════════════════════════════════════════════╝
  Widget _buildMalContent() {
    final mal = _data?.mal;
    if (mal == null) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Header
        Text(mal.username.toUpperCase(),
            style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold)),
        SizedBox(height: 16.h),
        // Stats Row
        Row(
          children: [
            _malStatBox("COMPLETED", "${mal.animeCompleted}", _malAccent),
            SizedBox(width: 8.w),
            _malStatBox(
                "EPISODES", "${mal.episodesWatched}", Colors.purpleAccent),
            SizedBox(width: 8.w),
            _malStatBox(
                "MEAN SCORE", mal.meanScore.toStringAsFixed(1), Colors.amber),
          ],
        ),
        SizedBox(height: 24.h),
        // Favorite Anime
        Text("FAVORITE ANIME",
            style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 12.h),
        SizedBox(
          height: 140.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: mal.favoriteAnime.length,
            itemBuilder: (context, index) {
              final anime = mal.favoriteAnime[index];
              return Container(
                width: 90.w,
                margin: EdgeInsets.only(right: 10.w),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: Image.network(anime.imageUrl,
                            fit: BoxFit.cover, width: 90.w),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(anime.title,
                        style: GoogleFonts.notoSans(
                            color: Colors.white54, fontSize: 8.sp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          ),
        ),
        // Favorite Characters
        if (mal.favoriteCharacters.isNotEmpty) ...[
          SizedBox(height: 24.h),
          Text("FAVORITE CHARACTERS",
              style: GoogleFonts.notoSans(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 12.h),
          SizedBox(
            height: 140.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mal.favoriteCharacters.length,
              itemBuilder: (context, index) {
                final char = mal.favoriteCharacters[index];
                return Container(
                  width: 90.w,
                  margin: EdgeInsets.only(right: 10.w),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6.r),
                          child: Image.network(char.imageUrl,
                              fit: BoxFit.cover, width: 90.w),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(char.name,
                          style: GoogleFonts.notoSans(
                              color: Colors.white54, fontSize: 8.sp),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _malStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.notoSans(
                    color: color,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900)),
            SizedBox(height: 2.h),
            Text(label,
                style: GoogleFonts.notoSans(
                    color: _textMuted, fontSize: 8.sp)),
          ],
        ),
      ),
    );
  }

  // ╔══════════════════════════════════════════════════════════╗
  // ║  FOOTER                                                 ║
  // ╚══════════════════════════════════════════════════════════╝
  Widget _buildFooter() {
    final lastFetch = _data?.fetchedAt ?? DateTime.now();
    final timeStr =
        "${lastFetch.hour.toString().padLeft(2, '0')}:${lastFetch.minute.toString().padLeft(2, '0')}";
    return Container(
      height: 32.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: _bgDarker,
        border:
            Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Text("SYNC_STATUS: STABLE",
              style: GoogleFonts.notoSans(
                  color: _textMuted.withOpacity(0.4), fontSize: 9.sp)),
          const Spacer(),
          Text("LAST_UPDATED: $timeStr",
              style: GoogleFonts.notoSans(
                  color: _textMuted.withOpacity(0.3), fontSize: 9.sp)),
        ],
      ),
    );
  }
}
