import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IntroLoader extends StatelessWidget {
  final int progress;

  const IntroLoader({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "WINDSTROM5",
              style: TextStyle(
                fontSize: 48.sp,
                fontFamily: 'Retro',
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "PORTFOLIO SYSTEM",
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white70,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 40.h),
            SizedBox(
              width: 300.w,
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 6,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(Colors.blue),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              "$progress%",
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
