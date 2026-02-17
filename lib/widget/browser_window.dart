import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:google_fonts/google_fonts.dart';
import 'package:project_test/widget/hud_components.dart';

class BrowserWindow extends StatefulWidget {
  final String initialUrl;
  final String title;
  final VoidCallback onClose;

  const BrowserWindow({
    super.key,
    required this.initialUrl,
    required this.title,
    required this.onClose,
  });

  @override
  State<BrowserWindow> createState() => _BrowserWindowState();
}

class _BrowserWindowState extends State<BrowserWindow> {
  late String _viewId;
  late String _currentUrl;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _viewId = 'browser-view-${DateTime.now().millisecondsSinceEpoch}';

    // Register the iframe factory
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => html.IFrameElement()
        ..src = _currentUrl
        ..style.border = 'none'
        ..width = '100%'
        ..height = '100%'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow =
            "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share",
    );
  }

  @override
  Widget build(BuildContext context) {
    return HUDContainer(
      width: 1100.w,
      height: 750.h,
      padding: EdgeInsets.zero,
      accentColor: Colors.cyanAccent,
      child: Column(
        children: [
          // HUD Title Bar
          Container(
            height: 45.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              border: Border(
                  bottom:
                      BorderSide(color: Colors.cyanAccent.withOpacity(0.3))),
              gradient: LinearGradient(
                colors: [
                  Colors.cyanAccent.withOpacity(0.1),
                  Colors.transparent
                ],
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.language, color: Colors.cyanAccent, size: 18.sp),
                SizedBox(width: 12.w),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title.toUpperCase(),
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      "ウェブ・ブラウザ - ONLINE",
                      style: GoogleFonts.notoSansJp(
                        color: Colors.cyanAccent,
                        fontSize: 9.sp,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    _browserBtn(Icons.arrow_back, () {}),
                    _browserBtn(Icons.arrow_forward, () {}),
                    _browserBtn(Icons.refresh, () {}),
                    SizedBox(width: 10.w),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: Colors.redAccent, size: 20.sp),
                      onPressed: widget.onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // HUD Address Bar
          Container(
            height: 40.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              border: Border(
                  bottom:
                      BorderSide(color: Colors.cyanAccent.withOpacity(0.1))),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, size: 12.sp, color: const Color(0xFF50FA7B)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _currentUrl,
                      style: GoogleFonts.vt323(
                          color: Colors.cyanAccent.withOpacity(0.7),
                          fontSize: 13.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Web View
          Expanded(
            child: Container(
              margin: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.1)),
              ),
              child: kIsWeb
                  ? HtmlElementView(viewType: _viewId)
                  : const Center(
                      child: Text(
                        "Browser only available on Web platform.",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _browserBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: Colors.white70, size: 18.sp),
      onPressed: onTap,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      constraints: const BoxConstraints(),
    );
  }
}
