import 'package:animate_do/animate_do.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_test/model/Education_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'model/ProjectGrid.dart';
import 'model/resume_generator.dart';
import 'model/certificate_card.dart';
import 'package:dev_icons/dev_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_test/widget/ai_chat_panel.dart';
import 'package:project_test/widget/Loader_Gate.dart';
import '../model/chat_message.dart';
import 'package:project_test/widget/vrm_maid_view.dart';
import 'dart:async'; // For clock
import 'dart:math';
import 'dart:convert'; // jsonDecode
import 'package:geolocator/geolocator.dart'; // Browser geolocation
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; // Open-Meteo API calls
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import '../llm/llm_service.dart';
import 'widget/poker.dart';

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
  String _weatherDesc = "Loading...";
  String _locationText = "Detecting...";
  int _cpuCores = 0;
  double _ramGb = 0.0;
  int _fakeCpuLoad = 35; // we'll animate it a bit
  Timer? _cpuLoadTimer; // Timer reference for proper disposal
  @override
  void initState() {
    super.initState();
    _loadRealWeather();
    _appStartTime = DateTime.now();
    _updateTime();
    _cpuCores = js.context['navigator']['hardwareConcurrency'] ?? 4;
    final ramStr = js.context['navigator']['deviceMemory']?.toString() ?? "8";
    _ramGb = double.tryParse(ramStr) ?? 8.0;
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

  String _getJsValue(String path) {
    try {
      var obj = js.context;
      for (var part in path.split('.')) {
        obj = obj[part];
      }
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

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
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
      else if (target == "tic_tac_toe")
        index = 5;
      else if (target == "rock_paper_scissors")
        index = 6;
      else if (target == "resume.pdf") {
        final resumePdf = ResumePdf();
        final pdfBytes = await resumePdf.generate();
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
      final freeGb = totalGb - usedGb;
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
                  SizedBox(width: 50.w), // Balance text
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
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.r),
                  child: child, // ← your GridView / Column etc. goes here
                ),
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
                        final pdfBytes = await resumePdf.generate();
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

  Widget _profileInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12.sp,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
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
        content = GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 0.75, // Slightly adapted
          mainAxisSpacing: 20.0,
          crossAxisSpacing: 20.0,
          children: const [
            ProjectGrid(
              name: "Go Fit",
              language: "HTML, JS",
              platform: Icon(FontAwesomeIcons.globe, color: Colors.blue),
              url: "https://github.com/Windstrom5/Go-Fit-android",
              imageUrl:
                  "https://raw.githubusercontent.com/Windstrom5/Go-Fit-android/master/app/src/main/res/drawable/logo.png",
            ),
            ProjectGrid(
              name: "Go Fit Android",
              language: "Kotlin",
              platform: Icon(FontAwesomeIcons.android, color: Colors.green),
              url: "https://github.com/Windstrom5/go_fit",
              imageUrl:
                  "https://raw.githubusercontent.com/Windstrom5/Go-Fit-android/master/app/src/main/res/drawable/logo.png",
            ),
            ProjectGrid(
              name: "WorkHubs",
              language: "Kotlin",
              platform: Icon(FontAwesomeIcons.android, color: Colors.green),
              url: "https://github.com/Windstrom5/Workhubs-Android-App",
              imageUrl:
                  "https://raw.githubusercontent.com/Windstrom5/Workhubs-Android-App/master/app/src/main/res/drawable/logo.png",
            ),
            ProjectGrid(
              name: "NihonGo",
              language: "Kotlin",
              platform: Icon(FontAwesomeIcons.android, color: Colors.green),
              url: "https://github.com/Windstrom5/backend_tugas_akhir",
              imageUrl:
                  "https://raw.githubusercontent.com/Windstrom5/nihonGO/master/app/src/main/res/drawable/logo.png",
            ),
          ],
        );
        break;
      case 2:
        content = GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          childAspectRatio: 0.7,
          mainAxisSpacing: 20.0,
          crossAxisSpacing: 20.0,
          children: const [
            CertificateCard(
              certificateName: "Researcher Management",
              organizationName: "University of Colorado",
              imagePath: "assets/Coursera WHAJ3WB5FKZB_page-0001.jpg",
            ),
            CertificateCard(
              certificateName: "English Score",
              organizationName: "British Council",
              imagePath: "assets/EnglishScore.jpg",
            ),
          ],
        );
        break;
      case 3:
        content = GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          childAspectRatio: 0.7,
          mainAxisSpacing: 20.0,
          crossAxisSpacing: 20.0,
          children: const [
            EducationCard(
                name: "SDN 001 Sungai Kunjang",
                location: "Samarinda",
                years: "2008-2014",
                imagePath: "assets/sdn.jpg",
                mapsUrl:
                    "https://www.google.com/maps/place/SD+Negeri+001/@-0.498135,117.1203361,17z/data=!3m1!4b1!4m6!3m5!1s0x2df67efe8db30583:0x5f632eb0108b6f42!8m2!3d-0.498135!4d117.122911!16s%2Fg%2F11b7q6zjzb?entry=ttu"),
            EducationCard(
                name: "Universitas Atma Jaya",
                location: "Yogyakarta",
                years: "2020-Present",
                imagePath: "assets/atma.jpg",
                mapsUrl:
                    "https://www.google.com/maps/place/Universitas+Atma+Jaya+Yogyakarta+-+Kampus+3+Gedung+Bonaventura+Babarsari/@-7.7794195,110.4135542,17z/data=!3m1!4b1!4m6!3m5!1s0x2e7a59f1fb2f2b45:0x20986e2fe9c79cdd!8m2!3d-7.7794195!4d110.4161291!16s%2Fg%2F11cfg5l4w?entry=ttu"),
          ],
        );
        break;
      case 4:
        content = Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 500.w),
            padding: EdgeInsets.all(30.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade900.withOpacity(0.6),
                  Colors.blue.shade900.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Avatar with glow
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60.r,
                    backgroundColor: Colors.cyan.withOpacity(0.2),
                    backgroundImage: const AssetImage('assets/profile.jpg'),
                  ),
                ),
                SizedBox(height: 20.h),
                // Name with gradient
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.cyanAccent, Colors.purpleAccent],
                  ).createShader(bounds),
                  child: Text(
                    "Angga Nugraha",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                  ),
                  child: Text(
                    "Full Stack Developer",
                    style: TextStyle(color: Colors.cyanAccent, fontSize: 14.sp),
                  ),
                ),
                SizedBox(height: 24.h),
                // Info cards
                _profileInfoCard(
                    Icons.location_on, "Location", "Yogyakarta, Indonesia"),
                SizedBox(height: 10.h),
                _profileInfoCard(Icons.email, "Email", "angga@example.com"),
                SizedBox(height: 24.h),
                // Skills section
                Text(
                  "⚡ Tech Stack",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _skillChip("Flutter", Colors.blue),
                    _skillChip("Kotlin", Colors.purple),
                    _skillChip("Vue.js", Colors.green),
                    _skillChip("Laravel", Colors.red),
                    _skillChip("Java", Colors.orange),
                    _skillChip("Dart", Colors.cyan),
                  ],
                ),
                SizedBox(height: 24.h),
                // Bio
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    "🎮 Passionate Full Stack Developer from Yogyakarta, specializing in mobile & web development. Enthusiast in Gaming Tech & Innovation.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14.sp,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
        break;
      case 5:
        content = LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final vrmWidth =
                (maxWidth * 0.18).clamp(150.0, 200.0); // Smaller VRM
            final gameWidth = maxWidth - vrmWidth;

            return SizedBox(
              height: MediaQuery.of(context).size.height *
                  0.8, // 👈 BOUND THE HEIGHT
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // VRM (left side)
                  SizedBox(
                    width: vrmWidth,
                    child: kIsWeb ? VrmMaidView() : const SizedBox.shrink(),
                  ),

                  // Game area — FIXED (NO Expanded in infinite height)
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 600,
                          maxHeight: 600, // 👈 HARD LIMIT = NO INFINITE HEIGHT
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: TicTacToe(
                            onSpeak: _postMessageToVrm,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
        break;
      case 6:
        content = Row(
          children: [
            if (kIsWeb)
              SizedBox(
                width: 300.w,
                height: 500.h,
                child: VrmMaidView(),
              ),
            Expanded(
              child: RockPaperScissors(onSpeak: _postMessageToVrm),
            ),
          ],
        );
        break;
      case 7:
        content = Row(
          children: [
            if (kIsWeb)
              SizedBox(
                width: 300.w,
                height: 500.h,
                child: VrmMaidView(),
              ),
            Expanded(
              child: PokerGame(onSpeak: _postMessageToVrm),
            ),
          ],
        );
        break;
      default:
        content = Container();
    }
    return _buildWindowFrame(title: _getTitle(_selectedIndex), child: content);
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
        return "Tic Tac Toe";
      case 6:
        return "Rock Paper Scissors";
      case 7:
        return "5-Card Draw Poker";

      default:
        return "";
    }
  }

  void _postMessageToVrm(String text, {String? english}) {
    if (kIsWeb) {
      try {
        var document = js.context['document'];
        var iframe = js_util.callMethod(
            document, 'querySelector', ['iframe[src="vrm/index.html"]']);
        if (iframe != null) {
          var contentWindow = js_util.getProperty(iframe, 'contentWindow');
          if (contentWindow != null) {
            // Send bilingual format: Japanese for voice, English for display
            js_util.callMethod(contentWindow, 'postMessage', [
              js_util.jsify({
                'type': 'speak',
                'japanese': text,
                'english': english ?? _translateToEnglish(text),
              }),
              '*'
            ]);
          } else {
            print(
                'VRM iframe contentWindow not available - voice skipped: $text');
          }
        } else {
          print('VRM iframe not found - voice skipped: $text');
        }
      } catch (e) {
        print('VRM postMessage error: $e - text: $text');
      }
    }
  }

  /// Simple translation helper for common game phrases (Japanese -> English)
  String _translateToEnglish(String japanese) {
    // Common TicTacToe phrases
    final translations = <String, String>{
      // TicTacToe - Updated visitor-friendly voice lines
      "ティックタックトーで遊ぼう！ あなたが先手でXだよ～♡":
          "Let's play Tic-Tac-Toe! You go first with X~♡",
      "わぁ～！ そこに置いたんだ～？♡": "Wow~! You placed it there~?♡",
      "えへへ、Xだね～！ ドキドキする～": "Ehehe, it's an X~! So exciting~",
      "ふふっ、次はSakuraの番だよ～！": "Fufu, it's Sakura's turn now~!",
      "上手～！ でも負けないからねっ♡": "Nice move~! But I won't lose~♡",
      "きゃっ、そこは危ないよ～！": "Kyaa, that spot is dangerous~!",
      "ここに〇だよ～♡": "I'll put O here~♡",
      "えへへ、Sakuraの〇～！": "Ehehe, Sakura's O~!",
      "ふふっ、どうかな～？": "Fufu, how's that~?",
      "置いちゃった～！ 見ててね♡": "I placed it~! Watch me♡",
      "やったー！ Sakuraの勝ち～！✨": "Yay~! Sakura wins~!✨",
      "えへへ～ 勝っちゃった♡": "Ehehe~ I won♡",
      "キャー！ 勝っちゃったよぉ～！": "Kyaa~! I won~!",
      "うぅ～… 強すぎるよぉ…💦": "Uuu~ You're too strong...💦",
      "負けちゃった…でも楽しかった～♡": "I lost... but it was fun~♡",
      "くぅ～！ 次は絶対勝つからねっ！": "Kuu~! I'll definitely win next time!",
      "あいこだよ～！ また遊ぼうね♡": "It's a tie~! Let's play again♡",
      "ふふっ、どっちもすごかった～！": "Fufu, we were both great~!",
      "引き分け～！ 楽しかったよぉ～♡": "Draw~! That was fun~♡",
      "リセットしたよ～！ また最初からだよ♡": "Reset~! Let's start again♡",
      "もう一回遊ぼうね～！ 準備OK～！": "Let's play again~! Ready~!",
      "えへへ、がんばろっ♡": "Ehehe, let's do our best♡",

      // Rock Paper Scissors - Updated visitor-friendly voice lines
      "じゃんけんぽんしよう～！ 最初に出してね♡": "Let's play Rock-Paper-Scissors~ Go first♡",
      "リセットしたよ～！ またじゃんけんしよう♡": "Reset~! Let's play again♡",
      // VRM choose templates
      "Sakuraは…じゃんけん…Rock！": "Sakura... janken... Rock!",
      "Sakuraは…じゃんけん…Paper！": "Sakura... janken... Paper!",
      "Sakuraは…じゃんけん…Scissors！": "Sakura... janken... Scissors!",
      "わぁ～！ それだね～♡": "Waa~! That's your choice~♡",
      "えへへ、きた～！ ドキドキするよぉ": "Ehehe, here it comes~! So exciting~",
      "ふふっ、Sakuraも負けないよ～！": "Fufu, Sakura won't lose either~!",
      "きゃっ！ ずるい～♡": "Kyaa~! That's sneaky~♡",
      "えへへ～ 私のはこれだよ～♡": "Ehehe~ This is mine~♡",
      "ふふっ、で勝負だよ～！": "Fufu, let's battle~!",
      "いくよ～！ だよっ！": "Here I go~! This is it~!",
      // RPS specific win/lose/draw
      "キャー！ 勝っちゃったよぉ～！ 嬉しい～！": "Kyaa~! I won~! So happy~!",
      "うぅ～… 負けちゃった…💦": "Uuu~ I lost...💦",
      "くぅ～！ でも楽しかったよ～♡ 次は勝つからねっ！": "Kuu~! But it was fun~♡ I'll win next time!",
      "え～ん… 強すぎるよぉ…！": "Eh~n... You're too strong~!",
      "あいこ～！ またやろっ♡": "Tie~! Let's play again♡",
      "ふふっ、どっちも同じだね～！ 楽しかった～": "Fufu, we chose the same~! That was fun~",
      "引き分けだよ～！ 同じで嬉しい♡": "It's a draw~! Happy we matched♡",

      // Poker - Updated visitor-friendly voice lines
      "ポーカー始めよ～！ カード配るね♡": "Let's start Poker~! Dealing cards♡",
      "えへへ、ドキドキする～！ がんばって！": "Ehehe, so exciting~! Do your best!",
      "ふふっ、Sakura強いよ～？ 負けないからねっ♡": "Fufu, Sakura is strong~? I won't lose~♡",
      "ここ raise よ～！ どう？♡": "I'm raising here~! How about that?♡",
      "えへへ、bet up～！ あなたの番だよ～": "Ehehe, bet up~! Your turn~",
      "ふふっ、強い手かも～？  raise！": "Fufu, maybe a strong hand~? Raise!",
      "call するよ～♡": "I'll call~♡",
      "ふふっ、OK～！ 次行こっ": "Fufu, OK~! Let's go next",
      "えへへ、call！ ドキドキ～": "Ehehe, call! So exciting~",
      "check だよ～♡": "Check~♡",
      "ふふっ、check！ どうぞ～": "Fufu, check! Your turn~",
      "うぅ～ fold… 勝っちゃった♡": "Uuu~ fold... You won♡",
      "くぅ～ 次は勝つよぉ～！": "Kuu~ I'll win next time~!",
      "fold したの？ Sakuraの勝ち～♡": "You folded? Sakura wins~♡",
      "キャー！ 嬉しいよぉ～！": "Kyaa~! I'm so happy~!",
      "split pot だよ～！ ふふっ、平等ね♡": "Split pot~! Fufu, it's fair♡",
      "あいこ～！ また遊ぼう～": "Tie~! Let's play again~",
      "flop きたよ～！ どうかな♡": "The flop is here~! How is it?♡",
      "えへへ、board オープン～！": "Ehehe, board revealed~!",
      "turn だよ～♡ ドキドキ～": "It's the turn~♡ So exciting~",
      "ふふっ、次の一枚～！": "Fufu, the next card~!",
      "river よ～！ 最終だね♡": "The river~! This is the final one♡",
      "えへへ、これで決まるよ～！": "Ehehe, this will decide it~!",
    };

    return translations[japanese] ?? japanese;
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
          SizedBox(width: 15.w),
          _dockIcon(1, FontAwesomeIcons.folderOpen, "Projects"),
          SizedBox(width: 15.w),
          _dockIcon(2, FontAwesomeIcons.trophy, "Awards"),
          SizedBox(width: 15.w),
          _dockIcon(3, FontAwesomeIcons.graduationCap, "Education"),
          SizedBox(width: 15.w),
          _dockIcon(4, FontAwesomeIcons.user, "Profile"),
          SizedBox(width: 15.w),
          _dockIcon(5, FontAwesomeIcons.gamepad, "TicTacToe"),
          SizedBox(width: 15.w),
          _dockIcon(6, FontAwesomeIcons.dice, "RPS"),
          SizedBox(width: 15.w),
          _dockIcon(7, FontAwesomeIcons.diamond,
              "Poker"), // or FontAwesomeIcons.diamond / gamepad
          Container(
            height: 40.h,
            width: 1,
            color: Colors.grey.withOpacity(0.5),
            margin: EdgeInsets.symmetric(horizontal: 15.w),
          ),
          _linkIcon(FontAwesomeIcons.github, "https://github.com/Windstrom5"),
          SizedBox(width: 15.w),
          _linkIcon(FontAwesomeIcons.discord,
              "https://discordapp.com/users/411135817449340929"),
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

  Widget _linkIcon(IconData icon, String url) {
    return GestureDetector(
      onTap: () => _launchURL(url),
      child: Icon(icon, color: Colors.white, size: 24.r),
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
          Text(label,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  shadows: [Shadow(color: Colors.black, blurRadius: 2)])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/bg.jpg'), // Ensure this is a cool wallpaper
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. Backdrop Blur (Glassmorphism for desktop feel)
          Container(
            color: Colors.black.withOpacity(0.2),
          ),

          Positioned(
            left: 100.w, // Shifted right to avoid overlap with vertical dock
            top: 80.h, // more top padding (macOS style starts lower)
            right: 20.w,
            bottom: 140.h, // more bottom space for your dock/taskbar
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate how many icons can fit vertically (using full height)
                const double iconHeight =
                    90; // Height per icon including spacing
                const double iconWidth = 80; // Fixed width for proper alignment
                const double columnSpacing = 32; // Space between columns

                final int iconsPerColumn =
                    (constraints.maxHeight / iconHeight).floor().clamp(1, 10);

                // All shortcuts in order
                final shortcuts = [
                  _desktopShortcut(0, FontAwesomeIcons.terminal, "Terminal"),
                  _desktopShortcut(1, FontAwesomeIcons.folderOpen, "Projects"),
                  _desktopShortcut(2, FontAwesomeIcons.trophy, "Certificates"),
                  _desktopShortcut(
                      3, FontAwesomeIcons.graduationCap, "Education"),
                  _desktopShortcut(4, FontAwesomeIcons.user, "Profile"),
                  _desktopShortcut(5, FontAwesomeIcons.gamepad, "TicTacToe"),
                  _desktopShortcut(6, FontAwesomeIcons.dice, "RPS"),
                  _desktopShortcut(7, FontAwesomeIcons.diamond, "Poker"),
                  _desktopShortcut(null, FontAwesomeIcons.robot, "Assistant",
                      onTap: openAiChat),
                ];

                // Build columns first (Windows-style), fill full height
                List<Widget> columns = [];
                for (int i = 0; i < shortcuts.length; i += iconsPerColumn) {
                  List<Widget> columnItems = [];
                  for (int j = i;
                      j < i + iconsPerColumn && j < shortcuts.length;
                      j++) {
                    columnItems.add(
                      SizedBox(
                        width: iconWidth,
                        height: iconHeight,
                        child: Center(child: shortcuts[j]),
                      ),
                    );
                  }
                  columns.add(
                    SizedBox(
                      width: iconWidth + columnSpacing,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: columnItems,
                      ),
                    ),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: columns,
                );
              },
            ),
          ),

          // 3. Top Status Bar
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
                      Text("Applications",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp)),
                      _systemInfoChip(
                        Icons.memory,
                        "$_cpuCores cores • ${_fakeCpuLoad}%",
                      ),

                      SizedBox(width: 16.w),

                      // Real RAM (browser estimate)
                      _systemInfoChip(
                          Icons.storage, "~${_ramGb.toStringAsFixed(0)} GB"),

                      SizedBox(width: 16.w),

                      // Real Weather
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
                      Icon(Icons.volume_up, color: Colors.white, size: 14.sp),
                      SizedBox(width: 10.w),
                      Icon(Icons.battery_full,
                          color: Colors.white, size: 14.sp),
                    ],
                  )
                ],
              ),
            ),
          ),

          // 4. Main Window Content
          Positioned.fill(
            top: 40.h,
            bottom: 100.h,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildBodyContent(),
            ),
          ),

          // 5. Bottom Dock
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeInUp(
              duration: const Duration(milliseconds: 1000),
              child: _buildDock(),
            ),
          ),
        ],
      ),
    );
  }
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
  final Function(String) onSpeak;

  const TicTacToe({super.key, required this.onSpeak});

  @override
  State<TicTacToe> createState() => _TicTacToeState();
}

class _TicTacToeState extends State<TicTacToe>
    with SingleTickerProviderStateMixin {
  List<String> board = List.filled(9, '');
  bool playerTurn = true; // Player = X, VRM = O
  String winner = '';
  bool isSpeaking = false; // Block actions during speech

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  final List<String> playerMoveReactions = [
    "わぁ～！ そこに置いたんだ～？♡",
    "えへへ、Xだね～！ ドキドキする～",
    "ふふっ、次はSakuraの番だよ～！",
    "上手～！ でも負けないからねっ♡",
    "きゃっ、そこは危ないよ～！",
  ];

  final List<String> vrmPlaceComments = [
    "ここに〇だよ～♡",
    "えへへ、Sakuraの〇～！",
    "ふふっ、どうかな～？",
    "置いちゃった～！ 見ててね♡",
  ];

  final List<String> vrmWinComments = [
    "やったー！ Sakuraの勝ち～！✨",
    "えへへ～ 勝っちゃった♡",
    "キャー！ 勝っちゃったよぉ～！",
  ];

  final List<String> vrmLoseComments = [
    "うぅ～… 強すぎるよぉ…💦",
    "負けちゃった…でも楽しかった～♡",
    "くぅ～！ 次は絶対勝つからねっ！",
  ];

  final List<String> vrmDrawComments = [
    "あいこだよ～！ また遊ぼうね♡",
    "ふふっ、どっちもすごかった～！",
    "引き分け～！ 楽しかったよぉ～♡",
  ];

  final List<String> vrmResetComments = [
    "リセットしたよ～！ また最初からだよ♡",
    "もう一回遊ぼうね～！ 準備OK～！",
    "えへへ、がんばろっ♡",
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      _safeSpeak("ティックタックトーで遊ぼう！ あなたが先手でXだよ～♡");
    });
  }

  /// Safely call onSpeak after the current frame to avoid setState during build
  /// Also sets isSpeaking to true and schedules unlock
  void _safeSpeak(String text) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => isSpeaking = true);
        widget.onSpeak(text);
        // Auto-unlock after estimated speech duration (3 seconds)
        Future.delayed(const Duration(milliseconds: 3000), () {
          if (mounted) {
            setState(() => isSpeaking = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _playerTap(int index) {
    // Block if speaking, cell taken, game over, or not player turn
    if (isSpeaking || board[index] != '' || winner != '' || !playerTurn) return;

    setState(() {
      board[index] = 'X';
      playerTurn = false;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && winner == '') {
        _safeSpeak(
          playerMoveReactions[Random().nextInt(playerMoveReactions.length)],
        );
      }
    });

    _checkWinner();

    if (winner == '') {
      _vrmMove();
    }
  }

  void _vrmMove() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || winner != '') return;

      final empty = <int>[];
      for (int i = 0; i < 9; i++) {
        if (board[i] == '') empty.add(i);
      }

      if (empty.isNotEmpty) {
        final move = empty[Random().nextInt(empty.length)];
        setState(() {
          board[move] = 'O';
          playerTurn = true;
        });

        _safeSpeak(
          vrmPlaceComments[Random().nextInt(vrmPlaceComments.length)],
        );

        _checkWinner();
      }
    });
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

    bool hasResult = false;
    String resultComment = '';

    for (final line in lines) {
      final a = board[line[0]];
      if (a != '' && a == board[line[1]] && a == board[line[2]]) {
        winner = a;
        resultComment = a == 'X'
            ? vrmLoseComments[Random().nextInt(vrmLoseComments.length)]
            : vrmWinComments[Random().nextInt(vrmWinComments.length)];
        hasResult = true;
        break;
      }
    }

    if (!hasResult && !board.contains('')) {
      winner = 'Draw';
      resultComment = vrmDrawComments[Random().nextInt(vrmDrawComments.length)];
      hasResult = true;
    }

    setState(() {});

    if (hasResult) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _safeSpeak(resultComment);
        }
      });

      _animController.forward(from: 0).then((_) {
        if (mounted) {
          _animController.reset();
        }
      });
    }
  }

  void _reset() {
    setState(() {
      board = List.filled(9, '');
      winner = '';
      playerTurn = true;
    });

    _safeSpeak(
      vrmResetComments[Random().nextInt(vrmResetComments.length)],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = MediaQuery.of(context).size;

        // SAFETY: handle infinite constraints
        final maxW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : screen.width;

        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : screen.height;

        double side = min(maxW * 0.8, maxH * 0.55);

        // HARD CLAMP
        side = side.clamp(260.0, 420.0);

        final double cellFontSize = (side / 5).clamp(28.0, 100.0);

        return Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.shade900.withOpacity(0.5),
                  Colors.purple.shade900.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  "⭐ TIC TAC TOE ⭐",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(blurRadius: 10, color: Colors.cyanAccent),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // GRID
                Container(
                  width: side,
                  height: side,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 9,
                    itemBuilder: (ctx, i) {
                      final cell = board[i];
                      return GestureDetector(
                        onTap: () => _playerTap(i),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: cell == ''
                                  ? [Colors.grey.shade800, Colors.grey.shade900]
                                  : cell == 'X'
                                      ? [
                                          Colors.cyan.shade800.withOpacity(0.4),
                                          Colors.cyan.shade900.withOpacity(0.2)
                                        ]
                                      : [
                                          Colors.pink.shade800.withOpacity(0.4),
                                          Colors.pink.shade900.withOpacity(0.2)
                                        ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cell == ''
                                  ? Colors.white.withOpacity(0.2)
                                  : cell == 'X'
                                      ? Colors.cyanAccent.withOpacity(0.6)
                                      : Colors.pinkAccent.withOpacity(0.6),
                              width: 2,
                            ),
                            boxShadow: cell != ''
                                ? [
                                    BoxShadow(
                                      color: cell == 'X'
                                          ? Colors.cyanAccent.withOpacity(0.3)
                                          : Colors.pinkAccent.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              cell,
                              style: TextStyle(
                                color: cell == 'X'
                                    ? Colors.cyanAccent
                                    : cell == 'O'
                                        ? Colors.pinkAccent
                                        : Colors.transparent,
                                fontSize: cellFontSize,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Status
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: winner != '' ? _scaleAnimation.value : 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: winner != ''
                              ? (winner == 'X'
                                      ? Colors.cyan
                                      : winner == 'O'
                                          ? Colors.pink
                                          : Colors.yellow)
                                  .withOpacity(0.2)
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: winner != ''
                                ? (winner == 'X'
                                    ? Colors.cyanAccent
                                    : winner == 'O'
                                        ? Colors.pinkAccent
                                        : Colors.yellowAccent)
                                : Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          winner == ''
                              ? (playerTurn
                                  ? "🎯 Your turn (X)"
                                  : "🌸 Sakura's turn (O)")
                              : winner == 'Draw'
                                  ? "🤝 It's a Draw!"
                                  : winner == 'X'
                                      ? "🏆 You Win!"
                                      : "🌸 Sakura Wins!",
                          style: TextStyle(
                            color: winner == ''
                                ? Colors.white
                                : winner == 'Draw'
                                    ? Colors.yellowAccent
                                    : winner == 'X'
                                        ? Colors.cyanAccent
                                        : Colors.pinkAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh, size: 22),
                  label: const Text(
                    'Play Again',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12),
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 8,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Keep RockPaperScissors as is, or add similar Japanese comments if you want
class RockPaperScissors extends StatefulWidget {
  final Function(String) onSpeak;

  const RockPaperScissors({super.key, required this.onSpeak});

  @override
  _RockPaperScissorsState createState() => _RockPaperScissorsState();
}

class _RockPaperScissorsState extends State<RockPaperScissors>
    with SingleTickerProviderStateMixin {
  String playerChoice = '';
  String vrmChoice = '';
  String result = '';
  bool isAnimating = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  // Base voice line templates (no $playerChoice here)
  final List<String> playerChooseReactions = [
    "わぁ～！ それだね～♡",
    "えへへ、きた～！ ドキドキするよぉ",
    "ふふっ、Sakuraも負けないよ～！",
    "きゃっ！ ずるい～♡",
  ];

  final List<String> vrmChooseComments = [
    "Sakuraは…じゃんけん…〇〇！",
    "えへへ～ 私のはこれだよ～♡",
    "ふふっ、で勝負だよ～！",
    "いくよ～！ だよっ！",
  ];

  final List<String> vrmWinComments = [
    "やった～！ Sakuraの勝ち～！✨",
    "えへへ～ 勝っちゃった♡",
    "キャー！ 勝っちゃったよぉ～！ 嬉しい～！",
  ];

  final List<String> vrmLoseComments = [
    "うぅ～… 負けちゃった…💦",
    "くぅ～！ でも楽しかったよ～♡ 次は勝つからねっ！",
    "え～ん… 強すぎるよぉ…！",
  ];

  final List<String> vrmDrawComments = [
    "あいこ～！ またやろっ♡",
    "ふふっ、どっちも同じだね～！ 楽しかった～",
    "引き分けだよ～！ 同じで嬉しい♡",
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      _safeSpeak("じゃんけんぽんしよう～！ 最初に出してね♡");
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _colorAnimation = ColorTween(begin: Colors.white, end: Colors.yellowAccent)
        .animate(_animController);
  }

  /// Safely call onSpeak after the current frame to avoid setState during build
  void _safeSpeak(String text) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onSpeak(text);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _play(String choice) {
    if (isAnimating) return;

    setState(() {
      playerChoice = choice;
      isAnimating = true;
    });

    // VRM chooses and announces (single speech to avoid interruption)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      List<String> options = ['Rock', 'Paper', 'Scissors'];
      vrmChoice = options[Random().nextInt(3)];

      String vrmTemplate =
          vrmChooseComments[Random().nextInt(vrmChooseComments.length)];
      String vrmSay = vrmTemplate.replaceAll('〇〇', vrmChoice);
      _safeSpeak(vrmSay);

      // Calculate result
      if (playerChoice == vrmChoice) {
        result = 'Draw';
      } else if ((playerChoice == 'Rock' && vrmChoice == 'Scissors') ||
          (playerChoice == 'Paper' && vrmChoice == 'Rock') ||
          (playerChoice == 'Scissors' && vrmChoice == 'Paper')) {
        result = 'You Win!';
      } else {
        result = 'Sakura Wins!';
      }

      setState(() {});

      // Speak result after VRM choice speech finishes (~3 seconds)
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (mounted) {
          String resultComment = '';
          if (result == 'Draw') {
            resultComment =
                vrmDrawComments[Random().nextInt(vrmDrawComments.length)];
          } else if (result == 'You Win!') {
            resultComment =
                vrmLoseComments[Random().nextInt(vrmLoseComments.length)];
          } else {
            resultComment =
                vrmWinComments[Random().nextInt(vrmWinComments.length)];
          }
          _safeSpeak(resultComment);
        }
      });

      // Trigger animation
      _animController.forward(from: 0).then((_) {
        if (mounted) {
          _animController.reset();
          setState(() => isAnimating = false);
        }
      });
    });
  }

  void _reset() {
    setState(() {
      playerChoice = '';
      vrmChoice = '';
      result = '';
      isAnimating = false;
    });
    _safeSpeak("リセットしたよ～！ またじゃんけんしよう♡");
  }

  IconData _getIcon(String choice) {
    switch (choice) {
      case 'Rock':
        return Icons.pan_tool;
      case 'Paper':
        return Icons.handshake;
      case 'Scissors':
        return Icons.content_cut;
      default:
        return Icons.question_mark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double buttonSize = screenWidth > 600 ? 120.w : 100.w;

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Choices display with animation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Player
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    return Transform.scale(
                      scale:
                          playerChoice.isNotEmpty ? _scaleAnimation.value : 1.0,
                      child: _buildChoiceCard(
                        label: playerChoice.isEmpty ? "You" : playerChoice,
                        icon: _getIcon(playerChoice),
                        color: playerChoice == 'Rock'
                            ? Colors.orange
                            : playerChoice == 'Paper'
                                ? Colors.blue
                                : Colors.red,
                        borderColor: playerChoice == vrmChoice
                            ? Colors.yellowAccent
                            : playerChoice.isEmpty
                                ? Colors.grey
                                : result.contains('You Win!')
                                    ? Colors.cyanAccent
                                    : Colors.pinkAccent,
                      ),
                    );
                  },
                ),

                Text(
                  "VS",
                  style: TextStyle(fontSize: 32.sp, color: Colors.white70),
                ),

                // VRM
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: vrmChoice.isNotEmpty ? _scaleAnimation.value : 1.0,
                      child: _buildChoiceCard(
                        label: vrmChoice.isEmpty ? "Sakura" : vrmChoice,
                        icon: _getIcon(vrmChoice),
                        color: vrmChoice == 'Rock'
                            ? Colors.orange
                            : vrmChoice == 'Paper'
                                ? Colors.blue
                                : Colors.red,
                        borderColor: vrmChoice == playerChoice
                            ? Colors.yellowAccent
                            : vrmChoice.isEmpty
                                ? Colors.grey
                                : result.contains('Sakura Wins!')
                                    ? Colors.pinkAccent
                                    : Colors.cyanAccent,
                      ),
                    );
                  },
                ),
              ],
            ),

            SizedBox(height: 40.h),
            // Result
            AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return Transform.scale(
                  scale: result.isNotEmpty ? _scaleAnimation.value : 1.0,
                  child: Text(
                    result.isEmpty ? "Choose your move!" : result,
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: result == 'Draw'
                          ? Colors.yellowAccent
                          : result == 'You Win!'
                              ? Colors.cyanAccent
                              : result == 'Sakura Wins!'
                                  ? Colors.pinkAccent
                                  : Colors.white,
                      shadows: [
                        Shadow(blurRadius: 12, color: Colors.black54),
                      ],
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 50.h),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton('Rock', Icons.pan_tool, Colors.orange),
                _buildActionButton('Paper', Icons.handshake, Colors.blue),
                _buildActionButton('Scissors', Icons.content_cut, Colors.red),
              ],
            ),

            SizedBox(height: 40.h),

            // Reset
            ElevatedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh, size: 28),
              label: Text('Play Again', style: TextStyle(fontSize: 18.sp)),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                backgroundColor: Colors.purpleAccent.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40)),
                elevation: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String label,
    required IconData icon,
    required Color color,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor, width: 3),
      ),
      child: Column(
        children: [
          Icon(icon, size: 70.w, color: color),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(fontSize: 18.sp, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: playerChoice.isEmpty && !isAnimating ? () => _play(label) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.5), blurRadius: 15, spreadRadius: 2),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 50.w, color: color),
            SizedBox(height: 12.h),
            Text(
              label,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
