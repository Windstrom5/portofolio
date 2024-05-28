import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class EducationCard extends StatelessWidget {
  final String name;
  final String location;
  final String years;
  final String imagePath;
  final String mapsUrl;

  const EducationCard({
    required this.name,
    required this.location,
    required this.years,
    required this.imagePath,
    required this.mapsUrl,
  });

  Future<void> _launchMapURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _launchMapURL(mapsUrl); // Launch map URL when tapped
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 150.w, // Set maximum width for the card
          maxHeight: 250.h, // Set maximum height for the card
        ),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  child: Image.asset(
                    imagePath,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 5.h), // Reduced space between texts
                      Text(
                        "Location : $location",
                        style: TextStyle(
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10.h), // Added extra space at the bottom
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
