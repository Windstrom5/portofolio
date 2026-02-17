import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import 'package:flutter/services.dart';

class LoaderGate extends StatefulWidget {
  const LoaderGate({super.key});

  @override
  State<LoaderGate> createState() => _LoaderGateState();
}

class _LoaderGateState extends State<LoaderGate> {
  bool showLogin = false;
  bool cursorVisible = true;
  bool isLoggingIn = false;
  Timer? _cursorTimer;
  Timer? _bootTimer;
  final int currentYear = DateTime.now().year;

  // MUFC Official Colors
  static const Color muRed = Color(0xFFDA291C);
  static const Color muGold = Color(0xFFFBE122);
  static const Color muBlack = Color(0xFF000000);

  // Fake boot messages - Hybrid Windstrom5/Sporty Edition
  final List<String> bootMessages = [
    "[    0.000000] WINDSTROM5 OS v3.5-LATEST-STABLE",
    "[    0.042188] [CORE] Initializing Terminal of Dreams kernel...",
    "[    1.248912] [NET ] Portfolio Network: [ONLINE]",
    "[    2.187654] [SYS ] Tactical Engine: [OPTIMIZED]",
    "[    3.891234] [SEC ] WINDSTROM5 Protocol: [ACTIVE]",
    "[    4.912345] [INF ] Root access granted. Welcome to the Terminal.",
  ];

  int currentMessageIndex = 0;
  bool bootFinished = false;

  @override
  void initState() {
    super.initState();

    // Blinking cursor
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => cursorVisible = !cursorVisible);
    });

    // Fake boot sequence - slightly faster for "Hacker" feel
    _bootTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (currentMessageIndex < bootMessages.length) {
          currentMessageIndex++;
        } else {
          bootFinished = true;
          timer.cancel();

          // Show login screen after boot
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              setState(() => showLogin = true);
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _bootTimer?.cancel();
    super.dispose();
  }

  void _onLogin() {
    if (isLoggingIn || !showLogin) return;
    setState(() => isLoggingIn = true);

    // Navigate after brief delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) {
        if (showLogin && event is RawKeyDownEvent) {
          _onLogin();
        }
      },
      child: GestureDetector(
        onTap: _onLogin, // CLICK ANYWHERE TO ENTER
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          backgroundColor: muBlack,
          body: Stack(
            children: [
              // Background gradient - MUFC themed but with dark hacker aesthetic
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      muBlack,
                      Color(0xFF0F0000), // Very dark red
                      Color(0xFF1A1A1A), // Dark grey
                    ],
                  ),
                ),
              ),

              // Subtle Tech Grid Overlay (CSS/Gradient based instead of Image)
              Opacity(
                opacity: 0.05,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.cyanAccent],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
              ),

              // Boot sequence - Hacker Green/Retro Cyan
              if (!showLogin)
                SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(30.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...List.generate(
                          currentMessageIndex,
                          (i) {
                            Color textColor = Colors.white70;
                            if (bootMessages[i].contains('[OK]') ||
                                bootMessages[i].contains('[ONLINE]') ||
                                bootMessages[i].contains('ACTIVE')) {
                              textColor =
                                  const Color(0xFF50FA7B); // Hacker Green
                            } else if (bootMessages[i].contains('[CORE]') ||
                                bootMessages[i].contains('[SYS]') ||
                                bootMessages[i].contains('[NET]')) {
                              textColor = const Color(0xFF8BE9FD); // Retro Cyan
                            }

                            return Text(
                              bootMessages[i],
                              style: GoogleFonts.vt323(
                                fontSize: 18.sp,
                                height: 1.4,
                                color: textColor,
                              ),
                            );
                          },
                        ),
                        if (bootFinished)
                          Padding(
                            padding: EdgeInsets.only(top: 16.h),
                            child: Text(
                              'WINDSTROM5_OS: AUTH_SERVICE_STANDBY...',
                              style: GoogleFonts.vt323(
                                fontSize: 20.sp,
                                color: muGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // Full Login Screen
              if (showLogin)
                Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Red Devils Logo
                        _brandLogo(),

                        SizedBox(height: 50.h),

                        // Login Box
                        Container(
                          width: 380.w.clamp(320.0, 420.0),
                          padding: EdgeInsets.all(40.r),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(24.r),
                            border: Border.all(
                                color: muRed.withOpacity(0.5), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: muRed.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              // User icon with MUFC Red glow
                              Container(
                                width: 100.r,
                                height: 100.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: muBlack,
                                  border: Border.all(color: muRed, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                        color: muRed.withOpacity(0.5),
                                        blurRadius: 15)
                                  ],
                                ),
                                child: Icon(
                                  Icons.bolt_rounded,
                                  size: 60.sp,
                                  color: muGold,
                                ),
                              ),

                              SizedBox(height: 25.h),

                              // Username
                              Text(
                                'VISITOR',
                                style: GoogleFonts.orbitron(
                                  fontSize: 22.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),

                              SizedBox(height: 35.h),

                              // Welcome Text
                              Text(
                                'CLICK ANYWHERE TO LOG IN',
                                style: GoogleFonts.vt323(
                                  color: muGold.withOpacity(0.8),
                                  fontSize: 18.sp,
                                  letterSpacing: 1,
                                ),
                              ),

                              if (isLoggingIn)
                                Padding(
                                  padding: EdgeInsets.only(top: 20.h),
                                  child: const CircularProgressIndicator(
                                    color: muRed,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        SizedBox(height: 40.h),

                        // Footer
                        Text(
                          'WINDSTROM5 OS • PORTFOLIO ENGINE',
                          style: GoogleFonts.vt323(
                            fontSize: 16.sp,
                            color: Colors.grey.shade500,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Windstrom5 Hybrid Edition v1.0',
                          style: GoogleFonts.notoSansJp(
                            fontSize: 10.sp,
                            color: muRed.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brandLogo() {
    return Column(
      children: [
        Text(
          'WINDSTROM5 OS',
          style: GoogleFonts.orbitron(
            fontSize: 42.sp,
            fontWeight: FontWeight.w900,
            color: muRed,
            letterSpacing: 8,
            shadows: [
              Shadow(
                color: Colors.black,
                offset: const Offset(4, 4),
                blurRadius: 2,
              ),
              Shadow(
                color: muRed.withOpacity(0.8),
                blurRadius: 20,
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [muRed, muGold]),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Text(
            'THE TERMINAL OF DREAMS',
            style: GoogleFonts.vt323(
              fontSize: 18.sp,
              color: muBlack,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ),
      ],
    );
  }
}
