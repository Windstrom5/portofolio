import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'model/resume_generator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_test/widget/crt_overlay.dart';
import 'package:project_test/widget/ai_chat_panel.dart';
import 'package:project_test/widget/Loader_Gate.dart';
import '../model/chat_message.dart';
import 'package:project_test/widget/vrm_maid_view.dart';
import 'dart:async'; // For clock
import 'dart:math';
import 'dart:convert'; // jsonDecode
import 'package:http/http.dart' as http; // Open-Meteo API calls
import 'utils/web_utils.dart';
import '../llm/llm_service.dart';
import 'widget/poker.dart';
import 'widget/chess_game.dart';
import 'widget/discord_activity_widget.dart';
import 'widget/premier_league_table.dart';

import 'model/work_experience_model.dart';
import 'model/project_model.dart';
import 'model/cv_models.dart';
import 'widget/sakura_particles.dart';
import 'widget/spotify_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widget/tech_marquee.dart';
import 'widget/project_store.dart';
import 'widget/vn_dialogue_bubble.dart';
import 'widget/image_processor.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1440, 900),
      builder: (_, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            // Set global font to a Monospace font for that Linux feel
            textTheme: GoogleFonts.jetBrainsMonoTextTheme(),
            scaffoldBackgroundColor:
                const Color(0xFF282a36), // Dracula Theme BG
          ),
          home: const LoaderGate(),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

Widget _systemInfoChip(IconData icon, String label) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: Colors.grey.shade900,
      borderRadius: BorderRadius.circular(4.r),
      border: Border.all(color: Colors.grey.shade700),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: Color(0xFF50FA7B)),
        SizedBox(width: 6.w),
        Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.white70)),
      ],
    ),
  );
}

class _HomePageState extends State<HomePage> {
  List<ChatMessage> chatHistory = [];
  int _selectedIndex = -1;
  String _currentTime = "";
  List<String> additionalTerminalOutput = [];
  final TextEditingController _terminalController = TextEditingController();
  bool _llmLoading = false;
  int _llmProgress = 0;
  late DateTime _appStartTime;
  String _weatherTemp = "—";
  String _weatherIcon = "🌤️";

  bool _discordMinimized = true;
  String _weatherDesc = "Loading...";
  String _locationText = "Detecting...";

  // Unified Dialogue State
  String _globalDialogueJp = "";
  String? _globalDialogueEn;
  bool _isGlobalSpeaking = false;
  Timer? _dialogueFadeTimer;
  int _cpuCores = 0;
  double _ramGb = 0.0;
  int _fakeCpuLoad = 35; // we'll animate it a bit
  Timer? _cpuLoadTimer; // Timer reference for proper disposal

  bool _plTableMinimized = true;
  bool _showSpotify = false;
  @override
  void initState() {
    super.initState();
    _loadRealWeather();
    _appStartTime = DateTime.now();
    _updateTime();
    _cpuCores = WebUtils.hardwareConcurrency;
    _ramGb = double.tryParse(WebUtils.deviceMemory) ?? 8.0;
// In initState(), after other timers:
    _cpuLoadTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _fakeCpuLoad = 30 + Random().nextInt(21); // Varies 30-50%
      });
    });
  }

  @override
  void dispose() {
    _cpuLoadTimer?.cancel();
    _terminalController.dispose();
    _terminalScrollController.dispose();
    super.dispose();
  }

  final ScrollController _terminalScrollController = ScrollController();
  final VrmController _vrmController = VrmController();
  void _scrollToBottom() {
    if (!_terminalScrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _terminalScrollController.animateTo(
        _terminalScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadRealWeather() async {
    if (!kIsWeb) {
      setState(() {
        _weatherDesc = "Web only";
        _locationText = "N/A";
      });
      return;
    }

    try {
      // First try IP-based geolocation (more reliable, no permissions needed)
      // wttr.in automatically uses visitor's IP for location
      final url = 'https://wttr.in?format=j1';
      await _fetchAndParseWttr(url);
    } catch (e) {
      print('Weather API error: $e');
      // Try with a fallback location
      try {
        final fallbackUrl = 'https://wttr.in/Yogyakarta?format=j1';
        await _fetchAndParseWttr(fallbackUrl);
      } catch (e2) {
        print('Weather fallback error: $e2');
        setState(() {
          _weatherTemp = "—";
          _weatherIcon = "⚠️";
          _weatherDesc = "Weather unavailable";
          _locationText = "—";
        });
      }
    }
  }

  Future<void> _fetchAndParseWttr(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception("wttr.in returned ${response.statusCode}");
    }

    final data = jsonDecode(response.body);

    // Current condition
    final current = data['current_condition']?[0];
    if (current == null) throw Exception("No current_condition");

    final tempC = current['temp_C'] ?? "—";
    final weatherCode = current['weatherCode'] ?? "999"; // fallback
    final windKph = current['windspeedKmph'] ?? "—";
    final city = data['nearest_area']?[0]?['areaName']?[0]?['value'] ?? "—";

    // Map weather code → icon + description
    // (wttr.in uses World Meteorological Organization-ish codes)
    String icon = "🌫️";
    String desc = "Unknown";

    final code = int.tryParse(weatherCode) ?? 999;

    if (code <= 119) {
      icon = "☀️";
      desc = "Sunny/Clear";
    } else if (code <= 260) {
      icon = "⛅";
      desc = "Cloudy";
    } else if (code <= 299) {
      icon = "🌤️";
      desc = "Partly cloudy";
    } else if (code <= 399) {
      icon = "🌧️";
      desc = "Rain";
    } else if (code <= 499) {
      icon = "🌦️";
      desc = "Showers";
    } else if (code <= 599) {
      icon = "❄️";
      desc = "Snow";
    } else if (code <= 699) {
      icon = "🌫️";
      desc = "Fog/Mist";
    } else if (code <= 799) {
      icon = "⛈️";
      desc = "Thunderstorm";
    } else {
      icon = "🌪️";
      desc = "Extreme";
    }

    setState(() {
      _weatherTemp = tempC;
      _weatherIcon = icon;
      _weatherDesc = "$desc • ${windKph}km/h";
      _locationText = city;
    });
  }

  void _updateGlobalDialogue(String text, {String? english, String? emotion}) {
    _dialogueFadeTimer?.cancel();
    setState(() {
      _globalDialogueJp = text;
      _globalDialogueEn = english;
      _isGlobalSpeaking = true;
    });

    _dialogueFadeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _isGlobalSpeaking = false);
      }
    });

    // Also forward to VRM
    _postMessageToVrm(text, english: english, emotion: emotion);
  }

  String _getJsValue(String path) {
    try {
      final obj = WebUtils.getPropertyByPath(path);
      return obj?.toString() ?? 'Unknown';
    } catch (_) {
      return 'Unavailable';
    }
  }

  int _getJsInt(String path) {
    final val = _getJsValue(path);
    return int.tryParse(val) ?? 0;
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    setState(() {
      _currentTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    });
  }

  void openAiChat() {
    setState(() {
      _llmLoading = true;
      _llmProgress = 0;
    });

    LlmService.init((p) {
      setState(() {
        _llmProgress = p;
      });
      if (p == 100) {
        setState(() {
          _llmLoading = false;
        });
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8), // Sharper corners for OS feel
          child: Container(
            width: 1000,
            height: 500,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: Stack(
              children: [
                if (_llmLoading)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(value: _llmProgress / 100),
                        SizedBox(height: 20),
                        Text("Loading AI... $_llmProgress%",
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  )
                else if (kIsWeb)
                  Row(
                    children: [
                      SizedBox(
                        width: 300,
                        height: 500,
                        child: VrmMaidView(),
                      ),
                      Expanded(
                        child: AiChatPanel(chatHistory: chatHistory),
                      ),
                    ],
                  )
                else
                  AiChatPanel(chatHistory: chatHistory),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      // Cancel LLM init if possible, but since it's static, it's fine
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.red, // OS Close button style
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'anggagant@gmail.com',
      query: encodeQueryParameters(<String, String>{
        'subject': '[COLLABORATION] Project Inquiry',
        'body':
            'Hello Windstrom5,\n\nI saw your portfolio and would like to discuss a potential project...'
      }),
    );
    if (!await launchUrl(emailLaunchUri,
        mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $emailLaunchUri';
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> _processCommand(String rawCommand) async {
    final command = rawCommand.trim();
    setState(() {
      additionalTerminalOutput.add("windstrom5@portfolio:~\$ $command");
    });

    final cmd = command.toLowerCase();

    if (cmd == "help") {
      _showHelp();
    } else if (cmd == "ls") {
      additionalTerminalOutput.add(
          "projects  certificates  education  profile  resume.pdf  tic_tac_toe  rock_paper_scissors");
    } else if (cmd.startsWith("open ")) {
      String target = cmd.substring(5).trim();
      int? index;
      if (target == "projects")
        index = 1;
      else if (target == "certificates")
        index = 2;
      else if (target == "education")
        index = 3;
      else if (target == "profile")
        index = 4;
      else if (target == "experience")
        index = 5;
      else if (target == "tic_tac_toe" || target == "tictactoe")
        index = 6;
      else if (target == "rock_paper_scissors" || target == "rps")
        index = 7;
      else if (target == "resume.pdf") {
        final resumePdf = ResumePdf();
        final pdfBytes = await resumePdf.generate(
          projects: allProjects,
          experiences: allWorkExperiences,
          education: allEducation,
          achievements: allAchievements,
        );
        resumePdf.downloadPdfWeb(pdfBytes, 'resume_angga.pdf');
        additionalTerminalOutput.add("Downloading resume.pdf...");
        return;
      }

      if (index != null) {
        setState(() {
          _selectedIndex = index!;
        });
      } else {
        additionalTerminalOutput.add("Target not found: $target");
      }
    } else if (cmd == "clear") {
      setState(() => additionalTerminalOutput.clear());
    } else if (cmd == "close" || cmd == "exit") {
      setState(() => _selectedIndex = -1);
    }
    // ─── New commands ───────────────────────────────────────
    else if (cmd == "whoami") {
      additionalTerminalOutput.add("windstrom5");
    } else if (cmd == "pwd") {
      additionalTerminalOutput.add("/home/windstrom5/portfolio");
    } else if (cmd == "uname -a") {
      additionalTerminalOutput
          .add("Linux portfolio 6.8.0-flutter #1 SMP PREEMPT_DYNAMIC "
              "Flutter Web x86_64 GNU/Linux");
    } else if (cmd == "uptime") {
      final diff = DateTime.now().difference(_appStartTime);
      final d = diff.inDays;
      final h = diff.inHours % 24;
      final m = diff.inMinutes % 60;
      final s = diff.inSeconds % 60;
      additionalTerminalOutput
          .add(" ${d}d ${h}h ${m}m ${s}s  (since page opened)");
    } else if (cmd == "neofetch" || cmd == "sysinfo") {
      final diff = DateTime.now().difference(_appStartTime);
      final uptime =
          "${diff.inHours}h ${diff.inMinutes % 60}m ${diff.inSeconds % 60}s";

      final cores = _getJsInt('navigator.hardwareConcurrency');
      final ramGb = _getJsValue('navigator.deviceMemory');
      final w = _getJsInt('screen.width');
      final h = _getJsInt('screen.height');
      final dpr = double.tryParse(_getJsValue('devicePixelRatio')) ?? 1.0;

      additionalTerminalOutput.addAll([
        "  OS: Flutter Web / Browser Distro",
        "  Host: Windstrom5 Portfolio",
        "  Kernel: WebGPU / CanvasKit",
        "  Uptime: $uptime",
        "  Resolution: ${w}x${h} @ ${dpr.toStringAsFixed(1)}x",
        if (cores > 0) "  CPU threads: $cores",
        if (ramGb != 'Unknown' && ramGb != '0')
          "  Memory: ~${ramGb} GB (browser estimate)",
        "  Shell: Emulated zsh",
        "  Theme: Dracula",
        "  Browser: ${_getJsValue('navigator.userAgent').split(' ').lastWhere((e) => e.contains('/'), orElse: () => 'Unknown')}",
        "",
        "  Note: Limited to browser-exposed info (privacy restrictions)",
      ]);
    } else if (cmd == "browser-info" || cmd == "device-info") {
      final ua = _getJsValue('navigator.userAgent');
      final platform = _getJsValue('navigator.platform');
      final vendor = _getJsValue('navigator.vendor');
      final cores = _getJsInt('navigator.hardwareConcurrency');
      final mem = _getJsValue('navigator.deviceMemory');
      final lang = _getJsValue('navigator.language');
      final screen =
          "${_getJsInt('screen.width')}×${_getJsInt('screen.height')}";

      additionalTerminalOutput.addAll([
        "Browser/Device Info (real values from browser):",
        "───────────────────────────────────────────────",
        "User Agent     : $ua",
        "Platform       : $platform",
        "Vendor         : $vendor",
        if (cores > 0) "Logical CPU cores : $cores",
        if (mem != 'Unknown' && mem != '0') "Approx. RAM (GB)  : $mem",
        "Screen         : $screen px",
        "Language       : $lang",
        "Touch support  : ${_getJsInt('navigator.maxTouchPoints') > 0 ? 'Yes' : 'No'}",
        "",
      ]);
    } else if (cmd == "fortune") {
      const fortunes = [
        "The best way to predict the future is to implement it.",
        "コードが動いた瞬間が一番気持ちいいよね～",
        "There are 10 types of people: those who understand binary, and those who don't.",
        "先輩…もうちょっとだけ一緒にいよ？",
        "Debugging is twice as hard as writing the code in the first place.",
      ];
      final randomLine = fortunes[Random().nextInt(fortunes.length)];
      additionalTerminalOutput.add(randomLine);
    } else if (cmd == "df -h") {
      final w = _getJsInt('screen.width');
      final h = _getJsInt('screen.height');
      final totalPx = (w * h / 1e6).toStringAsFixed(1); // mega-pixels as "GB"
      additionalTerminalOutput.addAll([
        "Filesystem      Size  Used Avail Use% Mounted on",
        "/dev/screen    ${totalPx}G  4.2G  ${(double.parse(totalPx) * 0.6).toStringAsFixed(1)}G  42% /",
        "tmpfs           512M     0  512M   0% /dev/shm",
        "(browser doesn't expose real disk — using screen resolution as metaphor)",
      ]);
    } else if (cmd == "free -h") {
      final ramStr = _getJsValue('navigator.deviceMemory');

      // Safely parse the approximate RAM in GB
      final totalGb =
          double.tryParse(ramStr) ?? 8.0; // fallback to 8 if unavailable

      // Make reasonable estimates (browser only gives rough value)
      final usedGb = totalGb * 0.45; // pretend ~45% used
      final freeGb = totalGb * 0.55;
      final buffCache = totalGb * 0.15; // pretend some cached

      final totalStr = totalGb.toStringAsFixed(1) + 'G';
      final usedStr = usedGb.toStringAsFixed(1) + 'G';
      final freeStr = freeGb.toStringAsFixed(1) + 'G';
      final availStr = (freeGb + buffCache).toStringAsFixed(1) + 'G';

      additionalTerminalOutput.addAll([
        "              total        used        free      shared  buff/cache   available",
        "Mem:           $totalStr       $usedStr       $freeStr         0B       ${buffCache.toStringAsFixed(1)}G        $availStr",
        "Swap:          2.0G          0B       2.0G",
        "(browser only exposes approximate total RAM — values are estimates)",
      ]);
    } else if (cmd == "lsb_release -a") {
      final ua = _getJsValue('navigator.userAgent').toLowerCase();
      String distro = "Unknown";
      if (ua.contains("windows"))
        distro = "Windows-like";
      else if (ua.contains("mac"))
        distro = "macOS-like";
      else if (ua.contains("linux"))
        distro = "Linux-like";
      else if (ua.contains("android"))
        distro = "Android-like";
      else if (ua.contains("iphone") || ua.contains("ipad"))
        distro = "iOS-like";

      additionalTerminalOutput.addAll([
        "No LSB modules are available.",
        "Distributor ID: FlutterWeb",
        "Description:    Custom Flutter Linux Distro ($distro)",
        "Release:        25.10 (Oracular Oriole vibe)",
        "Codename:       portfolio",
      ]);
    } else if (cmd == "cat /proc/cpuinfo") {
      final cores = _getJsInt('navigator.hardwareConcurrency');
      additionalTerminalOutput.addAll([
        "processor       : 0",
        "model name      : Browser Emulated CPU",
        "cpu MHz         : Variable (browser throttled)",
        "cache size      : Unknown",
        "physical id     : 0",
        "siblings        : $cores",
        "core id         : 0",
        "cpu cores       : $cores",
        "... (only logical cores are visible from browser)",
      ]);
    } else if (cmd == "cat /etc/os-release") {
      additionalTerminalOutput.addAll([
        'PRETTY_NAME="Flutter Portfolio OS"',
        'NAME="FlutterWeb"',
        'ID=flutterweb',
        'ID_LIKE=linux',
        'VERSION_ID="2025"',
        'HOME_URL="https://github.com/Windstrom5"',
        'SUPPORT_URL="https://x.com/Windstrom57"',
        'BUG_REPORT_URL="https://github.com/Windstrom5/project_test/issues"',
      ]);
    } else if (cmd == "echo \$LANG") {
      final lang = _getJsValue('navigator.language') ??
          _getJsValue('navigator.languages[0]') ??
          'en-US';
      additionalTerminalOutput.add(lang);
    } else if (cmd == "env") {
      final lang = _getJsValue('navigator.language') ?? 'en-US';
      additionalTerminalOutput.addAll([
        "TERM=portfolio-terminal",
        "LANG=$lang",
        "SHELL=emulated-zsh",
        "USER=windstrom5",
        "HOME=/home/windstrom5",
        "PATH=/usr/local/bin:/usr/bin:/bin",
        "DISPLAY=:0 (web)",
        "TZ=Asia/Jakarta", // you can change if needed
      ]);
    } else if (cmd == "hostname") {
      additionalTerminalOutput.add("portfolio");
    } else if (cmd == "ps") {
      additionalTerminalOutput.addAll([
        "  PID TTY          TIME CMD",
        "    1 ?        00:00:02 flutter_engine",
        "  420 tty1     00:00:00 zsh (emulated)",
        "  666 ?        00:00:01 vrm_maid_process",
        " 1337 pts/0    00:00:00 tic_tac_toe",
        " 4242 pts/0    00:00:00 rock_paper_scissors",
        "(only fun fake processes — real ones hidden)",
      ]);
    } else {
      additionalTerminalOutput.add("Command not found: $cmd    (try 'help')");
    }

    // Optional: auto-scroll would require ScrollController on the SingleChildScrollView
    _scrollToBottom();
  }

  void _showHelp() {
    setState(() {
      additionalTerminalOutput.addAll([
        "Available commands:",
        "  ls                     list sections & files",
        "  open <name>            open section/file (projects, tic_tac_toe, resume.pdf …)",
        "  ──────────────────────────────────────────────",
        "  whoami                 show current user",
        "  pwd                    print working directory",
        "  uname -a               show system/kernel info",
        "  uptime                 show time since page load",
        "  neofetch / sysinfo     beautiful system overview",
        "  browser-info           browser & device details",
        "  df -h                 disk usage (browser-style)",
        "  free -h                memory usage (approximate)",
        "  lsb_release -a         distribution info",
        "  cat /proc/cpuinfo      cpu information (limited)",
        "  cat /etc/os-release    os release details",
        "  echo \$LANG            current language",
        "  env                    environment variables",
        "  hostname               show hostname",
        "  ps                     process list (fun version)",
        "  fortune                random quote",
        "  clear                  clear terminal",
        "  help                   this help",
        "  close / exit           close window",
        "",
      ]);
    });
  }

  // ==========================================
  // 🖥️ LINUX WINDOW FRAME WIDGET
  // ==========================================
  Widget _buildWindowFrame({required Widget child, required String title}) {
    return Center(
      child: Container(
        width: 1000.w,
        height: 650.h,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Terminal/Window Dark BG
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
          border: Border.all(color: const Color(0xFF44475a), width: 1),
        ),
        child: Column(
          children: [
            // --- Title Bar ---
            Container(
              height: 35.h,
              decoration: BoxDecoration(
                color: const Color(0xFF282a36),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.r),
                  topRight: Radius.circular(8.r),
                ),
                border:
                    Border(bottom: BorderSide(color: const Color(0xFF44475a))),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Row(
                children: [
                  // Traffic Lights
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedIndex = -1);
                        },
                        child: CircleAvatar(
                            radius: 6.r,
                            backgroundColor: const Color(0xFFFF5555)), // Close
                      ),
                      SizedBox(width: 8.w),
                      CircleAvatar(
                          radius: 6.r,
                          backgroundColor: const Color(0xFFF1FA8C)), // Minimize
                      SizedBox(width: 8.w),
                      CircleAvatar(
                          radius: 6.r,
                          backgroundColor: const Color(0xFF50FA7B)), // Maximize
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "user@windstrom5: ~/$title",
                        style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                      ),
                    ),
                  ),
                  // Removed BACK / CLOSE Button (Traffic lights are sufficient)
                ],
              ),
            ),
            // --- Content ---
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8.r),
                  bottomRight: Radius.circular(8.r),
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 💻 TERMINAL CONTENT (HOME)
  // ==========================================
  Widget _buildTerminalHome() {
    // Green terminal text style
    final termStyle =
        TextStyle(color: const Color(0xFF50FA7B), fontSize: 16.sp);
    final whiteStyle = TextStyle(color: Colors.white, fontSize: 16.sp);

    return SingleChildScrollView(
      controller: _terminalScrollController,
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText.rich(
            TextSpan(
              children: [
                TextSpan(text: "windstrom5@portfolio", style: termStyle),
                TextSpan(text: ":", style: whiteStyle),
                TextSpan(
                    text: "~\$ ",
                    style:
                        TextStyle(color: Colors.blueAccent, fontSize: 16.sp)),
                TextSpan(text: "./neofetch\n", style: whiteStyle),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image instead of ASCII Art
              if (MediaQuery.of(context).size.width > 600)
                CircleAvatar(
                  radius: 100.r,
                  backgroundImage: AssetImage('assets/profile.jpg'),
                ),
              SizedBox(width: 20.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("OS: Custom Flutter Distro x86_64", style: whiteStyle),
                    Text("Host: Windstrom5 Portfolio", style: whiteStyle),
                    Text("Kernel: 5.15.0-generic", style: whiteStyle),
                    Text("Uptime: Forever", style: whiteStyle),
                    Text("Packages: 5 (Education, Projects...)",
                        style: whiteStyle),
                    Text("Shell: ZSH 5.8", style: whiteStyle),
                    Text("Theme: Dracula Dark", style: whiteStyle),
                    SizedBox(height: 15.h),
                    Text("--- BIO ---",
                        style: TextStyle(
                            color: Colors.purpleAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp)),
                    SizedBox(height: 5.h),
                    Text(
                      "Hello, I'm Angga Nugraha.\nFull Stack Developer based in Yogyakarta.\nEnthusiast in Gaming Tech & Innovation.",
                      style: whiteStyle.copyWith(height: 1.5),
                    ),
                    SizedBox(height: 15.h),
                    Text("--- SKILLS ---",
                        style: TextStyle(
                            color: Colors.purpleAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp)),
                    SizedBox(height: 5.h),
                    Wrap(
                      spacing: 10,
                      children: [
                        _termSkill("Kotlin", Colors.purple),
                        _termSkill("Vue.js", Colors.green),
                        _termSkill("Laravel", Colors.red),
                        _termSkill("Java", Colors.orange),
                      ],
                    ),
                    SizedBox(height: 15.h),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final resumePdf = ResumePdf();
                        final pdfBytes = await resumePdf.generate(
                          projects: [],
                          experiences: [],
                          education: [],
                          achievements: [],
                        );
                        resumePdf.downloadPdfWeb(pdfBytes, 'resume_angga.pdf');
                      },
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text("sudo apt-get install resume.pdf"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade800,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: 15.w, vertical: 15.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          ...additionalTerminalOutput
              .map((line) => Text(line, style: whiteStyle)),
          SizedBox(height: 10.h),
          Row(
            children: [
              Text("windstrom5@portfolio:~\$ ", style: termStyle),
              Expanded(
                child: TextField(
                  controller: _terminalController,
                  style: whiteStyle,
                  autofocus: true,
                  onSubmitted: (value) {
                    _processCommand(value);
                    _terminalController.clear();
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  cursorColor: const Color(0xFF50FA7B),
                  cursorWidth: 10.0,
                  cursorRadius: Radius.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _termSkill(String name, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(name, style: TextStyle(color: color, fontSize: 12.sp)),
    );
  }

  Widget _profileInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 18.sp),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(color: Colors.white54, fontSize: 11.sp)),
              Text(value,
                  style: TextStyle(color: Colors.white, fontSize: 13.sp)),
            ],
          )
        ],
      ),
    );
  }

  Widget _skillChip(String name, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: color,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ==========================================
  // 📂 CONTENT SWITCHER
  // ==========================================
  Widget _buildBodyContent() {
    if (_selectedIndex == -1) {
      return const SizedBox();
    }
    Widget content;
    switch (_selectedIndex) {
      case 0:
        content = _buildTerminalHome();
        break;
      case 1:
        content = const ProjectStoreApp();
        break;
      case 2:
        content = _buildCertificatesView();
        break;
      case 3:
        content = _buildEducationView();
        break;
      case 4:
        content = _buildProfileView();
        break;
      case 5:
        content = _buildExperienceView();
        break;
      case 6: // Tic Tac Toe
        content = _buildTicTacToeView();
        break;
      case 7: // Rock Paper Scissors
        content = _buildRpsView();
        break;
      case 8: // Poker
        content = _buildPokerView();
        break;
      case 9: // Chess
        content = _buildChessView();
        break;
      case 10: // Image Lab
        content = const ImageProcessor();
        break;
      default:
        content = Container();
    }
    return _buildWindowFrame(title: _getTitle(_selectedIndex), child: content);
  }

  Widget _buildCertificatesView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(32.r),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Header
          _buildPageHeader(
            title: "PROFESSIONAL CERTIFICATIONS",
            subtitle: "Verified credentials from global institutions",
            icon: Icons.verified,
            color: Colors.purpleAccent,
          ),
          SizedBox(height: 40.h),

          // Grid of Certificates
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 24.w,
              mainAxisSpacing: 24.h,
              childAspectRatio: 1.5,
            ),
            itemCount: allAchievements.length,
            itemBuilder: (context, index) {
              final ach = allAchievements[index];
              return _buildRetroCertificateCard(ach);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEducationView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(32.r),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Header
          _buildPageHeader(
            title: "ACADEMIC BACKGROUND",
            subtitle: "Foundations of knowledge and specialized study",
            icon: Icons.school,
            color: Colors.cyanAccent,
          ),
          SizedBox(height: 40.h),

          // Timeline/List of Education
          ...allEducation.map((edu) => _buildRetroEducationPage(edu)),
        ],
      ),
    );
  }

  Widget _buildPageHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.only(bottom: 24.h),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: color.withOpacity(0.3), width: 2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 32.sp),
          ),
          SizedBox(width: 24.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle.toUpperCase(),
                style: GoogleFonts.vt323(
                  color: color.withOpacity(0.7),
                  fontSize: 16.sp,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetroCertificateCard(AchievementModel ach) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    "assets/atma.jpg", // Fallback image as thumbnails might be missing
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8)
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12.h,
                  left: 12.w,
                  child: Text(
                    ach.date,
                    style: GoogleFonts.vt323(
                        color: Colors.purpleAccent, fontSize: 14.sp),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ach.certificateName,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  ach.organizationName,
                  style:
                      GoogleFonts.vt323(color: Colors.white70, fontSize: 14.sp),
                ),
                SizedBox(height: 12.h),
                // Key Learnings Header
                Text(
                  "VALIDATED SKILLS:",
                  style: GoogleFonts.orbitron(
                    color: Colors.purpleAccent.withOpacity(0.5),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  children: ach.skills
                      .map((s) => Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.purpleAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4.r),
                              border: Border.all(
                                  color: Colors.purpleAccent.withOpacity(0.3)),
                            ),
                            child: Text(
                              s.toUpperCase(),
                              style: GoogleFonts.vt323(
                                  color: Colors.purpleAccent, fontSize: 10.sp),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetroEducationPage(EducationModel edu) {
    // Dynamic asset path based on school name
    String assetPath = "assets/atma.jpg";
    if (edu.schoolName.contains("SMA")) assetPath = "assets/sman.jpg";
    if (edu.schoolName.contains("SMP")) assetPath = "assets/smpn.jpg";

    return Container(
      margin: EdgeInsets.only(bottom: 48.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name & Meta (Left)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: const BoxDecoration(
                        color: Colors.cyanAccent,
                      ),
                      child: Text(
                        edu.schoolName.toUpperCase(),
                        style: GoogleFonts.orbitron(
                          color: Colors.black,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: Colors.cyanAccent, size: 16.sp),
                        SizedBox(width: 8.w),
                        Text(
                          edu.location,
                          style: GoogleFonts.vt323(
                              color: Colors.cyanAccent, fontSize: 18.sp),
                        ),
                        SizedBox(width: 24.w),
                        Icon(Icons.calendar_today,
                            color: Colors.white54, size: 14.sp),
                        SizedBox(width: 8.w),
                        Text(
                          edu.years,
                          style: GoogleFonts.vt323(
                              color: Colors.white70, fontSize: 18.sp),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      edu.degreeType,
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 4.h),
                      height: 2.h,
                      width: 100.w,
                      color: Colors.cyanAccent,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 32.w),
              // School Logo / Graphic (Right)
              Container(
                width: 140.r,
                height: 140.r,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.cyanAccent, width: 3),
                  image: DecorationImage(
                    image: AssetImage(assetPath),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.3),
                      offset: const Offset(8, 8),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 40.h),

          // High-Energy Layout for Description & Learnings
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionSubheader("// DATA_DOMAIN"),
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        border: Border(
                            left: BorderSide(color: Colors.white24, width: 1)),
                      ),
                      child: Text(
                        edu.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16.sp,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 48.w),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionSubheader("// SKILL_INITIALIZATION"),
                    Container(
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.05),
                        border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.2)),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(24.r),
                        ),
                      ),
                      child: Text(
                        edu.learnings,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.cyanAccent,
                          fontSize: 14.sp,
                          height: 1.8,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: edu.skills
                          .map((skill) => Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  border: Border.all(
                                      color:
                                          Colors.cyanAccent.withOpacity(0.5)),
                                ),
                                child: Text(
                                  skill.toUpperCase(),
                                  style: GoogleFonts.vt323(
                                      color: Colors.white, fontSize: 13.sp),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 32.h),
          const Divider(color: Colors.white10),
        ],
      ),
    );
  }

  Widget _buildSectionSubheader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title,
        style: GoogleFonts.orbitron(
          color: Colors.white38,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(maxWidth: 520.w),
          padding: EdgeInsets.all(2.w), // Outer border padding
          decoration: BoxDecoration(
            color: Colors.cyanAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Container(
            padding: EdgeInsets.all(30.w),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117), // Deep space black
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // TOP HUD DECO
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("BIOS_ID: 8859-1",
                        style: GoogleFonts.vt323(
                            color: Colors.cyanAccent, fontSize: 10.sp)),
                    Row(
                      children: [
                        Container(
                            width: 20, height: 2, color: Colors.cyanAccent),
                        SizedBox(width: 5.w),
                        Container(
                            width: 4, height: 4, color: Colors.cyanAccent),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                // PROFILE IMAGE WITH SCANNERS
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Decorative rings
                    Container(
                      width: 140.w,
                      height: 140.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.2),
                            width: 1),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.3),
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60.r,
                        backgroundColor: Colors.cyan.withOpacity(0.1),
                        backgroundImage: const AssetImage('assets/profile.jpg'),
                      ),
                    ),
                    // Diagonal accents
                    Positioned(
                      top: 0,
                      right: 10,
                      child: Icon(Icons.qr_code_scanner,
                          color: Colors.cyanAccent, size: 20.sp),
                    ),
                  ],
                ),
                SizedBox(height: 25.h),
                // NAME & TITLE BLOCK
                Column(
                  children: [
                    Text(
                      "ANGGA NUGRAHA",
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.cyanAccent),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10.r),
                          bottomRight: Radius.circular(10.r),
                        ),
                      ),
                      child: Text(
                        "FULL STACK DEVELOPER // BACKEND SPECIALIST",
                        style: GoogleFonts.vt323(
                          color: Colors.cyanAccent,
                          fontSize: 12.sp,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                // BIO DATA SECTION
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    border: Border(
                      left: BorderSide(color: Colors.cyanAccent, width: 3.w),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _hudDataField("REGISTRY", "YOGYAKARTA, ID"),
                      SizedBox(height: 12.h),
                      _hudDataField("CONTACT", "ANGGAGANT@GMAIL.COM"),
                    ],
                  ),
                ),
                SizedBox(height: 30.h),
                // TECH STACK HEADER
                Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.cyanAccent, size: 18.sp),
                    SizedBox(width: 8.w),
                    Text(
                      "SUBSYSTEMS / TECH_STACK",
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                        child: Divider(
                            color: Colors.cyanAccent.withOpacity(0.3),
                            indent: 10)),
                  ],
                ),
                SizedBox(height: 15.h),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _hudSkillChip("FLUTTER", Colors.blue),
                    _hudSkillChip("KOTLIN", Colors.purple),
                    _hudSkillChip("VUE.JS", Colors.green),
                    _hudSkillChip("LARAVEL", Colors.red),
                    _hudSkillChip("DART", Colors.blueAccent),
                  ],
                ),
                SizedBox(height: 30.h),
                // SYSTEM LOG FOOTER
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    "PASSIOINATE FULL STACK DEVELOPER SPECIALIZING IN MOBILE & WEB ARCHITECTURE. CURRENTLY OPTIMIZING HIGH-PERFORMANCE BACKEND SYSTEMS.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vt323(
                      color: Colors.blueGrey.shade300,
                      fontSize: 13.sp,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hudDataField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.vt323(
                color: Colors.cyanAccent.withOpacity(0.5), fontSize: 10.sp)),
        Text(value,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }

  Widget _hudSkillChip(String name, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: 8.w),
          Text(
            name,
            style: GoogleFonts.vt323(
              color: Colors.white,
              fontSize: 14.sp,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceView() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, color: Colors.cyanAccent),
              SizedBox(width: 10.w),
              Text(
                "ACTIVE_MISSIONS / WORK_HISTORY",
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 25.h),
          ...allWorkExperiences.map((exp) {
            return _buildRetroExperienceCard(exp);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRetroExperienceCard(WorkExperienceModel exp) {
    return Container(
      margin: EdgeInsets.only(bottom: 35.h),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. REAR SKEWED DECORATIVE PANEL (RED)
          Positioned(
            left: -10,
            top: -10,
            right: 10,
            bottom: 10,
            child: Transform(
              transform: Matrix4.skewX(-0.1),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000), // Persona RED
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(4, 4),
                    )
                  ],
                ),
              ),
            ),
          ),
          // 2. MAIN CONTENT PANEL (BLACK)
          Transform(
            transform: Matrix4.skewX(-0.1),
            child: Container(
              padding: EdgeInsets.zero,
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER STRIPE
                  Container(
                    height: 40.h,
                    width: double.infinity,
                    color: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: [
                        Text(
                          "MISSION_INTEL",
                          style: GoogleFonts.vt323(
                            color: Colors.black,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          exp.period.toUpperCase(),
                          style: GoogleFonts.vt323(
                            color: Colors.red,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // MAIN INFO
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exp.title.toUpperCase(),
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Color(0xFFFF0000), size: 14),
                            SizedBox(width: 5.w),
                            Text(
                              exp.company.toUpperCase(),
                              style: GoogleFonts.vt323(
                                color: Colors.grey,
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        // POINTS
                        ...exp.points.map((point) => Padding(
                              padding: EdgeInsets.only(bottom: 8.h),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(">",
                                      style: TextStyle(
                                          color: Color(0xFFFF0000),
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      point,
                                      style: GoogleFonts.vt323(
                                          color: Colors.white, fontSize: 14.sp),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        SizedBox(height: 15.h),
                        // TECH CHIPS (RED OUTLINE)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: exp.techStack.map((tech) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.white, width: 1.5),
                                color: Colors.transparent,
                              ),
                              child: Text(
                                tech.toUpperCase(),
                                style: GoogleFonts.vt323(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 3. OVERLAY BORDER STRIPE (PERSONA STYLE)
          Positioned(
            bottom: -5,
            right: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
              color: const Color(0xFFFF0000),
              child: Text(
                "ID: ${exp.company.substring(0, 3).toUpperCase()}_0${allWorkExperiences.indexOf(exp) + 1}",
                style: GoogleFonts.vt323(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // 4. THEFT MARK (COMPLETED STAMP)
          Positioned(
            top: -15,
            right: -10,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Text(
                  exp.period.contains("Present") ||
                          exp.period.contains("Currently")
                      ? "ACTIVE!"
                      : "CLEARED!",
                  style: GoogleFonts.blackOpsOne(
                    color: exp.period.contains("Present") ||
                            exp.period.contains("Currently")
                        ? const Color(0xFF00FFFF) // Cyan/Blue for Active
                        : const Color(0xFFFF0000), // Red for Cleared
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hudMiniChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.vt323(
          color: Colors.white.withOpacity(0.7),
          fontSize: 11.sp,
        ),
      ),
    );
  }

  Widget _buildTicTacToeView() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 600,
        ),
        child: CrtOverlay(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                  color: Colors.cyanAccent.withOpacity(0.5), width: 2),
            ),
            child: TicTacToe(onSpeak: _updateGlobalDialogue),
          ),
        ),
      ),
    );
  }

  Widget _buildRpsView() {
    return Center(child: RockPaperScissors(onSpeak: _updateGlobalDialogue));
  }

  Widget _buildPokerView() {
    return Center(child: PokerGame(onSpeak: _updateGlobalDialogue));
  }

  Widget _buildChessView() {
    return ChessGame(
      onClose: () => setState(() => _selectedIndex = -1),
      onSpeak: _updateGlobalDialogue,
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return "Terminal";
      case 1:
        return "File Manager/Projects";
      case 2:
        return "Certificates";
      case 3:
        return "Education";
      case 4:
        return "Profile";
      case 5:
        return "Work Experience";
      case 6:
        return "Tic Tac Toe";
      case 7:
        return "Rock Paper Scissors";
      case 8:
        return "5-Card Draw Poker";
      case 9:
        return "Chess";
      case 10:
        return "Image Lab";
      default:
        return "";
    }
  }

  void _postMessageToVrm(String text, {String? english, String? emotion}) {
    if (kIsWeb) {
      _vrmController.speak(text, english: english);
      if (emotion != null) {
        _vrmController.setEmotion(emotion);
      }
    }
  }

  // ==========================================
  // 🛳️ DOCK / TASKBAR WIDGET
  // ==========================================
  Widget _buildDock() {
    return Container(
      height: 70.h,
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dockIcon(0, FontAwesomeIcons.terminal, "Terminal"),
          SizedBox(width: 16.w),
          GestureDetector(
            onTap: _launchEmail,
            child: Tooltip(
              message: "Email",
              child: Icon(Icons.email, color: Colors.white, size: 24.r),
            ),
          ),
          SizedBox(width: 16.w),
          _dockIcon(4, FontAwesomeIcons.user, "Profile"),
        ],
      ),
    );
  }

  Widget _dockIcon(int index, IconData icon, String tooltip) {
    bool isSelected = _selectedIndex == index;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          int prev = _selectedIndex;
          setState(() {
            _selectedIndex = index;
            _triggerPersonalizedReaction(tooltip, index);
            if (index == 0 && prev != 0) {
              additionalTerminalOutput.clear();
              _showHelp();
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: isSelected ? const Color(0xFF50FA7B) : Colors.white,
                  size: 24.r),
              SizedBox(height: 4.h),
              if (isSelected)
                Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                        color: Color(0xFF50FA7B), shape: BoxShape.circle))
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopShortcut(int? index, IconData icon, String label,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: index != null
          ? () {
              int prev = _selectedIndex;
              setState(() {
                _selectedIndex = index!;
                _triggerPersonalizedReaction(label, index);
                if (index == 0 && prev != 0) {
                  additionalTerminalOutput.clear();
                  _showHelp();
                }
              });
            }
          : onTap,
      child: Column(
        children: [
          Icon(icon, size: 48.r, color: Colors.white),
          SizedBox(height: 5.h),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)]),
          ),
        ],
      ),
    );
  }

  Timer? _idleTimer;

  // Idle Logic
  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 20), _triggerIdleAction);
  }

  void _triggerIdleAction() {
    if (!mounted || _isGlobalSpeaking) return;

    // Resume Context Quips
    final osQuips = [
      "Visitor, checking the system logs... all clear! ♡",
      "Do you need me to open a project for you?",
      "I'm keeping an eye on the server status, don't worry!",
      "Master Angga, remember to stay hydrated while coding!",
      "Waiting for your next command, Visitor...",
      "Everything is running smoothly! ~",
      "Hehe~ This OS is really fast, isn't it?",
    ];

    final r = Random().nextInt(osQuips.length);
    _vrmController.speak(osQuips[r]);
  }

  // Head Tracking
  void _onHover(PointerEvent details) {
    if (!kIsWeb) return;

    final size = MediaQuery.of(context).size;
    double normX = (details.position.dx / size.width) * 2 - 1;
    // Fix: Remove inversion to look UP when mouse is UP
    double normY = (details.position.dy / size.height) * 2 - 1;

    _vrmController.lookAt(normX, normY);
    _resetIdleTimer();
  }

  void _triggerPersonalizedReaction(String label, int index) {
    String message = "Opening $label for you, Visitor! ♡";
    String emotion = 'fun';

    if (label.contains("Experience")) {
      message = "Here is for showcase what experience Master Angga have! ~";
      emotion = 'joy';
    } else if (label.contains("Projects")) {
      message = "Check out Master Angga's creative works! ♡";
      emotion = 'fun';
    } else if (label.contains("Education")) {
      message = "Master Angga is very studious! Here's his academic journey.";
      emotion = 'joy';
    } else if (label.contains("Poker") ||
        label.contains("TicTacToe") ||
        label.contains("RPS")) {
      message = "Ready to lose to me? Fufufu~ Let's play!";
      emotion = 'fun';
    } else if (label.contains("Image Lab")) {
      message =
          "Time to get creative with some images! Let me help you, Visitor~ ♡";
      emotion = 'joy';
    }
    //else if (label == "Spotify") {
    //   message = "Let's listen to some music together, Visitor! ♪";
    //   emotion = 'joy';
    // }

    _vrmController.speak(message, emotion: emotion);
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return MouseRegion(
      onHover: _onHover,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. Background Image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/bg.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // 2. Backdrop + Sakura Particles
            Container(color: Colors.black.withOpacity(0.2)),
            const Positioned.fill(
              child: IgnorePointer(child: SakuraParticles()),
            ),

            // 3. VRM Holo-Pod Container (Static Position for Stability)
            if (kIsWeb)
              Positioned(
                key: const ValueKey('vrm-pod'),
                bottom: 20.h,
                left: 20.w,
                width: 300.w,
                height: 400.h,
                child: IgnorePointer(
                  ignoring: true,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: 280.w,
                        height: 350.h,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Colors.cyanAccent.withOpacity(0.5),
                                width: 2),
                            left: BorderSide(
                                color: Colors.cyanAccent.withOpacity(0.3),
                                width: 1),
                            right: BorderSide(
                                color: Colors.cyanAccent.withOpacity(0.3),
                                width: 1),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.cyanAccent.withOpacity(0.05),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                          bottom: 0,
                          left: -20,
                          right: -20,
                          top: 0,
                          child: VrmMaidView(
                            controller: _vrmController,
                            onReady: () {
                              _vrmController.speak(
                                  "System initialized. Welcome, Visitor! ♡",
                                  emotion: 'joy');
                            },
                          )),
                    ],
                  ),
                ),
              ),

            // 4. Desktop Shortcuts (Dynamic Vertical Wrap - PERSISTENT)
            Positioned(
              top: 40.h,
              left: 20.w,
              bottom: 420.h,
              child: SizedBox(
                width: 500.w,
                child: Builder(builder: (context) {
                  double iconWidth = 80.w;
                  double iconHeight = 90.h;

                  List<Widget> shortcuts = [
                    _desktopShortcut(0, FontAwesomeIcons.terminal, "Terminal"),
                    _desktopShortcut(1, FontAwesomeIcons.briefcase, "Projects"),
                    _desktopShortcut(
                        3, FontAwesomeIcons.graduationCap, "Education"),
                    _desktopShortcut(
                        5, FontAwesomeIcons.briefcase, "Experience"),
                    _desktopShortcut(6, FontAwesomeIcons.gamepad, "TicTacToe"),
                    _desktopShortcut(7, FontAwesomeIcons.dice, "RPS"),
                    _desktopShortcut(8, FontAwesomeIcons.diamond, "Poker"),
                    _desktopShortcut(9, FontAwesomeIcons.chess, "Chess"),
                    _desktopShortcut(10, FontAwesomeIcons.image, "Image Lab"),
                    _desktopShortcut(null, FontAwesomeIcons.robot, "Assistant",
                        onTap: openAiChat),
                    // _desktopShortcut(null, FontAwesomeIcons.spotify, "Spotify",
                    //     onTap: () =>
                    //         setState(() => _showSpotify = !_showSpotify)),
                  ];

                  return Wrap(
                    direction: Axis.vertical,
                    spacing: 10.h,
                    runSpacing: 20.w,
                    children: shortcuts
                        .map((w) => SizedBox(
                              width: iconWidth,
                              height: iconHeight,
                              child: Center(child: w),
                            ))
                        .toList(),
                  );
                }),
              ),
            ),

            // 4. Right-Side Widgets (Discord + Football Table) - Hidden on mobile
            if (!isMobile)
              Positioned(
                right: 10.w,
                top: 40.h,
                bottom: 100.h,
                child: SizedBox(
                  width: 280.w,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Discord Activity
                        DiscordActivityWidget(
                          isMinimized: _discordMinimized,
                          onToggleMinimize: () => setState(
                              () => _discordMinimized = !_discordMinimized),
                        ),
                        SizedBox(height: 12.h),
                        // Premier League Table
                        PremierLeagueTable(
                          isMinimized: _plTableMinimized,
                          onToggleMinimize: () => setState(
                              () => _plTableMinimized = !_plTableMinimized),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 5. Top Status Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 30.h,
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                color: Colors.black.withOpacity(0.9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(isMobile ? "APP" : "Applications",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp)),
                        if (!isMobile) ...[
                          _systemInfoChip(
                            Icons.memory,
                            "$_cpuCores cores • ${_fakeCpuLoad}%",
                          ),
                          SizedBox(width: 16.w),
                          _systemInfoChip(Icons.storage,
                              "~${_ramGb.toStringAsFixed(0)} GB"),
                        ],
                        SizedBox(width: 16.w),
                        _systemInfoChip(
                          Icons.cloud,
                          "$_weatherIcon ${_weatherTemp}°C • $_weatherDesc",
                        ),
                      ],
                    ),
                    Text(_currentTime,
                        style: TextStyle(color: Colors.white, fontSize: 12.sp)),
                    Row(
                      children: [
                        Icon(Icons.wifi, color: Colors.white, size: 14.sp),
                        SizedBox(width: 10.w),
                        if (!isMobile)
                          Icon(Icons.volume_up,
                              color: Colors.white, size: 14.sp),
                        SizedBox(width: 10.w),
                        Icon(Icons.battery_full,
                            color: Colors.white, size: 14.sp),
                      ],
                    )
                  ],
                ),
              ),
            ),

            // 6. Main Window Content - PUSHED RIGHT to avoid VRM
            if (_selectedIndex != -1)
              Positioned(
                top: 40.h,
                bottom: isMobile ? 120.h : 100.h,
                left: isMobile ? 10.w : 350.w, // Offset for VRM + Shortcuts
                right: isMobile ? 10.w : 300.w,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildBodyContent(),
                ),
              ),

            // 7. Integrated Tech Marquee + Dock - REACTIVE
            Positioned(
              left: 0,
              right: 0,
              bottom: 10.h,
              height: 100.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Marquee - Offset for VRM Box
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: isMobile ? 0 : 320.w), // Clear VRM Box
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.white,
                              Colors.white,
                              Colors.transparent
                            ],
                            stops: [0.0, 0.7, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: const TechStackMarquee(),
                      ),
                    ),
                  ),

                  // Adaptive Dock - Center
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: _buildDock(),
                  ),

                  // Right Marquee
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            Colors.white,
                            Colors.white
                          ],
                          stops: [0.0, 0.3, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: const TechStackMarquee(),
                    ),
                  ),
                ],
              ),
            ),

            // 8. Global Character Dialogue - Unified
            // 8. Global Character Dialogue - Unified

            // Dialogue Bubble - Positioned above Holo-Pod
            // Dialogue Bubble - Positioned above Holo-Pod
            // Only show on Desktop to avoid redundancy with game dialogues
            if (_isGlobalSpeaking && _selectedIndex == -1)
              Positioned(
                bottom: 420.h, // Just above the 400.h Holo-Pod
                left: 40.w,
                width: 400.w,
                child: VnDialogueBubble(
                  text: _globalDialogueEn ?? "",
                  subtitle: _globalDialogueJp,
                  isSpeaking: _isGlobalSpeaking,
                ),
              ),

            // 9. Spotify Player overlay
            // if (_showSpotify)
            //   Positioned(
            //     left: 50.w,
            //     bottom: 110.h,
            //     child: SpotifyPlayer(
            //       playlistId: '37i9dQZF1DX4sWSpwq3LiO',
            //       onClose: () => setState(() => _showSpotify = false),
            //     ),
            //   ),

            // 11. CRT Overlay (subtle retro scanlines)
            const Positioned.fill(
              child: IgnorePointer(child: CrtOverlay(child: SizedBox.expand())),
            ),
          ],
        ),
      ),
    );
  }

  // --- Project Section and Game UI Updates ---
}

// Simple cursor blinker for terminal
class BlinkCursor extends StatefulWidget {
  @override
  _BlinkCursorState createState() => _BlinkCursorState();
}

class _BlinkCursorState extends State<BlinkCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(width: 10, height: 20, color: const Color(0xFF50FA7B)),
    );
  }
}
// ... (keep all your previous imports and code up to TicTacToe class)

class TicTacToe extends StatefulWidget {
  final Function(String, {String? english, String? emotion}) onSpeak;

  const TicTacToe({super.key, required this.onSpeak});

  @override
  State<TicTacToe> createState() => _TicTacToeState();
}

class _TicTacToeState extends State<TicTacToe> {
  List<String> board = List.filled(9, '');
  bool playerTurn = true;
  String winner = '';
  bool isSpeaking = false;
  String currentDialogueJp = "";
  String? currentDialogueEn;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      _safeSpeak("ティックタックトーで遊ぼう！ あなたが先手でXだよ～♡",
          english: "Let's play Tic-Tac-Toe! You go first with X~♡");
    });
  }

  void _safeSpeak(String text, {String? english, String? emotion}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          currentDialogueJp = text;
          currentDialogueEn = english;
          isSpeaking = true;
        });
        widget.onSpeak(text, english: english, emotion: emotion);
      }
    });
  }

  void _playerTap(int i) {
    if (board[i] != '' || winner != '' || !playerTurn) return;
    setState(() {
      board[i] = 'X';
      playerTurn = false;
    });
    _checkWinner();
    if (winner == '') {
      List<String> moveQuips = [
        "そこに来たか～！",
        "ふふっ、いい場所だね！",
        "Sakuraを止められるかな？♡",
        "そこは予想外だよ～！",
      ];
      List<String> moveEng = [
        "So you chose there~!",
        "Fufu, good placement!",
        "Can you block Sakura? ♡",
        "That was unexpected~!",
      ];
      int idx = Random().nextInt(moveQuips.length);
      _safeSpeak(moveQuips[idx], english: moveEng[idx], emotion: "fun");

      Future.delayed(const Duration(milliseconds: 600), _vrmMove);
    }
  }

  void _vrmMove() {
    if (!mounted || winner != '') return;
    List<int> empty = [];
    for (int i = 0; i < 9; i++) if (board[i] == '') empty.add(i);
    if (empty.isNotEmpty) {
      List<String> tapQuips = [
        "ふふっ、そこなの？♡",
        "えいっ！ ここだよ～！",
        "負けないもんっ！",
        "Sakuraの番だね！"
      ];
      List<String> tapEng = [
        "Fufu, you chose there?♡",
        "Take that! Here I go~!",
        "I won't lose!",
        "My turn now!"
      ];
      int tidx = Random().nextInt(tapQuips.length);
      _safeSpeak(tapQuips[tidx], english: tapEng[tidx], emotion: "fun");

      setState(() {
        board[empty[Random().nextInt(empty.length)]] = 'O';
        playerTurn = true;
      });
      _checkWinner();
    }
  }

  void _checkWinner() {
    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];
    for (final line in lines) {
      if (board[line[0]] != '' &&
          board[line[0]] == board[line[1]] &&
          board[line[0]] == board[line[2]]) {
        setState(() => winner = board[line[0]]);
        if (winner == 'X') {
          _safeSpeak("うぅ～… 負けちゃった…💦",
              english: "Uuu~ I lost...💦", emotion: "sorrow");
        } else if (winner == 'O') {
          _safeSpeak("キャー！ 勝っちゃったよぉ～！",
              english: "Kyaa~! I won~!", emotion: "joy");
        }
        return;
      }
    }
    if (!board.contains('')) {
      setState(() => winner = 'Draw');
      _safeSpeak("引き分け～！ 楽しかったよぉ～♡",
          english: "Draw~! That was fun~♡", emotion: "fun");
    }
  }

  void _reset() {
    setState(() {
      board = List.filled(9, '');
      winner = '';
      playerTurn = true;
    });
  }

  Widget _buildArcadeButton(
      {required VoidCallback onPressed,
      required String label,
      required Color color}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), offset: const Offset(4, 4))
          ],
        ),
        child: Text(label,
            style: GoogleFonts.vt323(
                color: color, fontSize: 18.sp, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CrtOverlay(
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 500.w, maxHeight: 700.h),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.cyanAccent.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Glassmorphism background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1A1A2E).withOpacity(0.6),
                          const Color(0xFF16213E).withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                // Grid and Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      Text("NEON TACTICS",
                          style: GoogleFonts.orbitron(
                            color: Colors.cyanAccent,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            shadows: [
                              Shadow(
                                  color: Colors.cyanAccent.withOpacity(0.8),
                                  blurRadius: 10),
                            ],
                          )),
                      SizedBox(height: 10.h),
                      Container(
                        height: 2,
                        width: 100.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.cyanAccent,
                              Colors.transparent
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Animated Grid
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: SizedBox(
                          width: 280.w,
                          height: 280.w,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12),
                            itemCount: 9,
                            itemBuilder: (ctx, i) => GestureDetector(
                              onTap: () => _playerTap(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  color: board[i] == ''
                                      ? Colors.white.withOpacity(0.03)
                                      : (board[i] == 'X'
                                          ? Colors.cyanAccent.withOpacity(0.1)
                                          : Colors.pinkAccent.withOpacity(0.1)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: board[i] == ''
                                          ? Colors.white10
                                          : (board[i] == 'X'
                                              ? Colors.cyanAccent
                                              : Colors.pinkAccent),
                                      width: 1.5),
                                  boxShadow: board[i] == ''
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: (board[i] == 'X'
                                                    ? Colors.cyanAccent
                                                    : Colors.pinkAccent)
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                          )
                                        ],
                                ),
                                child: Center(
                                    child: AnimatedScale(
                                  duration: const Duration(milliseconds: 200),
                                  scale: board[i] == '' ? 0.0 : 1.0,
                                  child: Text(board[i],
                                      style: GoogleFonts.pressStart2p(
                                          color: board[i] == 'X'
                                              ? Colors.cyanAccent
                                              : Colors.pinkAccent,
                                          fontSize: 28.sp,
                                          shadows: [
                                            Shadow(
                                                color: (board[i] == 'X'
                                                    ? Colors.cyanAccent
                                                    : Colors.pinkAccent),
                                                blurRadius: 10),
                                          ])),
                                )),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (winner != '')
                        _buildArcadeButton(
                            onPressed: _reset,
                            label: "REBOOT MATCH",
                            color: Colors.pinkAccent)
                      else
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: playerTurn
                                    ? Colors.cyanAccent.withOpacity(0.5)
                                    : Colors.pinkAccent.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            playerTurn
                                ? "SYSTEM READY: PLAYER X"
                                : "UPLOADING: SAKURA O...",
                            style: GoogleFonts.vt323(
                              color: playerTurn
                                  ? Colors.cyanAccent
                                  : Colors.pinkAccent,
                              fontSize: 14.sp,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RockPaperScissors extends StatefulWidget {
  final Function(String, {String? english, String? emotion}) onSpeak;
  const RockPaperScissors({super.key, required this.onSpeak});
  @override
  _RockPaperScissorsState createState() => _RockPaperScissorsState();
}

class _RockPaperScissorsState extends State<RockPaperScissors> {
  String playerChoice = '';
  String vrmChoice = '';
  String result = '';
  bool isAnimating = false;

  @override
  void initState() {
    super.initState();
  }

  void _safeSpeak(String text, {String? english, String? emotion}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onSpeak(text, english: english, emotion: emotion);
    });
  }

  void _play(String choice) {
    if (isAnimating) return;
    setState(() {
      playerChoice = choice;
      isAnimating = true;
    });
    _safeSpeak("いくよ～！ せーのっ！",
        english: "Here we go! Ready... set...", emotion: "fun");
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      vrmChoice = ['ROCK', 'PAPER', 'SCISSORS'][Random().nextInt(3)];
      if (playerChoice == vrmChoice) {
        result = 'Draw';
        _safeSpeak("あいこ～！ またやろっ♡",
            english: "Tie~! Let's play again♡", emotion: "fun");
      } else if ((playerChoice == 'ROCK' && vrmChoice == 'SCISSORS') ||
          (playerChoice == 'PAPER' && vrmChoice == 'ROCK') ||
          (playerChoice == 'SCISSORS' && vrmChoice == 'PAPER')) {
        result = 'You Win!';
        _safeSpeak("うぅ～… 負けちゃった…💦",
            english: "Uuu~ I lost...💦", emotion: "sorrow");
      } else {
        result = 'Sakura Wins!';
        _safeSpeak("キャー！ 勝っちゃったよぉ～！ 嬉しい～！",
            english: "Kyaa~! I won~! So happy~!", emotion: "joy");
      }
      setState(() => isAnimating = false);
    });
  }

  void _reset() {
    setState(() {
      playerChoice = '';
      vrmChoice = '';
      result = '';
    });
  }

  Widget _buildArcadeButton(
      {required VoidCallback onPressed,
      required String label,
      required Color color}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), offset: const Offset(4, 4))
          ],
        ),
        child: Text(label,
            style: GoogleFonts.vt323(
                color: color, fontSize: 18.sp, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildChoiceCard(String label, String choice, Color color) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.vt323(color: Colors.white, fontSize: 16.sp)),
        SizedBox(height: 10.h),
        Container(
          width: 100.w,
          height: 120.h,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: color.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.2), offset: const Offset(2, 2))
            ],
          ),
          child: Center(
            child: Text(
              choice == '' ? '?' : choice.substring(0, 1),
              style: GoogleFonts.vt323(
                  color: color, fontSize: 48.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (choice != '')
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(choice,
                style: GoogleFonts.vt323(color: color, fontSize: 14.sp)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CrtOverlay(
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: Colors.cyanAccent.withOpacity(0.5), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("NEO-DUEL",
                    style: GoogleFonts.vt323(
                        color: Colors.white, fontSize: 32.sp)),
                SizedBox(height: 20.h),
                if (result != '')
                  Text(result.toUpperCase(),
                      style: GoogleFonts.vt323(
                          color: Colors.yellowAccent, fontSize: 28.sp)),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildChoiceCard("YOU", playerChoice, Colors.cyanAccent),
                    SizedBox(width: 40.w),
                    _buildChoiceCard("SAKURA", vrmChoice, Colors.pinkAccent),
                  ],
                ),
                SizedBox(height: 30.h),
                if (playerChoice == '')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildArcadeButton(
                          onPressed: () => _play('ROCK'),
                          label: "ROCK",
                          color: Colors.cyanAccent),
                      SizedBox(width: 12.w),
                      _buildArcadeButton(
                          onPressed: () => _play('PAPER'),
                          label: "PAPER",
                          color: Colors.cyanAccent),
                      SizedBox(width: 12.w),
                      _buildArcadeButton(
                          onPressed: () => _play('SCISSORS'),
                          label: "SCISSORS",
                          color: Colors.cyanAccent),
                    ],
                  )
                else
                  _buildArcadeButton(
                      onPressed: _reset,
                      label: "DUEL AGAIN",
                      color: Colors.purpleAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
