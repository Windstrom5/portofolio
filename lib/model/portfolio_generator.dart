import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../utils/web_utils.dart';
import 'project_model.dart';

class PortfolioPdf {
  Future<Uint8List> generate({
    required List<ProjectModel> projects,
  }) async {
    final pw.Document pdf = pw.Document();

    // --- Font Loading ---
    pw.Font? ttfRegular;
    pw.Font? ttfBold;
    pw.Font? ttfItalic;

    try {
      final fontRegular = await rootBundle.load("fonts/NotoSans-Regular.ttf");
      ttfRegular = pw.Font.ttf(fontRegular);
    } catch (e) {
      print("Error loading regular font: $e");
    }

    try {
      final fontBold = await rootBundle.load("fonts/NotoSans-Bold.ttf");
      ttfBold = pw.Font.ttf(fontBold);
    } catch (e) {
      print("Error loading bold font: $e");
    }

    try {
      final fontItalic = await rootBundle.load("fonts/NotoSans-Italic.ttf");
      ttfItalic = pw.Font.ttf(fontItalic);
    } catch (e) {
      print("Error loading italic font: $e");
    }

    final theme = pw.ThemeData.withFont(
      base: ttfRegular,
      bold: ttfBold,
      italic: ttfItalic,
    );

    // --- Color Palette (Professional Warm Tones) ---
    final primaryColor = PdfColor.fromInt(0xFF111827); // Gray 900
    final secondaryColor = PdfColor.fromInt(0xFF4B5563); // Gray 600
    final accentColor = PdfColor.fromInt(0xFF1E3A5F); // Deep Slate Blue
    final accentWarm = PdfColor.fromInt(0xFFB45309); // Amber 700
    final borderColor = PdfColor.fromInt(0xFFD1D5DB); // Gray 300
    final pageBg = PdfColor.fromInt(0xFFFAFAFA); // Warm white

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      theme: theme,
      buildBackground: (context) {
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Stack(
            children: [
              pw.Container(color: pageBg),
              // Subtle accent bar at very top of first page only
              if (context.pageNumber == 1)
                pw.Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: pw.Container(
                    height: 3,
                    decoration: pw.BoxDecoration(
                      gradient: pw.LinearGradient(
                        colors: [accentColor, accentWarm],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );

    final list = projects.isEmpty ? allProjects : projects;

    // Aggregate unique tech skills across all projects
    final Set<String> allTechSkills = {};
    for (final proj in list) {
      allTechSkills.addAll(proj.techStack);
    }

    // Count projects by status
    final int productionCount =
        list.where((p) => p.status == ProjectStatus.production).length;
    final int devCount =
        list.where((p) => p.status == ProjectStatus.development).length;
    final int legacyCount =
        list.where((p) => p.status == ProjectStatus.legacy).length;

    // Aggregate unique platforms
    final Set<String> allPlatforms = {};
    for (final proj in list) {
      allPlatforms.add(proj.platform);
    }

    // Aggregate unique languages
    final Set<String> allLanguages = {};
    for (final proj in list) {
      allLanguages.add(proj.primaryLanguage);
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 6),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: borderColor, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'ANGGA NUGRAHA  //  PROJECT PORTFOLIO',
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: secondaryColor,
                    letterSpacing: 0.8,
                  ),
                ),
                pw.Text(
                  'PAGE ${context.pageNumber} OF ${context.pagesCount}',
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: borderColor, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'windstrom5profile.netlify.app',
                  style: pw.TextStyle(
                    fontSize: 7,
                    color: accentWarm,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 7, color: secondaryColor),
                ),
              ],
            ),
          );
        },
        build: (context) {
          return [
            // ========================================
            // 1. PROFESSIONAL HEADER
            // ========================================
            pw.SizedBox(height: 8),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ANGGA NUGRAHA PUTRA',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Project Portfolio — Full Stack & Android Development',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: accentWarm,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Yogyakarta, Indonesia  |  anggagant@gmail.com  |  github.com/Windstrom5  |  linkedin.com/in/angga-nugraha',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 15),
                // Single profile QR code
                pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(3),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                            color: borderColor, width: 0.5),
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: 'https://windstrom5profile.netlify.app/',
                        width: 48,
                        height: 48,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'ONLINE PROFILE',
                      style: pw.TextStyle(
                        fontSize: 5.5,
                        fontWeight: pw.FontWeight.bold,
                        color: secondaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // ========================================
            // 2. PORTFOLIO OVERVIEW
            // ========================================
            _sectionHeader('PORTFOLIO OVERVIEW', primaryColor),
            pw.Text(
              'This document presents ${list.length} software development projects '
              'spanning ${allPlatforms.join(", ")} platforms, '
              'built with ${allLanguages.join(", ")}. '
              'Of these, $productionCount are in production'
              '${devCount > 0 ? ", $devCount in active development" : ""}'
              '${legacyCount > 0 ? ", and $legacyCount are legacy projects" : ""}. '
              'Each entry includes a full description, technology stack, platform, and repository link where available.',
              style: pw.TextStyle(
                fontSize: 9,
                color: secondaryColor,
                lineSpacing: 1.4,
              ),
            ),
            pw.SizedBox(height: 8),
            _techRow(
              'Technical Proficiency:',
              allTechSkills.toList()..sort(),
              primaryColor,
              secondaryColor,
            ),
            pw.SizedBox(height: 6),

            // ========================================
            // 3. PROJECTS
            // ========================================
            _sectionHeader('PROJECTS & DEVELOPMENTS', primaryColor),
            ...list.map((proj) => _buildProjectEntry(
                  proj,
                  primaryColor,
                  secondaryColor,
                  accentWarm,
                )),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // --- Section Header (ATS Pattern) ---
  pw.Widget _sectionHeader(String title, PdfColor textPrimary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 10),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Divider(thickness: 1, color: textPrimary),
        pw.SizedBox(height: 6),
      ],
    );
  }

  // --- Technical Proficiency Row ---
  pw.Widget _techRow(
    String label,
    List<String> skills,
    PdfColor textPrimary,
    PdfColor textSecondary,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$label ',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: textPrimary,
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            skills.join(', '),
            style: pw.TextStyle(fontSize: 9, color: textSecondary),
          ),
        ),
      ],
    );
  }

  // --- Project Entry (ATS-style) ---
  pw.Widget _buildProjectEntry(
    ProjectModel proj,
    PdfColor primary,
    PdfColor secondary,
    PdfColor accent,
  ) {
    final String statusLabel = proj.status == ProjectStatus.production
        ? 'PRODUCTION'
        : proj.status == ProjectStatus.development
            ? 'IN DEVELOPMENT'
            : 'LEGACY';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Row 1: Title + Date
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${proj.title} (${proj.platform})',
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                  color: primary,
                ),
              ),
              pw.Text(
                proj.completionDate,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: secondary,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 2),

          // Row 2: Language, Status
          pw.Text(
            'Primary Language: ${proj.primaryLanguage}  |  Status: [$statusLabel]',
            style: pw.TextStyle(
              fontSize: 8.5,
              fontStyle: pw.FontStyle.italic,
              color: secondary,
            ),
          ),
          pw.SizedBox(height: 4),

          // Row 3: Description
          pw.Text(
            proj.description,
            style: pw.TextStyle(
              fontSize: 9,
              color: secondary,
              lineSpacing: 1.3,
            ),
          ),
          pw.SizedBox(height: 4),

          // Row 4: Tech Stack inline
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Tech Stack: ',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: primary,
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  proj.techStack.join(', '),
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontStyle: pw.FontStyle.italic,
                    color: secondary,
                  ),
                ),
              ),
            ],
          ),

          // Row 5: Repository link (if available)
          if (proj.repoUrl != null) ...[
            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                pw.Text(
                  'Repository: ',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: primary,
                  ),
                ),
                pw.UrlLink(
                  destination: proj.repoUrl!,
                  child: pw.Text(
                    proj.repoUrl!.replaceFirst('https://', ''),
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      color: accent,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Future<void> downloadPdfWeb(
      Uint8List pdfBytes, String filename) async {
    WebUtils.downloadFile(pdfBytes, filename, 'application/pdf');
  }
}
