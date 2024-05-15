import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: SizedBox(
          width: 150,
          height: 150, // Adjust width as needed
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
            crossAxisAlignment: CrossAxisAlignment.center, // Center the content horizontally
            children: [
              Image.network(
                imageUrl,
                width: 250, // Match the card width
                height: 150, // Fixed height
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // Center the text horizontally
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center, // Align text to center
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Language: ${language}",
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center, // Align text to center
                    ),
                    const SizedBox(height: 15),
                    platform,
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
