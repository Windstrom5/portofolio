import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectGrid extends StatelessWidget {
  final String name;
  final String language;
  final Icon platform;
  final String url;
  final String imageUrl;

  const ProjectGrid({
    required this.name,
    required this.language,
    required this.platform,
    required this.url,
    required this.imageUrl,
  });

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double maxCardWidth = screenWidth <= 600 ? screenWidth * 0.8 : 150.w;

    return GestureDetector(
      onTap: () {
        _launchURL(url);
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: SizedBox(
          width: maxCardWidth,
          height: 250.h,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0.r),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        "Language: $language",
                        style: TextStyle(fontSize: 14.sp),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 15.h),
                      SizedBox(
                        width: 30.w,
                        height: 30.w,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: platform,
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
