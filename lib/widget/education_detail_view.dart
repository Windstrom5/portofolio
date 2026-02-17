import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class EducationStoreDetailView extends StatelessWidget {
  final String schoolName;
  final String location;
  final String years;
  final String degreeType;
  final String imagePath;
  final String mapsUrl;
  final String description;
  final List<String> skills;
  final List<String> screenshots;

  const EducationStoreDetailView({
    Key? key,
    required this.schoolName,
    required this.location,
    required this.years,
    required this.degreeType,
    required this.imagePath,
    required this.mapsUrl,
    required this.description,
    required this.skills,
    this.screenshots = const [],
  }) : super(key: key);

  Future<void> _launchMapURL() async {
    final Uri uri = Uri.parse(mapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "ACADEMIC DOSSIER",
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 16.sp,
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'edu_icon_$schoolName',
                  child: Container(
                    width: 100.r,
                    height: 100.r,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      image: DecorationImage(
                        image: AssetImage(imagePath),
                        fit: BoxFit.cover,
                      ),
                      border:
                          Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 24.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schoolName,
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        location.toUpperCase(),
                        style: GoogleFonts.vt323(
                          color: Colors.cyanAccent,
                          fontSize: 18.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          _StatBadge(
                              icon: Icons.calendar_today,
                              text: years,
                              color: Colors.white70),
                          SizedBox(width: 16.w),
                          _StatBadge(
                              icon: Icons.school,
                              text: "GPA: 4.0",
                              color: Colors.white70),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 32.h),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _launchMapURL,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
                child: Text(
                  "VISIT CAMPUS LOCATION",
                  style: GoogleFonts.orbitron(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

            SizedBox(height: 32.h),

            // Preview Screenshots (Placeholder Support)
            Text(
              "CAMPUS PREVIEW",
              style: GoogleFonts.orbitron(
                color: Colors.white70,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 200.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: screenshots.isEmpty ? 3 : screenshots.length,
                separatorBuilder: (context, index) => SizedBox(width: 16.w),
                itemBuilder: (context, index) {
                  // Use provided screenshot or placeholder
                  if (screenshots.isNotEmpty) {
                    return _buildScreenshotContainer(
                        AssetImage(screenshots[index]));
                  } else {
                    return _buildPlaceholderContainer();
                  }
                },
              ),
            ),

            SizedBox(height: 32.h),

            // Description
            Text(
              "ACADEMIC SUMMARY",
              style: GoogleFonts.orbitron(
                color: Colors.white70,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14.sp,
                height: 1.5,
              ),
            ),

            SizedBox(height: 24.h),

            // Skills / Competencies
            Text(
              "SKILLS ACQUIRED",
              style: GoogleFonts.orbitron(
                color: Colors.white70,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: skills
                  .map((skill) => Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                              color: Colors.cyanAccent.withOpacity(0.3)),
                        ),
                        child: Text(
                          skill.toUpperCase(),
                          style: GoogleFonts.vt323(
                              color: Colors.cyanAccent, fontSize: 14.sp),
                        ),
                      ))
                  .toList(),
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenshotContainer(ImageProvider image) {
    return Container(
      width: 300.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        image: DecorationImage(image: image, fit: BoxFit.cover),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
    );
  }

  Widget _buildPlaceholderContainer() {
    return Container(
      width: 300.w,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, color: Colors.white24, size: 40.sp),
            SizedBox(height: 8.h),
            Text(
              "PREVIEW SCREENSHOT",
              style: GoogleFonts.vt323(color: Colors.white24, fontSize: 16.sp),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatBadge({
    Key? key,
    required this.icon,
    required this.text,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16.sp),
        SizedBox(width: 4.w),
        Text(text,
            style: GoogleFonts.vt323(
                color: Colors.white.withOpacity(0.9), fontSize: 16.sp)),
      ],
    );
  }
}
