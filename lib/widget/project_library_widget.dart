import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ─── Data Model ──────────────────────────────────────────────
class LibraryItem {
  final String title;
  final String description;
  final String longDescription;
  final String genre;
  final List<String> tags;
  final String developer;
  final String releaseDate;
  final IconData icon;
  final Color accentColor;
  final int mainIndex;
  final double rating;
  final String version;
  final String bannerAsset;
  final List<String> features;
  final String esrbRating;

  LibraryItem({
    required this.title,
    required this.description,
    required this.longDescription,
    required this.genre,
    required this.tags,
    required this.developer,
    required this.releaseDate,
    required this.icon,
    required this.accentColor,
    required this.mainIndex,
    required this.rating,
    required this.version,
    required this.bannerAsset,
    required this.features,
    this.esrbRating = "E",
  });
}

class ProjectLibraryWidget extends StatefulWidget {
  final Function(int) onLaunchProject;
  final int currentActiveIndex;
  final List<int> runningGameIds;
  final Function(int)? onStopProject;
  final Map<int, int> playTimeSeconds;
  final VoidCallback onClose;

  const ProjectLibraryWidget({
    super.key,
    required this.onLaunchProject,
    required this.currentActiveIndex,
    required this.runningGameIds,
    required this.onClose,
    this.onStopProject,
    this.playTimeSeconds = const {},
  });

  @override
  State<ProjectLibraryWidget> createState() => _ProjectLibraryWidgetState();
}

class _ProjectLibraryWidgetState extends State<ProjectLibraryWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  LibraryItem? _selectedItem;
  String _activeNav = 'STORE';
  String? _activeGenre;
  int? _hoveredIndex;
  late final ScrollController _sidebarScrollController;

  // Persistence (mocked in state for now)
  final Set<int> _ownedGameIndices = {8, 9, 12, 15, 16, 17, 18, 19}; // Pre-installed games
  final Set<int> _wishlistIndices = {};

  final bool _sidebarCollapsed = false;

  // ─── Color Palette (Steam-inspired) ────────────────────────
  static const Color _bgDark = Color(0xFF1B2838);
  static const Color _bgDarker = Color(0xFF171A21);
  static const Color _bgCard = Color(0xFF16202D);
  static const Color _accent = Color(0xFF66C0F4);
  static const Color _accentGreen = Color(0xFF75b022); // Steam Green
  static const Color _accentGreenBright = Color(0xFFBEEE11); // Steam Highlight
  static const Color _textMuted = Color(0xFF8F98A0);
  static const Color _bgDetailBar = Color(0xFF213245);

  // ─── Project Data ──────────────────────────────────────────
  final List<LibraryItem> _projects = [
    LibraryItem(
      title: "POKER",
      description: "5-Card Draw with AI Maid",
      longDescription:
          "Step into the high-stakes world of Cyber-Poker. Challenge our advanced autonomous dealer in a 5-card draw format optimized for data-rich HUD environments. Featuring real-time probability analysis, behavioral simulation, and dynamic betting systems.",
      genre: "Strategy",
      tags: ["Strategy", "Casino", "Card Game", "Singleplayer"],
      developer: "WINDSTROM_INDUSTRIES",
      releaseDate: "Mar 30, 2026",
      icon: FontAwesomeIcons.diamond,
      accentColor: const Color(0xFFFF5555),
      mainIndex: 8,
      rating: 4.8,
      version: "v2.1.0",
      bannerAsset: 'assets/banner_poker.png',
      features: [
        "AI-powered dealer with adaptive difficulty",
        "5-card draw format with full HUD overlay",
        "Real-time probability display",
        "Multiple betting rounds",
      ],
    ),
    LibraryItem(
      title: "CHESS",
      description: "Grandmaster HUD Edition",
      longDescription:
          "A tactical chess engine built with a focus on visual feedback and strategic overlays. Analyze every move with integrated heatmaps and threat detection. Perfect for grandmasters and novices alike.",
      genre: "Board Games",
      tags: ["Board", "Tactical", "Strategy", "Multiplayer"],
      developer: "WINDSTROM_LABS",
      releaseDate: "Jan 15, 2026",
      icon: FontAwesomeIcons.chess,
      accentColor: const Color(0xFFF1FA8C),
      mainIndex: 9,
      rating: 4.9,
      version: "v1.4.2",
      bannerAsset: 'assets/banner_chess.png',
      features: [
        "Full chess engine with legal move validation",
        "Piece capture tracking and history",
        "Checkmate & stalemate detection",
        "Clean, responsive board UI",
      ],
    ),
    LibraryItem(
      title: "MINESWEEPER",
      description: "Cybernetic Grid Analysis",
      longDescription:
          "Re-engineered classic logic puzzle. Navigate through a high-frequency sensor field to neutralize kinetic threats. Features procedural difficulty scaling and retro CRT aesthetic.",
      genre: "Puzzle",
      tags: ["Puzzle", "Logic", "Classic", "Singleplayer"],
      developer: "HUD_WORKS",
      releaseDate: "Nov 20, 2025",
      icon: FontAwesomeIcons.bomb,
      accentColor: const Color(0xFF50FA7B),
      mainIndex: 12,
      rating: 4.5,
      version: "v0.9.3",
      bannerAsset: 'assets/banner_minesweeper.png',
      features: [
        "Classic minesweeper with flag system",
        "Multiple grid sizes",
        "Retro CRT scanline overlay",
        "Win/loss detection",
      ],
    ),
    LibraryItem(
      title: "TIC-TAC-TOE",
      description: "Minimalist Neon Strategy",
      longDescription:
          "The absolute minimum viable strategy product. Optimized for low-latency neural interfaces and quick-reflex tactical decision making with smooth neon animations.",
      genre: "Strategy",
      tags: ["Strategy", "Minimalist", "Casual", "Singleplayer"],
      developer: "WINDSTROM_CORE",
      releaseDate: "Jun 10, 2025",
      icon: FontAwesomeIcons.xmark,
      accentColor: const Color(0xFFBD93F9),
      mainIndex: 6,
      rating: 4.2,
      version: "v1.0.1",
      bannerAsset: 'assets/banner_tictactoe.png',
      features: [
        "Classic 3x3 grid gameplay",
        "Two-player turn system",
        "Win/draw detection",
        "Neon-styled visual effects",
      ],
    ),
    LibraryItem(
      title: "ROCK PAPER SCISSORS",
      description: "Visual Novel Hybrid",
      longDescription:
          "A narrative-driven decision game where every choice is a toss. Experience the drama of probability across multiple dimensions of rock, paper, and scissors with maid commentary.",
      genre: "Strategy",
      tags: ["Visual Novel", "Casual", "Comedy", "Singleplayer"],
      developer: "STORY_DRIVE",
      releaseDate: "Aug 5, 2025",
      icon: FontAwesomeIcons.handBackFist,
      accentColor: const Color(0xFFFFB86C),
      mainIndex: 7,
      rating: 4.0,
      version: "v1.1.2",
      bannerAsset: 'assets/banner_rps.png',
      features: [
        "Rock, Paper, Scissors with AI opponent",
        "Maid character commentary",
        "Score tracking system",
        "Animated hand gestures",
      ],
    ),
    LibraryItem(
      title: "FARAWAY LANDS",
      description: "Board Game Adventure",
      longDescription:
          "Advanced procedural world-building board game engine. Explore vast digital frontiers and collect cards in an infinite horizon of adventure and strategy.",
      genre: "Board Games",
      tags: ["Simulator", "Open World", "Board", "Adventure"],
      developer: "GEO_GEN_SYSTEMS",
      releaseDate: "2025-ALPHA",
      icon: FontAwesomeIcons.mountain,
      accentColor: const Color(0xFF8BE9FD),
      mainIndex: 11,
      rating: 4.7,
      version: "v0.5.0",
      bannerAsset: 'assets/banner_faraway.png',
      features: [
        "Card-based scoring system",
        "Strategic placement mechanics",
        "Beautiful landscape artwork",
        "Solo & multiplayer modes",
      ],
    ),
    LibraryItem(
      title: "QUERY FROM THE VOID",
      description: "Eldritch SQL Detective Game",
      longDescription:
          "Decode the whispers of the ancient ones. Use the archival SQL terminal to uncover hidden patterns, track cult activities, and prevent the awakening of the Great Old One. Manage your Sanity as you uncover truths that were meant to stay buried.",
      genre: "Mystery",
      tags: ["Detective", "SQL", "Horror", "Singleplayer"],
      developer: "MISKATONIC_INVESTIGATIONS",
      releaseDate: "Mar 31, 2026",
      icon: FontAwesomeIcons.magnifyingGlass,
      accentColor: const Color(0xFF50FA7B),
      mainIndex: 15,
      rating: 5.0,
      version: "v1.0.0-BETA",
      bannerAsset: 'assets/banner_eldritch.png',
      features: [
        "Simulated SQL terminal for deep investigation",
        "Sanity and Doom resource management",
        "Multiple endings based on data discovery",
        "Moody, Lovecraftian noir atmosphere",
      ],
    ),
    LibraryItem(
      title: "DOOM (1993)",
      description: "The Father of First-Person Shooters",
      longDescription:
          "The game that changed everything. Fight your way through the UAC moon base on Phobos in the legendary first-person shooter. Rip and tear until it is done.",
      genre: "FPS",
      tags: ["Classic", "Action", "Horror", "Retro"],
      developer: "id Software",
      releaseDate: "Dec 10, 1993",
      icon: FontAwesomeIcons.skullCrossbones,
      accentColor: const Color(0xFFB21818),
      mainIndex: 16,
      rating: 5.0,
      version: "v1.9-SHAREWARE",
      bannerAsset: 'assets/banner_doom.png',
      features: [
        "Iconic 3D Level Design",
        "Hidden Secret Rooms",
        "Keycard Progression System",
        "BFG-9000 Firepower",
      ],
    ),
    LibraryItem(
      title: "SHIFT: NEON PULSE",
      description: "NFS-inspired Pseudo-3D Racing",
      longDescription:
          "Burn rubber in this high-octane tribute to classic arcade racers. Featuring a custom pseudo-3D engine with curves and elevation, dynamic traffic, and nitro-boosted pulses of speed across synthwave cityscapes.",
      genre: "Racing",
      tags: ["Racing", "Synthwave", "Fast-Paced", "3D"],
      developer: "LIMIT_BREAK_STUDIOS",
      releaseDate: "APR 2026",
      icon: FontAwesomeIcons.car,
      accentColor: const Color(0xFF00FFFF),
      mainIndex: 17,
      rating: 4.9,
      version: "v2.0.0",
      bannerAsset: 'assets/banner_racer.png',
      features: [
        "Pseudo-3D Segment-based Road Engine",
        "Dynamic Traffic & Weaving mechanics",
        "Tachometer HUD & Nitro systems",
        "Parallax Environment Layers",
      ],
    ),
    LibraryItem(
      title: "ABYSSAL REMNANT",
      description: "Dark Souls-style First-Person Combat",
      longDescription:
          "The Abyss calls back. Engage in high-stakes, first-person pseudo-3D combat against relentless guardians. Master stamina management, attack telegraphing, and defensive maneuvers in this dark fantasy survival challenge.",
      genre: "RPG",
      tags: ["RPG", "First-Person", "Souls-like", "Strategy"],
      developer: "ABYSS_DEV",
      releaseDate: "APR 2026",
      icon: FontAwesomeIcons.scroll,
      accentColor: const Color(0xFFA020F0),
      mainIndex: 18,
      rating: 5.0,
      version: "v2.0.1",
      bannerAsset: 'assets/banner_void.png',
      features: [
        "Stamina-based Combat System",
        "Telegraphed Boss Mechanics",
        "Multi-phase Boss Encounters",
        "Authentic Souls HUD elements",
      ],
    ),
    LibraryItem(
      title: "ROOT PROTOCOL",
      description: "Linux Terminal Mystery Investigation",
      longDescription:
          "Infiltrate NexaCorp's internal systems to investigate a massive data breach. Use authentic-feeling terminal tools like nmap, sqlmap, and aircrack-ng to gather evidence, crack passwords, and uncover the real culprit in this hacking simulation.",
      genre: "Simulator",
      tags: ["Simulation", "Mystery", "Hacking", "Detective"],
      developer: "ROOT_ACCESS",
      releaseDate: "APR 2026",
      icon: FontAwesomeIcons.code,
      accentColor: const Color(0xFF00FF00),
      mainIndex: 19,
      rating: 5.0,
      version: "v2.0.0",
      bannerAsset: 'assets/banner_root_protocol.png',
      features: [
        "Interactive Linux Prompt & Toolset",
        "Simulated Multi-Server Investigation",
        "Multi-stage Evidence Board",
        "Authentic Pentesting Logic",
      ],
    ),
  ];

  List<LibraryItem> get _filteredProjects {
    if (_activeGenre == null) return _projects;
    return _projects
        .where((p) =>
            p.genre == _activeGenre ||
            p.tags.any((t) => t.toLowerCase() == _activeGenre!.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _sidebarScrollController = ScrollController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sidebarScrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1B2838),
      child: Column(
        children: [
          _buildNavBar(),
          Expanded(
            child: Row(
              children: [
                if (!_sidebarCollapsed) _buildSidebar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildMainContent(),
                  ),
                ),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      color: _bgDarker,
      child: Row(
        children: [
          _navTab("STORE", Icons.store),
          _navTab("LIBRARY", Icons.library_books),
          _navTab("DEV LOG", Icons.terminal),
          _navTab("WINDSTROM5", Icons.person),
          const Spacer(),
          if (_selectedItem != null)
            IconButton(
              onPressed: () => setState(() => _selectedItem = null),
              icon: Icon(Icons.arrow_back_rounded,
                  color: Colors.white54, size: 18.sp),
              tooltip: "Back to Store",
            ),
        ],
      ),
    );
  }

  Widget _navTab(String label, IconData icon) {
    final isActive = _activeNav == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeNav = label;
          _selectedItem = null;
          _activeGenre = null;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? _accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13.sp,
                color: isActive ? Colors.white : Colors.white54),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.notoSans(
                color: isActive ? Colors.white : Colors.white54,
                fontSize: 12.sp,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_selectedItem != null) return _buildDetailPage(_selectedItem!);
    
    switch (_activeNav) {
      case 'LIBRARY':
        return _buildLibraryView();
      case 'DEV LOG':
        return _buildCommunityView();
      case 'WINDSTROM5':
        return _buildProfileView();
      default:
        if (_activeGenre == 'MY WISHLIST') return _buildWishlistView();
        return _buildStoreHome();
    }
  }

  Widget _buildLibraryView() {
    if (_activeGenre == 'MY WISHLIST') return _buildWishlistView();
    
    final owned = _projects.where((p) => _ownedGameIndices.contains(p.mainIndex)).toList();
    if (owned.isEmpty) {
      return Center(child: Text("NO GAMES OWNED", style: GoogleFonts.vt323(color: _textMuted, fontSize: 24.sp)));
    }
    return _buildGameGrid(owned, "MY LIBRARY");
  }

  Widget _buildWishlistView() {
    final wish = _projects.where((p) => _wishlistIndices.contains(p.mainIndex)).toList();
    if (wish.isEmpty) {
      return Center(child: Text("WISHLIST IS EMPTY", style: GoogleFonts.vt323(color: _textMuted, fontSize: 24.sp)));
    }
    return _buildGameGrid(wish, "MY WISHLIST");
  }

  Widget _buildCommunityView() {
    final devLogs = [
      {
        "game": "QUERY FROM THE VOID",
        "update": "Patch 1.0.4: Initialized Sanity-check buffers and fixed spatial audio leaks in the Abyss.",
        "timestamp": "2026-03-31 08:30:15",
        "status": "STABLE"
      },
      {
        "game": "POKER",
        "update": "Refactored AI decision trees to prioritize bluffing when master is low on credits.",
        "timestamp": "2026-03-30 14:15:22",
        "status": "OPTIMIZED"
      },
      {
        "game": "CHESS",
        "update": "Migrated engine to WebWorkers to prevent UI thread blocking during deep search (depth 12).",
        "timestamp": "2026-03-28 11:05:00",
        "status": "MERGED"
      },
      {
        "game": "CORE_SYSTEM",
        "update": "Implemented Multi-App Windowing kernel. Handlers now support concurrent rendering stacks.",
        "timestamp": "2026-03-27 09:00:00",
        "status": "DEPLOYED"
      },
      {
        "game": "ELDRITCH_SHADER",
        "update": "Experimental: Added volumetric void-particles to eldritch encounters. Performance hit: +12ms.",
        "timestamp": "2026-03-26 18:00:00",
        "status": "EXPERIMENTAL"
      },
    ];

    final filteredLogs = _activeGenre == null 
        ? devLogs 
        : devLogs.where((log) => log["status"] == _activeGenre).toList();

    return Container(
      padding: EdgeInsets.all(24.r),
      color: Colors.black.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal, color: _accent, size: 20.sp),
              SizedBox(width: 12.w),
              Text(
                "PROJECT_ARCHIVE // DEV_LOGS",
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Expanded(
            child: ListView.builder(
              itemCount: filteredLogs.length,
              itemBuilder: (context, index) {
                final log = filteredLogs[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    border: Border(
                      left: BorderSide(color: _accent.withOpacity(0.5), width: 2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            log["game"]!,
                            style: GoogleFonts.vt323(
                              color: _accent,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                            child: Text(
                              log["status"]!,
                              style: GoogleFonts.vt323(color: _accent, fontSize: 10.sp),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        log["update"]!,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white70,
                          fontSize: 12.sp,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        "[TIMESTAMP: ${log["timestamp"]}]",
                        style: GoogleFonts.vt323(
                          color: _textMuted.withOpacity(0.6),
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    if (_activeGenre == 'INVENTORY') return _buildInventoryView();
    if (_activeGenre == 'BADGES') return _buildBadgesView();
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(radius: 50.r, backgroundColor: _accent, child: Icon(Icons.person, size: 50.sp, color: Colors.white)),
          SizedBox(height: 16.h),
          Text("WINDSTROM5", style: GoogleFonts.orbitron(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold)),
          Text("Level 42 Archival Specialist", style: GoogleFonts.vt323(color: _accent, fontSize: 16.sp)),
          SizedBox(height: 32.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statBox("GAMES", _ownedGameIndices.length.toString()),
              SizedBox(width: 24.w),
              _statBox("ACHIEVEMENTS", "154"),
              SizedBox(width: 24.w),
              _statBox("FRIENDS", "0"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryView() {
    final items = [
      {"name": "Neural Link v2.0", "rarity": "LEGENDARY", "icon": Icons.psychology},
      {"name": "Data Shard: Abyss", "rarity": "RARE", "icon": Icons.usb},
      {"name": "Cyber-Deck 404", "rarity": "UNCOMMON", "icon": Icons.developer_board},
      {"name": "Void Token", "rarity": "BASIC", "icon": Icons.generating_tokens},
    ];

    return Container(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("PLAYER INVENTORY", Icons.inventory_2_outlined),
          SizedBox(height: 20.h),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 12.w, mainAxisSpacing: 12.h, childAspectRatio: 1),
              itemCount: items.length,
              itemBuilder: (context, idx) {
                final item = items[idx];
                return Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4.r)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item["icon"] as IconData, color: _accent, size: 24.sp),
                      SizedBox(height: 8.h),
                      Text(item["name"] as String, 
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSans(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w600)),
                      Text(item["rarity"] as String, 
                          style: GoogleFonts.notoSans(color: _textMuted, fontSize: 8.sp, letterSpacing: 1.2)),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBadgesView() {
    final badges = [
      {"title": "EARLY ACCESS", "desc": "WINDSTROM_INDUSTRIES Pioneer", "color": Colors.orangeAccent},
      {"title": "GRANDMASTER CODE", "desc": "Completed all Chess puzzles", "color": Colors.cyanAccent},
      {"title": "VOID HUNTER", "desc": "Found three secret Eldritch shaders", "color": Colors.purpleAccent},
    ];

    return Container(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("VIRTUAL BADGES", Icons.military_tech_outlined),
          SizedBox(height: 20.h),
          Expanded(
            child: ListView.builder(
              itemCount: badges.length,
              itemBuilder: (context, idx) {
                final badge = badges[idx];
                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    border: Border(left: BorderSide(color: badge["color"] as Color, width: 3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.stars, color: badge["color"] as Color, size: 20.sp),
                      SizedBox(width: 16.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(badge["title"] as String, 
                              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                          Text(badge["desc"] as String, 
                              style: GoogleFonts.notoSans(color: _textMuted, fontSize: 9.sp)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _statBox(String label, String val) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.orbitron(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.notoSans(color: _textMuted, fontSize: 10.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _accent, size: 18.sp),
        SizedBox(width: 10.w),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
      ],
    );
  }

  Widget _buildGameGrid(List<LibraryItem> items, String title) {
    return Container(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title, Icons.grid_view),
          SizedBox(height: 20.h),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 0.8,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isRunning = widget.runningGameIds.contains(item.mainIndex);
                return _buildStoreCard(item, isRunning: isRunning);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 200.w,
      decoration: BoxDecoration(
        color: _bgDark.withOpacity(0.5),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _activeNav == 'LIBRARY' 
            ? _buildLibrarySidebar() 
            : _activeNav == 'DEV LOG'
                ? _buildDevLogSidebar()
                : _activeNav == 'WINDSTROM5'
                    ? _buildProfileSidebar()
                    : _buildStoreSidebar(),
      ),
    );
  }

  Widget _buildDevLogSidebar() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      key: const ValueKey('devlog_sidebar'),
      padding: EdgeInsets.symmetric(vertical: 16.h),
      children: [
        _sidebarEntry("ARCHIVE HOME", Icons.history, _activeGenre == null,
            onTap: () => setState(() => _activeGenre = null)),
        _sidebarEntry("STABLE", Icons.check_circle_outline, _activeGenre == 'STABLE',
            onTap: () => setState(() => _activeGenre = 'STABLE')),
        _sidebarEntry("EXPERIMENTAL", FontAwesomeIcons.flask, _activeGenre == 'EXPERIMENTAL',
            onTap: () => setState(() => _activeGenre = 'EXPERIMENTAL')),
      ],
    );
  }

  Widget _buildProfileSidebar() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      key: const ValueKey('profile_sidebar'),
      padding: EdgeInsets.symmetric(vertical: 16.h),
      children: [
        _sidebarEntry("OVERVIEW", Icons.account_circle_outlined, _activeGenre == null,
            onTap: () => setState(() => _activeGenre = null)),
        _sidebarEntry("INVENTORY", Icons.inventory_2_outlined, _activeGenre == 'INVENTORY',
            onTap: () => setState(() => _activeGenre = 'INVENTORY')),
        _sidebarEntry("VIRTUAL BADGES", Icons.military_tech_outlined, _activeGenre == 'BADGES',
            onTap: () => setState(() => _activeGenre = 'BADGES')),
      ],
    );
  }

  Widget _buildStoreSidebar() {
    final genres = ["Strategy", "Board Games", "Puzzle", "Mystery", "Action", "Racing", "RPG", "Simulator"];
    return Theme(
      data: Theme.of(context).copyWith(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(_accent.withOpacity(0.2)),
          radius: Radius.circular(10.r),
          thickness: WidgetStateProperty.all(4.r),
        ),
      ),
      child: Scrollbar(
        controller: _sidebarScrollController,
        thumbVisibility: true,
        interactive: true, // Re-enabled for manual dragging
        child: ListView(
          physics: const BouncingScrollPhysics(),
          controller: _sidebarScrollController,
          key: const ValueKey('store_sidebar'),
          padding: EdgeInsets.fromLTRB(0, 16.h, 0, 20.h), // Reduced bottom padding to avoid clipping
          children: [
            _sidebarEntry("STORE HOME", Icons.storefront, _activeGenre == null,
                onTap: () => setState(() {
                      _activeGenre = null;
                      _selectedItem = null;
                    })),
            _sidebarEntry("MY WISHLIST", Icons.favorite_border, _activeGenre == 'MY WISHLIST',
                onTap: () => setState(() {
                      _activeGenre = 'MY WISHLIST';
                      _selectedItem = null;
                    })),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 10.h),
              child: Text(
                "GENRES",
                style: GoogleFonts.notoSans(
                  color: _textMuted.withOpacity(0.5),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...genres.map((g) {
              final isActive = _activeGenre == g;
              IconData gIcon;
              switch (g) {
                case "Strategy": gIcon = Icons.grid_view; break;
                case "Board Games": gIcon = Icons.table_chart; break;
                case "Puzzle": gIcon = Icons.extension; break;
                case "Mystery": gIcon = Icons.search; break;
                case "Action": gIcon = FontAwesomeIcons.gun; break;
                case "Racing": gIcon = FontAwesomeIcons.car; break;
                case "RPG": gIcon = FontAwesomeIcons.scroll; break;
                case "Simulator": gIcon = FontAwesomeIcons.code; break;
                default: gIcon = Icons.category;
              }
              return _sidebarEntry(g.toUpperCase(), gIcon, isActive, onTap: () {
                setState(() {
                  _activeGenre = isActive ? null : g;
                  _selectedItem = null;
                });
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLibrarySidebar() {
    final ownedGames = _projects.where((p) => _ownedGameIndices.contains(p.mainIndex)).toList();
    return ListView(
      physics: const BouncingScrollPhysics(),
      key: const ValueKey('library_sidebar'),
      padding: EdgeInsets.symmetric(vertical: 16.h),
      children: [
        _sidebarEntry("LIBRARY HOME", Icons.home_filled, _activeGenre == null && _selectedItem == null,
            onTap: () => setState(() {
                  _activeGenre = null;
                  _selectedItem = null;
                })),
        _sidebarEntry("MY WISHLIST", Icons.favorite_border, _activeGenre == 'MY WISHLIST',
            onTap: () => setState(() {
                  _activeGenre = 'MY WISHLIST';
                  _selectedItem = null;
                })),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 10.h),
          child: Text(
            "YOUR GAMES",
            style: GoogleFonts.notoSans(
              color: _textMuted.withOpacity(0.5),
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...ownedGames.map((p) => _sidebarGameEntry(p)),
      ],
    );
  }

  Widget _sidebarEntry(String label, IconData icon, bool active,
      {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: _accent.withOpacity(0.08),
        splashColor: _accent.withOpacity(0.15),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: active ? _accent.withOpacity(0.12) : Colors.transparent,
            border: Border(
                left: BorderSide(
                    color: active ? _accent : Colors.transparent, width: 3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: active ? _accent : _textMuted, size: 15.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.notoSans(
                    color: active ? Colors.white : _textMuted,
                    fontSize: 11.sp,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sidebarGameEntry(LibraryItem item) {
    final isActive = _selectedItem == item;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() {
          _selectedItem = item;
          _activeGenre = null;
        }),
        hoverColor: _accent.withOpacity(0.08),
        splashColor: _accent.withOpacity(0.15),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isActive ? _accent.withOpacity(0.12) : Colors.transparent,
            border: Border(
                left: BorderSide(
                    color: isActive ? _accent : Colors.transparent, width: 3)),
          ),
          child: Row(
            children: [
              Icon(item.icon,
                  color: isActive ? Colors.white : item.accentColor,
                  size: 13.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  item.title.toUpperCase(),
                  style: GoogleFonts.notoSans(
                    color: isActive ? Colors.white : Colors.white70,
                    fontSize: 10.sp,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.runningGameIds.contains(item.mainIndex))
                Container(
                  width: 6.r,
                  height: 6.r,
                  decoration: const BoxDecoration(
                      color: _accentGreenBright, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreHome() {
    final items = _filteredProjects;
    if (items.isEmpty) return Center(child: Text("No games found.", style: GoogleFonts.notoSans(color: _textMuted)));
    final featured = items.first;

    return ListView(
      key: ValueKey(_activeGenre ?? 'home'),
      padding: EdgeInsets.all(24.r),
      children: [
        Text(
          _activeGenre != null ? "${_activeGenre!.toUpperCase()} GAMES" : "FEATURED & RECOMMENDED",
          style: GoogleFonts.notoSans(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 14.h),
        _buildFeaturedBanner(featured),
        SizedBox(height: 28.h),
        Text(
          "BROWSE ALL",
          style: GoogleFonts.notoSans(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 14.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 12.w, mainAxisSpacing: 12.h, childAspectRatio: 1.5),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isRunning = widget.runningGameIds.contains(item.mainIndex);
            return _buildStoreCard(item, isRunning: isRunning);
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedBanner(LibraryItem item) {
    return GestureDetector(
      onTap: () => setState(() => _selectedItem = item),
      child: Container(
        height: 260.h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.r),
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(item.bannerAsset, fit: BoxFit.cover),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft, end: Alignment.centerRight,
                          colors: [Colors.transparent, _bgCard.withOpacity(0.8)],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                color: _bgCard, padding: EdgeInsets.all(20.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: GoogleFonts.notoSans(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8.h),
                    Text(item.description, style: GoogleFonts.notoSans(color: _textMuted, fontSize: 11.sp)),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                      decoration: BoxDecoration(color: _accentGreen, borderRadius: BorderRadius.circular(2.r)),
                      child: Text("FREE TO PLAY", style: GoogleFonts.notoSans(color: _accentGreenBright, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(LibraryItem item, {bool isRunning = false}) {
    final isHovered = _hoveredIndex == item.mainIndex;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = item.mainIndex),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () => setState(() => _selectedItem = item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: isHovered ? (Matrix4.identity()..scale(1.03)) : Matrix4.identity(),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(color: isRunning ? _accentGreenBright : (isHovered ? _accent : Colors.white10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(item.bannerAsset, fit: BoxFit.cover),
                    if (isRunning)
                      Positioned(
                        top: 8.h, right: 8.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(color: _accentGreen, borderRadius: BorderRadius.circular(2.r)),
                          child: Text("RUNNING", style: GoogleFonts.vt323(color: _accentGreenBright, fontSize: 10.sp)),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(8.r), color: _bgCard,
                child: Text(item.title, style: GoogleFonts.notoSans(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPage(LibraryItem item) {
    final bool isOwned = _ownedGameIndices.contains(item.mainIndex);
    final bool isRunning = widget.runningGameIds.contains(item.mainIndex);
    final int playSeconds = widget.playTimeSeconds[item.mainIndex] ?? 0;

    return ListView(
      key: ValueKey(item.title),
      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
      children: [
        // --- Breadcrumbs ---
        Row(
          children: [
            GestureDetector(
                onTap: () => setState(() => _selectedItem = null),
                child: Text("All Games > ",
                    style: GoogleFonts.notoSans(
                        color: _accent,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600))),
            Text(item.title,
                style: GoogleFonts.notoSans(
                    color: Colors.white54, fontSize: 10.sp)),
          ],
        ),
        SizedBox(height: 12.h),

        // --- Large Header Title ---
        Text(
          item.title,
          style: GoogleFonts.notoSans(
            color: Colors.white,
            fontSize: 36.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 24.h),

        // --- Main Content Row (Banner + Info) ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner with slight shadow and rounded corners
            Expanded(
              flex: 3,
              child: Container(
                height: 320.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(item.bannerAsset, fit: BoxFit.cover),
              ),
            ),
            SizedBox(width: 24.w),
            // Game Mini-Info Sidebar
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      item.description,
                      style: GoogleFonts.notoSans(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12.sp,
                        height: 1.6,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _detailRow("REVIEWS", "Overwhelmingly Positive",
                      valueColor: const Color(0xFF66C0F4)),
                  _detailRow("RELEASE DATE", item.releaseDate),
                  _detailRow("DEVELOPER", item.developer),
                  _detailRow("GENRE", item.genre),
                  SizedBox(height: 20.h),
                  // Small Tag Cloud
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: item.tags.take(3).map((tag) => Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                          child: Text(tag.toUpperCase(), style: GoogleFonts.notoSans(color: Colors.white60, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                        )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 32.h),

        // --- STEAM ACTION BAR ---
        Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_bgDetailBar, _bgDetailBar.withOpacity(0.7)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              // Main Action Button
              _buildSteamButton(item, isOwned, isRunning),
              SizedBox(width: 32.w),
              // Playtime Stats
              if (isOwned) ...[
                _buildStatColumn("PLAY TIME", _formatPlayTime(playSeconds)),
                SizedBox(width: 24.w),
                _buildStatColumn("LAST PLAYED", "Today"),
                const Spacer(),
                // Extra Icons (Settings/Manage)
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.settings, color: _textMuted, size: 20.sp),
                  tooltip: "Manage",
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.info_outline, color: _textMuted, size: 20.sp),
                  tooltip: "Support",
                ),
              ] else ...[
                const Spacer(),
                Text("FREE TO PLAY", style: GoogleFonts.notoSans(color: _accentGreenBright, fontSize: 16.sp, fontWeight: FontWeight.w900)),
              ],
            ],
          ),
        ),
        SizedBox(height: 32.h),

        // --- ABOUT THIS GAME ---
        Text("ABOUT THIS GAME",
            style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
        SizedBox(height: 8.h),
        Divider(color: Colors.white.withOpacity(0.1), thickness: 1.5),
        SizedBox(height: 12.h),
        Text(
          item.longDescription,
          style: GoogleFonts.notoSans(
            color: _textMuted.withOpacity(0.9),
            fontSize: 12.sp,
            height: 1.8,
          ),
        ),
        SizedBox(height: 60.h), // Extra padding to keep text above window frame
      ],
    );
  }

  Widget _buildSteamButton(LibraryItem item, bool isOwned, bool isRunning) {
    if (!isOwned) {
      return _actionButton(
        label: "ADD TO LIBRARY",
        color: const Color(0xFF2D73FF),
        onTap: () => setState(() => _ownedGameIndices.add(item.mainIndex)),
      );
    }
    if (isRunning) {
      return _actionButton(
        label: "STOP",
        color: const Color(0xFF2D73FF),
        icon: Icons.close,
        onTap: () => widget.onStopProject?.call(item.mainIndex),
      );
    }
    return _actionButton(
      label: "PLAY NOW",
      color: _accentGreen,
      onTap: () => widget.onLaunchProject(item.mainIndex),
      hasGradient: true,
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    IconData? icon,
    required VoidCallback onTap,
    bool hasGradient = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180.w,
        height: 48.h,
        decoration: BoxDecoration(
          color: hasGradient ? null : color,
          gradient: hasGradient
              ? LinearGradient(
                  colors: [color.withOpacity(1.0), const Color(0xFF5a9b02)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          borderRadius: BorderRadius.circular(2.r),
          boxShadow: [
            if (hasGradient)
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18.sp),
              SizedBox(width: 8.w),
            ],
            Text(
              label,
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.notoSans(color: _textMuted, fontSize: 8.sp, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
        SizedBox(height: 4.h),
        Text(value, style: GoogleFonts.notoSans(color: Colors.white.withOpacity(0.9), fontSize: 13.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }


  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(children: [SizedBox(width: 100.w, child: Text(label, style: GoogleFonts.notoSans(color: _textMuted.withOpacity(0.6), fontSize: 9.sp))), Expanded(child: Text(value, style: GoogleFonts.notoSans(color: valueColor ?? Colors.white70, fontSize: 10.sp, fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal)))]),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 32.h, padding: EdgeInsets.symmetric(horizontal: 20.w), color: _bgDarker,
      child: Row(children: [Text("STORE UPDATED: 2026-03-31", style: GoogleFonts.notoSans(color: _textMuted.withOpacity(0.4), fontSize: 9.sp)), const Spacer(), Text("${_projects.length} GAMES", style: GoogleFonts.notoSans(color: _textMuted.withOpacity(0.4), fontSize: 9.sp)), SizedBox(width: 16.w), Icon(Icons.cloud_done, color: _accentGreenBright, size: 12.sp), SizedBox(width: 5.w), Text("CONNECTED", style: GoogleFonts.notoSans(color: _accentGreenBright, fontSize: 9.sp, fontWeight: FontWeight.bold))]),
    );
  }

  String _formatPlayTime(int totalSeconds) {
    if (totalSeconds < 60) return "$totalSeconds seconds";
    final minutes = totalSeconds ~/ 60;
    if (minutes < 60) return "$minutes minutes";
    final hours = totalSeconds / 3600.0;
    return "${hours.toStringAsFixed(1)} hours";
  }
}
