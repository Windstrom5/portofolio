import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import '../service/discord_service.dart';

class DiscordActivityWidget extends StatefulWidget {
  final bool isMinimized;
  final VoidCallback onToggleMinimize;
  final VoidCallback? onTap;

  const DiscordActivityWidget({
    super.key,
    required this.isMinimized,
    required this.onToggleMinimize,
    this.onTap,
  });

  @override
  State<DiscordActivityWidget> createState() => _DiscordActivityWidgetState();
}

class _DiscordActivityWidgetState extends State<DiscordActivityWidget> {
  final DiscordService _discordService = DiscordService();
  DiscordActivity? _activity;
  Timer? _playtimeTimer;
  String _playtimeStr = "";

  @override
  void initState() {
    super.initState();
    _discordService.start();
    _discordService.activityStream.listen((activity) {
      if (mounted) {
        setState(() {
          _activity = activity;
          _updatePlaytime();
        });
      }
    });

    _playtimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _activity != null && _activity!.isPlaying) {
        setState(() => _updatePlaytime());
      }
    });
  }

  void _updatePlaytime() {
    if (_activity == null || _activity!.startTimestamp == null) {
      _playtimeStr = "";
      return;
    }

    final start =
        DateTime.fromMillisecondsSinceEpoch(_activity!.startTimestamp!);
    final now = DateTime.now();
    final diff = now.difference(start);

    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);

    if (hours > 0) {
      _playtimeStr = "${hours}h ${minutes}m ${seconds}s";
    } else {
      _playtimeStr = "${minutes}m ${seconds}s";
    }
  }

  @override
  void dispose() {
    _discordService.dispose();
    _playtimeTimer?.cancel();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'online':
        return Colors.greenAccent;
      case 'idle':
        return Colors.orangeAccent;
      case 'dnd':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMinimized) {
      return _buildMinimizedState();
    }

    if (_activity == null) {
      return FadeInRight(
        duration: const Duration(milliseconds: 800),
        child: _buildContainer(
          child: Row(
            children: [
              SizedBox(
                width: 14.r,
                height: 14.r,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.indigoAccent),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                "CONNECTING_TO_LINK...",
                style: GoogleFonts.vt323(
                  color: Colors.white38,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final statusColor = _getStatusColor(_activity!.discordStatus);

    return GestureDetector(
      onTap: widget.onTap,
      child: FadeInRight(
        duration: const Duration(milliseconds: 800),
        child: _buildContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Discord Icon and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: Colors.indigoAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          FontAwesomeIcons.discord,
                          color: Colors.indigoAccent,
                          size: 18.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        _activity!.discordStatus == 'offline'
                            ? "SYSTEM_LINK: OFFLINE"
                            : "SYSTEM_LINK: ACTIVE",
                        style: GoogleFonts.orbitron(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  // Controls
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onToggleMinimize,
                        icon: Icon(Icons.remove,
                            color: Colors.white60, size: 18.sp),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: "MINIMIZE",
                      ),
                      SizedBox(width: 8.w),
                      // Pulsing Status Dot
                      Pulse(
                        infinite: _activity!.discordStatus != 'offline',
                        duration: const Duration(seconds: 2),
                        child: Container(
                          width: 10.r,
                          height: 10.r,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (_activity!.discordStatus != 'offline')
                                BoxShadow(
                                  color: statusColor.withOpacity(0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Divider(color: Colors.white.withOpacity(0.1), height: 1),
              SizedBox(height: 14.h),

              // Playing Content
              if (_activity!.isPlaying) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Game Art with Neon Border
                    Container(
                      width: 64.r,
                      height: 64.r,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.cyanAccent.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: _activity!.largeImage != null
                            ? Image.network(
                                _activity!.largeImage!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.white10,
                                child: Icon(Icons.videogame_asset,
                                    color: Colors.white38, size: 24.sp),
                              ),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CURRENTLY_PLAYING",
                            style: GoogleFonts.vt323(
                              color: Colors.cyanAccent,
                              fontSize: 12.sp,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            _activity!.gameName!.toUpperCase(),
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_activity!.details != null)
                            Text(
                              _activity!.details!,
                              style: GoogleFonts.vt323(
                                color: Colors.white70,
                                fontSize: 13.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (_playtimeStr.isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(top: 4.h),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                "EXP_TIME: $_playtimeStr",
                                style: GoogleFonts.vt323(
                                  color: Colors.cyanAccent,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Idle State
                Row(
                  children: [
                    Icon(Icons.hourglass_empty,
                        color: Colors.white38, size: 20.sp),
                    SizedBox(width: 10.w),
                    Text(
                      "STANDBY_MODE",
                      style: GoogleFonts.vt323(
                        color: Colors.white38,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimizedState() {
    if (_activity == null) return const SizedBox.shrink();
    final statusColor = _getStatusColor(_activity!.discordStatus);

    return GestureDetector(
      onTap: widget.onToggleMinimize,
      child: FadeInRight(
        duration: const Duration(milliseconds: 500),
        child: _buildContainer(
          width: 60.w,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 60.r,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  FontAwesomeIcons.discord,
                  color: Colors.indigoAccent,
                  size: 24.sp,
                ),
                Positioned(
                  right: 12.r,
                  bottom: 12.r,
                  child: Pulse(
                    infinite: _activity!.discordStatus != 'offline',
                    duration: const Duration(seconds: 2),
                    child: Container(
                      width: 10.r,
                      height: 10.r,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
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

  Widget _buildContainer(
      {required Widget child, double? width, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: width ?? 280.w,
          padding: padding ?? EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.indigoAccent.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
