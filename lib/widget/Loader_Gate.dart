import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';

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

  // Fake boot messages
  final List<String> bootMessages = [
    "[    0.000000] Linux version 6.8.0-windstrom5 (build@portfolio) ...",
    "[    0.042188] Command line: BOOT_IMAGE=/boot/vmlinuz-6.8.0 root=UUID=... ro quiet splash",
    "[    1.248912]   [  OK  ] Started Journal Service.",
    "[    2.187654]   [  OK  ] Started Network Manager.",
    "[    3.891234]   [  OK  ] Reached target Graphical Interface.",
    "[    4.912345] Started Windstrom5 Display Manager.",
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

    // Fake boot sequence
    _bootTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
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
          Future.delayed(const Duration(milliseconds: 800), () {
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
    if (isLoggingIn) return;
    setState(() => isLoggingIn = true);

    // Navigate after brief delay
    Future.delayed(const Duration(milliseconds: 800), () {
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
      child: Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1a1a2e),
                    Color(0xFF16213e),
                    Color(0xFF0f3460),
                  ],
                ),
              ),
            ),

            // Boot sequence
            if (!showLogin)
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...List.generate(
                        currentMessageIndex,
                        (i) => Text(
                          bootMessages[i],
                          style: TextStyle(
                            fontFamily: 'Courier New',
                            fontSize: 12.sp,
                            height: 1.4,
                            color: bootMessages[i].contains('[  OK  ]')
                                ? Colors.green.shade400
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                      if (bootFinished)
                        Padding(
                          padding: EdgeInsets.only(top: 16.h),
                          child: Text(
                            'Starting login manager...',
                            style: TextStyle(
                              fontFamily: 'Courier New',
                              fontSize: 12.sp,
                              color: Colors.cyan.shade300,
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
                      // ASCII Logo - WINDSTROM5
                      _asciiLogo(),

                      SizedBox(height: 48.h),

                      // Login Box
                      Container(
                        width: 350.w.clamp(300.0, 400.0),
                        padding: EdgeInsets.all(32.r),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                              color: Colors.green.shade800.withOpacity(0.4)),
                        ),
                        child: Column(
                          children: [
                            // Generic user icon
                            Container(
                              width: 90.r,
                              height: 90.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade800,
                                border: Border.all(
                                    color: Colors.green.shade600, width: 3),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                size: 50.sp,
                                color: Colors.green.shade400,
                              ),
                            ),

                            SizedBox(height: 20.h),

                            // Username
                            Text(
                              'visitor',
                              style: TextStyle(
                                fontFamily: 'Courier New',
                                fontSize: 24.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 32.h),

                            // Enter button only (no password)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoggingIn ? null : _onLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  elevation: 4,
                                ),
                                child: isLoggingIn
                                    ? SizedBox(
                                        height: 22.h,
                                        width: 22.w,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'ENTER',
                                        style: TextStyle(
                                          fontFamily: 'Courier New',
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // Footer
                      Text(
                        'Windstrom5 Portfolio OS • $currentYear',
                        style: TextStyle(
                          fontFamily: 'Courier New',
                          fontSize: 12.sp,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Press any key to continue',
                        style: TextStyle(
                          fontFamily: 'Courier New',
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                        ),
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

  Widget _asciiLogo() {
    // Simple clean text logo that works well on web
    return Column(
      children: [
        Text(
          'W I N D S T R O M 5',
          style: TextStyle(
            fontFamily: 'Courier New',
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade400,
            letterSpacing: 6,
            shadows: [
              Shadow(
                color: Colors.green.withOpacity(0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green.shade700, width: 1),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Text(
            'PORTFOLIO OS',
            style: TextStyle(
              fontFamily: 'Courier New',
              fontSize: 14.sp,
              color: Colors.grey.shade400,
              letterSpacing: 4,
            ),
          ),
        ),
      ],
    );
  }
}
