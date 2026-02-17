import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectGrid extends StatefulWidget {
  final String name;
  final String language;
  final Icon platform;
  final String url;
  final String imageUrl;
  final bool isCompleted;

  const ProjectGrid({
    super.key,
    required this.name,
    required this.language,
    required this.platform,
    required this.url,
    required this.imageUrl,
    this.isCompleted = true,
  });

  @override
  State<ProjectGrid> createState() => _ProjectGridState();
}

class _ProjectGridState extends State<ProjectGrid>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => _launchURL(widget.url),
        child: AnimatedBuilder(
          animation: _glowCtrl,
          builder: (context, child) {
            final glowOpacity =
                _isHovered ? (_glowCtrl.value * 0.3 + 0.2) : 0.0;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: _isHovered
                  ? (Matrix4.identity()..scale(1.03))
                  : Matrix4.identity(),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: _isHovered
                      ? Colors.cyanAccent.withOpacity(0.6)
                      : Colors.white.withOpacity(0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  if (_isHovered)
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(glowOpacity),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -- Image Section --
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      // Project Image
                      Positioned.fill(
                        child: Image.network(
                          widget.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            color: const Color(0xFF1A1A1A),
                            child: Icon(Icons.broken_image,
                                color: Colors.white24, size: 40.r),
                          ),
                        ),
                      ),
                      // Dark gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Platform badge (top-right)
                      Positioned(
                        top: 8.h,
                        right: 8.w,
                        child: Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                                color: Colors.cyanAccent.withOpacity(0.3)),
                          ),
                          child: SizedBox(
                            width: 18.r,
                            height: 18.r,
                            child: FittedBox(child: widget.platform),
                          ),
                        ),
                      ),
                      // Status tag (top-left)
                      Positioned(
                        top: 8.h,
                        left: 8.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: widget.isCompleted
                                ? Colors.greenAccent.withOpacity(0.8)
                                : Colors.orangeAccent.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4.r),
                            boxShadow: [
                              BoxShadow(
                                color: (widget.isCompleted
                                        ? Colors.greenAccent
                                        : Colors.orangeAccent)
                                    .withOpacity(0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                          child: Text(
                            widget.isCompleted ? "DONE" : "WIP",
                            style: GoogleFonts.vt323(
                              color: Colors.black,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      // Language tag (bottom-left)
                      Positioned(
                        bottom: 8.h,
                        left: 8.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4.r),
                            border: Border.all(
                                color: Colors.cyanAccent.withOpacity(0.4)),
                          ),
                          child: Text(
                            widget.language.toUpperCase(),
                            style: GoogleFonts.vt323(
                              color: Colors.cyanAccent,
                              fontSize: 11.sp,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // -- Info Section --
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D0D),
                    border: Border(
                      top: BorderSide(
                          color: Colors.cyanAccent.withOpacity(0.15)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.name.toUpperCase(),
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      // VIEW PROJECT button
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isHovered
                                ? [
                                    Colors.cyanAccent.withOpacity(0.3),
                                    Colors.purpleAccent.withOpacity(0.3),
                                  ]
                                : [
                                    Colors.white.withOpacity(0.05),
                                    Colors.white.withOpacity(0.08),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(4.r),
                          border: Border.all(
                            color: _isHovered
                                ? Colors.cyanAccent.withOpacity(0.5)
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.open_in_new,
                              color: _isHovered
                                  ? Colors.cyanAccent
                                  : Colors.white54,
                              size: 12.sp,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              "VIEW PROJECT",
                              style: GoogleFonts.vt323(
                                color: _isHovered
                                    ? Colors.cyanAccent
                                    : Colors.white54,
                                fontSize: 13.sp,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
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
