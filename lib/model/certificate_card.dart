import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:html' as html;

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
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: SizedBox(
          width: 250,
          height: 250, // Adjust width as needed
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                imagePath,
                width: 250, // Adjust width as needed
                height: 150,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      certificateName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      organizationName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
