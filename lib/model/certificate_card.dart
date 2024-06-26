import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CertificateCard extends StatelessWidget {
  final String certificateName;
  final String organizationName;
  final String imagePath;

  const CertificateCard({
    required this.certificateName,
    required this.organizationName,
    required this.imagePath,
  });

  Future<void> _downloadCertificate(String assetPath) async {
    final html.AnchorElement anchorElement = html.AnchorElement(href: assetPath)
      ..setAttribute("download", "certificate.jpg")
      ..click();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _downloadCertificate(imagePath); // Call download function
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 150.w, // Set maximum width for the card
          maxHeight: 200.h, // Set maximum height for the card
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
                        certificateName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 5.h), // Reduced space between texts
                      Text(
                        organizationName,
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