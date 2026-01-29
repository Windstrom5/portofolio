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
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import '../llm/llm_service.dart';

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

class _HomePageState extends State<HomePage> {
  List<ChatMessage> chatHistory = [];
  int _selectedIndex = -1;
  String _currentTime = "";
  List<String> additionalTerminalOutput = [];
  final TextEditingController _terminalController = TextEditingController();
  bool _llmLoading = false;
  int _llmProgress = 0;

  @override
  void initState() {
    super.initState();
    // Simple clock ticker
    _updateTime();
    Timer.periodic(const Duration(seconds: 60), (Timer t) => _updateTime());
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

  Future<void> _processCommand(String command) async {
    setState(() {
      additionalTerminalOutput.add("windstrom5@portfolio:~\$ $command");
    });
    command = command.trim().toLowerCase();

    if (command == "help") {
      _showHelp();
    } else if (command == "ls") {
      setState(() {
        additionalTerminalOutput.add(
            "projects certificates education profile resume.pdf tic_tac_toe rock_paper_scissors");
      });
    } else if (command.startsWith("open ")) {
      String target = command.substring(5).trim();
      int? index;
      if (target == "projects") {
        index = 1;
      } else if (target == "certificates") {
        index = 2;
      } else if (target == "education") {
        index = 3;
      } else if (target == "profile") {
        index = 4;
      } else if (target == "tic_tac_toe") {
        index = 5;
      } else if (target == "rock_paper_scissors") {
        index = 6;
      } else if (target == "resume.pdf") {
        final resumePdf = ResumePdf();
        final pdfBytes = await resumePdf.generate();
        resumePdf.downloadPdfWeb(pdfBytes, 'resume_angga.pdf');
        setState(() {
          additionalTerminalOutput.add("Downloading resume.pdf...");
        });
        return;
      }
      if (index != null) {
        setState(() {
          _selectedIndex = index!;
        });
      } else {
        setState(() {
          additionalTerminalOutput.add("Target not found: $target");
        });
      }
    } else if (command == "clear") {
      setState(() {
        additionalTerminalOutput.clear();
      });
    } else if (command == "close" || command == "exit") {
      setState(() {
        _selectedIndex = -1;
      });
    } else {
      setState(() {
        additionalTerminalOutput.add("Command not found: $command");
      });
    }
  }

  void _showHelp() {
    setState(() {
      additionalTerminalOutput.addAll([
        "Available commands:",
        "ls - list sections and files",
        "open <section> - open a section (projects, certificates, education, profile, tic_tac_toe, rock_paper_scissors) or file (resume.pdf)",
        "clear - clear additional output",
        "close or exit - close the terminal window",
        "help - show this help"
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
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 80.r,
                backgroundImage: AssetImage('assets/profile.jpg'),
              ),
            ),
            SizedBox(height: 20.h),
            Text("Angga Nugraha",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold)),
            Text("Full Stack Developer",
                style: TextStyle(color: Colors.grey, fontSize: 18.sp)),
            SizedBox(height: 20.h),
            Text("Location: Yogyakarta",
                style: TextStyle(color: Colors.white, fontSize: 16.sp)),
            Text("Email: angga@example.com",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp)), // Replace with real email
            Text("Phone: +62 123 456 789",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp)), // Replace with real phone
            SizedBox(height: 20.h),
            Text("Skills:",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 10,
              children: [
                _termSkill("Kotlin", Colors.purple),
                _termSkill("Vue.js", Colors.green),
                _termSkill("Laravel", Colors.red),
                _termSkill("Java", Colors.orange),
              ],
            ),
            SizedBox(height: 20.h),
            Text("Games:",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 10,
              children: [
                _termSkill("NihonGo", Colors.blue),
                _termSkill("Go Fit Game Mode", Colors.cyan),
                _termSkill("Tic Tac Toe", Colors.yellow),
                _termSkill("Rock Paper Scissors", Colors.pink),
              ],
            ),
            SizedBox(height: 20.h),
            Text("Bio:",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 10.h),
            Text(
              "Hello, I'm Angga Nugraha. A Full Stack Developer based in Yogyakarta. Enthusiast in Gaming Tech & Innovation.",
              style:
                  TextStyle(color: Colors.white, fontSize: 16.sp, height: 1.5),
            ),
          ],
        );
        break;
      case 5:
        content = LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final vrmWidth = (maxWidth * 0.28).clamp(220.0, 300.0);
            final gameWidth = maxWidth - vrmWidth;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // VRM (left side)
                SizedBox(
                  width: vrmWidth,
                  child: [
                    if (kIsWeb) VrmMaidView(),
                  ].isNotEmpty
                      ? [if (kIsWeb) VrmMaidView()].first
                      : const SizedBox.shrink(),
                ),

                // Game area
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: gameWidth.clamp(300.0, 600.0),
                        maxHeight: constraints.maxHeight * 0.85,
                      ),
                      child: TicTacToe(onSpeak: _postMessageToVrm),
                    ),
                  ),
                ),
              ],
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
      default:
        return "";
    }
  }

  void _postMessageToVrm(String text) {
    if (kIsWeb) {
      try {
        var document = js.context['document'];
        var iframe = js_util.callMethod(
            document, 'querySelector', ['iframe[src="vrm/index.html"]']);
        if (iframe != null) {
          js_util.callMethod(iframe['contentWindow'], 'postMessage', [
            js_util.jsify({'type': 'speak', 'text': text}),
            '*'
          ]);
        }
      } catch (e) {
        // Handle error if needed
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

          // Desktop Shortcuts
          Positioned(
            left: 20.w,
            top: 50.h,
            child: SizedBox(
              width: 300.w,
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                mainAxisSpacing: 20.h,
                crossAxisSpacing: 20.w,
                children: [
                  _desktopShortcut(0, FontAwesomeIcons.terminal, "Terminal"),
                  _desktopShortcut(1, FontAwesomeIcons.folderOpen, "Projects"),
                  _desktopShortcut(2, FontAwesomeIcons.trophy, "Certificates"),
                  _desktopShortcut(
                      3, FontAwesomeIcons.graduationCap, "Education"),
                  _desktopShortcut(4, FontAwesomeIcons.user, "Profile"),
                  _desktopShortcut(5, FontAwesomeIcons.gamepad, "TicTacToe"),
                  _desktopShortcut(6, FontAwesomeIcons.dice, "RPS"),
                  _desktopShortcut(null, FontAwesomeIcons.robot, "Assistant",
                      onTap: openAiChat),
                ],
              ),
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
  _TicTacToeState createState() => _TicTacToeState();
}

class _TicTacToeState extends State<TicTacToe> {
  List<String> board = List.filled(9, '');
  bool playerTurn = true; // Player = X, VRM = O
  String winner = '';

  // Japanese cute reactions when PLAYER places X
  final List<String> playerMoveReactions = [
    "わぁ～！ ご主人様そこ置いたの～？♡",
    "えへへ、Xだね～！ ドキドキする～",
    "ふふっ、次はSakuraの番だよ～！",
    "ご主人様上手～！ でも負けないからねっ♡",
    "きゃっ、そこは危ないよ～！",
  ];

  // When VRM places O
  final List<String> vrmPlaceComments = [
    "ここに〇だよ～♡",
    "えへへ、Sakuraの〇～！",
    "ふふっ、どうかな～？",
    "置いちゃった～！ ご主人様見ててね♡",
  ];

  // Win / Lose / Draw
  final List<String> vrmWinComments = [
    "やったー！ Sakuraの勝ち～！✨",
    "えへへ～ ご主人様に勝っちゃった♡",
    "キャー！ 勝っちゃったよぉ～！",
  ];

  final List<String> vrmLoseComments = [
    "うぅ～… ご主人様強すぎるよぉ…💦",
    "負けちゃった…でも楽しかった～♡",
    "くぅ～！ 次は絶対勝つからねっ！",
  ];

  final List<String> vrmDrawComments = [
    "あいこだよ～！ また遊ぼうね♡",
    "ふふっ、どっちもすごかった～！",
    "引き分け～！ 楽しかったよぉ～♡",
  ];

  // Reset
  final List<String> vrmResetComments = [
    "リセットしたよ～！ また最初からだよ♡",
    "もう一回遊ぼうね～！ 準備OK～！",
    "えへへ、がんばろっ♡",
  ];

  @override
  void initState() {
    super.initState();
    widget.onSpeak("ティックタックトーしようね！ ご主人様が先手でXだよ～♡");
  }

  void _playerTap(int index) {
    if (board[index] == '' && winner == '' && playerTurn) {
      board[index] = 'X';
      setState(() {});

      // VRM reacts to player's move
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && winner == '') {
          String reaction =
              playerMoveReactions[Random().nextInt(playerMoveReactions.length)];
          widget.onSpeak(reaction);
        }
      });

      playerTurn = false;
      _checkWinner();

      if (winner == '') {
        _vrmMove();
      }
    }
  }

  void _vrmMove() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (winner == '' && mounted) {
        List<int> empty = [];
        for (int i = 0; i < 9; i++) {
          if (board[i] == '') empty.add(i);
        }
        if (empty.isNotEmpty) {
          int move = empty[Random().nextInt(empty.length)];
          board[move] = 'O';

          // VRM speaks when placing her move
          String comment =
              vrmPlaceComments[Random().nextInt(vrmPlaceComments.length)];
          widget.onSpeak(comment);

          playerTurn = true;
          _checkWinner();
          setState(() {});
        }
      }
    });
  }

  void _checkWinner() {
    List<List<int>> lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (var line in lines) {
      if (board[line[0]] != '' &&
          board[line[0]] == board[line[1]] &&
          board[line[0]] == board[line[2]]) {
        winner = board[line[0]];
        if (winner == 'X') {
          widget.onSpeak(
              vrmLoseComments[Random().nextInt(vrmLoseComments.length)]);
        } else {
          widget
              .onSpeak(vrmWinComments[Random().nextInt(vrmWinComments.length)]);
        }
        return;
      }
    }

    if (!board.contains('')) {
      winner = 'Draw';
      widget.onSpeak(vrmDrawComments[Random().nextInt(vrmDrawComments.length)]);
    }
  }

  void _reset() {
    setState(() {
      board = List.filled(9, '');
      winner = '';
      playerTurn = true;
    });
    widget.onSpeak(vrmResetComments[Random().nextInt(vrmResetComments.length)]);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate grid side with stricter clamping to prevent tiny sizes
        double side = min(
          constraints.maxWidth * 0.92,
          constraints.maxHeight * 0.65,
        );

        // Hard minimum to avoid zero-size cells/text
        side =
            side.clamp(260.0, 500.0); // increased min from 240 → 260 for safety

        // Dynamic font size with strong minimum
        final double cellFontSize =
            (side / 5.0).clamp(24.0, 140.0); // min 24 prevents tiny text

        return SingleChildScrollView(
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Grid
                  SizedBox(
                    width: side,
                    height: side,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 9,
                      itemBuilder: (ctx, i) {
                        final String cell = board[i];
                        return GestureDetector(
                          onTap: () => _playerTap(i),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
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
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10,
                                      color: cell == 'X'
                                          ? Colors.cyan
                                          : Colors.pink,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    winner == ''
                        ? (playerTurn ? "Your turn (X)" : "Sakura's turn (O)")
                        : winner == 'Draw'
                            ? "It's a Draw!"
                            : winner == 'X'
                                ? "You Win!"
                                : "Sakura Wins!",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh, size: 28),
                    label: const Text(
                      'Play Again',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                      backgroundColor: Colors.purpleAccent.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 8,
                    ),
                  ),
                ],
              ),
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
    "わぁ～！ ご主人様は…だね～♡",
    "えへへ、きた～！ ドキドキするよぉ",
    "ふふっ、ご主人様の選択…Sakuraも負けないよ～！",
    "きゃっ！ だなんて…ずるい～♡",
  ];

  final List<String> vrmChooseComments = [
    "Sakuraは…じゃんけん…〇〇！",
    "えへへ～ 私のはこれだよ～♡",
    "ふふっ、で勝負だよ～！",
    "いくよ～！ だよっ！",
  ];

  final List<String> vrmWinComments = [
    "やった～！ Sakuraの勝ち～！✨",
    "えへへ～ ご主人様に勝っちゃった♡",
    "キャー！ 勝っちゃったよぉ～！ 嬉しい～！",
  ];

  final List<String> vrmLoseComments = [
    "うぅ～… ご主人様に負けちゃった…💦",
    "くぅ～！ でも楽しかったよ～♡ 次は勝つからねっ！",
    "え～ん… ご主人様強すぎるよぉ…でも大好き～！",
  ];

  final List<String> vrmDrawComments = [
    "あいこ～！ またやろっ♡",
    "ふふっ、どっちも同じだね～！ 楽しかった～",
    "引き分けだよ～！ ご主人様と一緒で嬉しい♡",
  ];

  @override
  void initState() {
    super.initState();
    widget.onSpeak("じゃんけんぽんしようね～！ ご主人様、最初に出してね♡");

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

    // VRM reacts to player's choice (insert choice dynamically)
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      String reactionTemplate =
          playerChooseReactions[Random().nextInt(playerChooseReactions.length)];
      String reaction = reactionTemplate.replaceAll('…', ' $choice ');
      widget.onSpeak(reaction);
    });

    // VRM chooses and announces
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      List<String> options = ['Rock', 'Paper', 'Scissors'];
      vrmChoice = options[Random().nextInt(3)];

      String vrmTemplate =
          vrmChooseComments[Random().nextInt(vrmChooseComments.length)];
      String vrmSay = vrmTemplate.replaceAll('〇〇', vrmChoice);
      widget.onSpeak(vrmSay);

      // Calculate result
      if (playerChoice == vrmChoice) {
        result = 'Draw';
        widget
            .onSpeak(vrmDrawComments[Random().nextInt(vrmDrawComments.length)]);
      } else if ((playerChoice == 'Rock' && vrmChoice == 'Scissors') ||
          (playerChoice == 'Paper' && vrmChoice == 'Rock') ||
          (playerChoice == 'Scissors' && vrmChoice == 'Paper')) {
        result = 'You Win!';
        widget
            .onSpeak(vrmLoseComments[Random().nextInt(vrmLoseComments.length)]);
      } else {
        result = 'Sakura Wins!';
        widget.onSpeak(vrmWinComments[Random().nextInt(vrmWinComments.length)]);
      }

      // Trigger animation
      _animController.forward(from: 0).then((_) {
        if (mounted) {
          _animController.reset();
          setState(() => isAnimating = false);
        }
      });

      setState(() {});
    });
  }

  void _reset() {
    setState(() {
      playerChoice = '';
      vrmChoice = '';
      result = '';
      isAnimating = false;
    });
    widget.onSpeak("リセットしたよ～！ またじゃんけんぽんしようね♡");
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
                return Text(
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
                                : _colorAnimation.value,
                    shadows: [
                      Shadow(blurRadius: 12, color: Colors.black54),
                    ],
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
