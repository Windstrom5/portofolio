import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class EducationListItem extends StatefulWidget {
  final String schoolName;
  final String location;
  final String years;
  final String degreeType;
  final String imagePath;
  final String mapsUrl;
  final String description; // About the school
  final String learnings; // "What I learned"
  final List<String> skills;

  const EducationListItem({
    Key? key,
    required this.schoolName,
    required this.location,
    required this.years,
    required this.degreeType,
    required this.imagePath,
    required this.mapsUrl,
    required this.description,
    required this.learnings,
    this.skills = const [],
  }) : super(key: key);

  @override
  State<EducationListItem> createState() => _EducationListItemState();
}

class _EducationListItemState extends State<EducationListItem> {
  bool _isExpanded = false;

  Future<void> _launchMapURL() async {
    final Uri uri = Uri.parse(widget.mapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header / Summary Row
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(12.r),
                bottom: Radius.circular(_isExpanded ? 0 : 12.r)),
            child: Padding(
              padding: EdgeInsets.all(20.r),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // School Logo / Image
                  Container(
                    width: 70.r,
                    height: 70.r,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12.r),
                      border:
                          Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                      image: DecorationImage(
                        image: AssetImage(widget.imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 20.w),

                  // Main Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.schoolName,
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          widget.degreeType,
                          style: GoogleFonts.vt323(
                            color: Colors.cyanAccent,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                color: Colors.white38, size: 14.sp),
                            SizedBox(width: 4.w),
                            Text(
                              widget.location,
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 12.sp),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Year Badge & Expand Icon
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                              color: Colors.cyanAccent.withOpacity(0.3)),
                        ),
                        child: Text(
                          widget.years,
                          style: GoogleFonts.vt323(
                            color: Colors.cyanAccent,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Details Section
          if (_isExpanded)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(12.r)),
                border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: Padding(
                padding: EdgeInsets.all(20.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // About School
                    _DetailSection(
                      title: "ABOUT INSTITUTION",
                      content: widget.description,
                      icon: Icons.account_balance,
                    ),
                    SizedBox(height: 20.h),

                    // What I Learned
                    _DetailSection(
                      title: "KEY LEARNINGS & CURRICULUM",
                      content: widget.learnings,
                      icon: Icons.lightbulb,
                    ),

                    SizedBox(height: 20.h),

                    // Skills Chips
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: widget.skills
                          .map((skill) => Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(4.r),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Text(
                                  skill.toUpperCase(),
                                  style: GoogleFonts.vt323(
                                      color: Colors.white70, fontSize: 12.sp),
                                ),
                              ))
                          .toList(),
                    ),

                    SizedBox(height: 20.h),

                    // Actions
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _launchMapURL,
                        icon: Icon(Icons.map,
                            size: 16.sp, color: Colors.cyanAccent),
                        label: Text("VIEW ON MAP",
                            style: GoogleFonts.orbitron(
                                fontSize: 12.sp, color: Colors.cyanAccent)),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 12.h),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _DetailSection(
      {required this.title, required this.content, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16.sp, color: Colors.white70),
            SizedBox(width: 8.w),
            Text(
              title,
              style: GoogleFonts.orbitron(
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Padding(
          padding: EdgeInsets.only(left: 24.w),
          child: Text(
            content,
            style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14.sp,
                height: 1.5),
          ),
        ),
      ],
    );
  }
}
