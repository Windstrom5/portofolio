import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CertificateCard extends StatelessWidget {
  final String certificateName;
  final String organizationName;
  final String imagePath;

  const CertificateCard({
    required this.certificateName,
    required this.organizationName,
    required this.imagePath,
  });
  
  Future<void> _downloadCertificate(String url) async {
      final response = await http.get(Uri.parse(url));
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final file = File('${documentsDirectory.path}/certificate.jpg');
      await file.writeAsBytes(response.bodyBytes);
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      organizationName,
                      style: TextStyle(
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
