import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';

class IntroLoader extends StatefulWidget {
  const IntroLoader({super.key});

  @override
  _IntroLoaderState createState() => _IntroLoaderState();
}

class _IntroLoaderState extends State<IntroLoader> {
  List<String> bootMessages = [
    "[    0.000000] Booting Windstrom5 Portfolio System",
    "[    0.123456] Mounting root filesystem...",
    "[    0.234567] Loading kernel modules...",
    "[    0.345678] Initializing network interfaces...",
    "[    0.456789] Starting user services...",
    "[    0.567890] Checking disk integrity...",
    "[    0.678901] Loading Flutter environment...",
    "[    0.789012] Preparing Dracula theme...",
    "[    0.890123] Initializing terminal emulator...",
    "[    0.901234] Booting complete. Welcome!"
  ];

  int currentMessageIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startBootSimulation();
  }

  void _startBootSimulation() {
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (currentMessageIndex < bootMessages.length) {
        setState(() {
          currentMessageIndex++;
        });
      } else {
        timer.cancel();
        // Notify parent to switch to home after boot simulation
        Future.delayed(const Duration(seconds: 1), () {
          if (context.mounted) {
            // We will handle the ready state in LoaderGate
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Windstrom5 Portfolio OS",
              style: TextStyle(
                fontSize: 24.sp,
                fontFamily: 'Courier',
                color: Colors.green,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 20.h),
            ...List.generate(currentMessageIndex, (index) {
              return Text(
                bootMessages[index],
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white70,
                  fontFamily: 'Courier',
                ),
              );
            }),
            if (currentMessageIndex < bootMessages.length)
              Text(
                "[ OK ]",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.green,
                  fontFamily: 'Courier',
                ),
              ),
          ],
        ),
      ),
    );
  }
}