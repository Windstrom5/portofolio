import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:google_fonts/google_fonts.dart';
import 'hud_components.dart';
import '../utils/web_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SpotifyPlayer extends StatefulWidget {
  final String playlistId;
  final VoidCallback onClose;

  const SpotifyPlayer({
    super.key,
    required this.playlistId,
    required this.onClose,
  });

  @override
  State<SpotifyPlayer> createState() => _SpotifyPlayerState();
}

class _SpotifyPlayerState extends State<SpotifyPlayer> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'spotify-player-${widget.playlistId}';

    // Register the iframe factory
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId, {Object? params}) => WebUtils.createIFrameElement(
        src:
            'https://open.spotify.com/embed/playlist/${widget.playlistId}?utm_source=generator&theme=0',
        border: 'none',
        width: '100%',
        height: '100%',
        allow:
            'autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HUDContainer(
      width: 400.w,
      height: 500.h,
      padding: EdgeInsets.zero,
      accentColor: Colors.greenAccent,
      child: Column(
        children: [
          // HUD Title Bar
          Container(
            height: 45.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              border: Border(
                  bottom:
                      BorderSide(color: Colors.greenAccent.withOpacity(0.3))),
              gradient: LinearGradient(
                colors: [
                  Colors.greenAccent.withOpacity(0.1),
                  Colors.transparent
                ],
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.music_note, color: Colors.greenAccent, size: 18.sp),
                SizedBox(width: 12.w),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SPOTIFY PLAYER",
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      "オーディオ・ストリーム - V4.2",
                      style: GoogleFonts.notoSansJp(
                        color: Colors.greenAccent,
                        fontSize: 8.sp,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white54, size: 18.sp),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Player Content
          Expanded(
            child: Container(
              margin: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent.withOpacity(0.1)),
              ),
              child: kIsWeb
                  ? HtmlElementView(viewType: _viewId)
                  : const Center(
                      child: Text(
                        "Spotify Player only available on Web.",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
