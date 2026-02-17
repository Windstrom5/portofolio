import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:html' as html;

class AchievementListItem extends StatelessWidget {
  final String certificateName;
  final String organizationName;
  final String description;
  final String imagePath;
  final String date;
  final List<String> skills;

  const AchievementListItem({
    Key? key,
    required this.certificateName,
    required this.organizationName,
    required this.imagePath,
    this.description =
        "Professional certification validating specialized skills and knowledge.",
    this.date = "2024-01-01",
    this.skills = const ["Skill 1", "Skill 2"],
  }) : super(key: key);

  Future<void> _downloadCertificate() async {
    html.AnchorElement(href: imagePath)
      ..setAttribute("download", "certificate.jpg")
      ..click();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      child: Stack(
        children: [
          // Background with sharp cut
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                  color: Colors.purpleAccent.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.1),
                  offset: const Offset(4, 4),
                )
              ],
            ),
            child: Row(
              children: [
                // Info (Left)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withOpacity(0.2),
                          border: const Border(
                              left: BorderSide(
                                  color: Colors.purpleAccent, width: 4)),
                        ),
                        child: Text(
                          certificateName.toUpperCase(),
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Icon(Icons.bolt,
                              color: Colors.yellowAccent, size: 14.sp),
                          SizedBox(width: 6.w),
                          Text(
                            organizationName,
                            style: GoogleFonts.vt323(
                              color: Colors.white70,
                              fontSize: 16.sp,
                            ),
                          ),
                          Text(
                            " // $date",
                            style: GoogleFonts.vt323(
                              color: Colors.purpleAccent.withOpacity(0.7),
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 4.h,
                        children: skills
                            .take(5)
                            .map((skill) => Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    border: Border.all(color: Colors.white12),
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                  child: Text(
                                    skill.toUpperCase(),
                                    style: GoogleFonts.vt323(
                                        color: Colors.cyanAccent,
                                        fontSize: 11.sp),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20.w),
                // Image (Right)
                Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.white24),
                    image: DecorationImage(
                      image: AssetImage(imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sporty accent - Speed lines placeholder
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 40,
              height: 4,
              color: Colors.yellowAccent,
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: 4,
              height: 40,
              color: Colors.cyanAccent,
            ),
          ),
        ],
      ),
    );
  }
}
