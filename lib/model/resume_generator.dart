import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../utils/web_utils.dart';
import 'project_model.dart';
import 'work_experience_model.dart';
import 'cv_models.dart';

class ResumePdf {
  Future<Uint8List> generate({
    required List<ProjectModel> projects,
    required List<WorkExperienceModel> experiences,
    required List<EducationModel> education,
    required List<AchievementModel> achievements,
    String themeType = 'midnight', // 'midnight', 'light_code', 'elegant', 'executive_zen'
  }) async {
    final pw.Document pdf = pw.Document();

    // --- Font Loading with Fallbacks ---
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

    // --- Profile Image with Fallback ---
    pw.MemoryImage? photo;
    try {
      final Uint8List photoBytes = await rootBundle
          .load('assets/profile.jpg')
          .then((data) => data.buffer.asUint8List());

      // Ensure it's an actual image by checking magic bytes (0xFF for JPEG, 0x89 for PNG)
      // On Web, a missing asset might return an HTML 404 page (starting with '<' 0x3C)
      if (photoBytes.isNotEmpty &&
          (photoBytes[0] == 0xFF || photoBytes[0] == 0x89)) {
        photo = pw.MemoryImage(photoBytes);
      } else {
        print(
            "Profile image is not a valid JPEG/PNG (likely a 404 Web HTML page fallback)");
      }
    } catch (e) {
      print("Error loading profile image asset: $e");
      // Fallback is handled by checking for null later in build
    }

    // --- Dynamic Color Palette ---
    final bool isDarkTheme = themeType == 'midnight';

    PdfColor mainBg;
    PdfColor surfaceColor;
    PdfColor accentCyan;
    PdfColor accentPink;
    PdfColor textPrimary;
    PdfColor textSecondary;
    PdfColor borderColor;

    if (themeType == 'elegant') {
      // Professional Elegance: High-end executive styling
      mainBg = PdfColor.fromInt(0xFFFAFAFA); // Ultra subtle warm white
      surfaceColor = PdfColors.white;
      accentCyan = PdfColor.fromInt(0xFF2C3E50); // Deep Slate Navy (Headers)
      accentPink = PdfColor.fromInt(0xFF9F8358); // Muted Gold/Bronze (Accents)
      textPrimary = PdfColor.fromInt(0xFF1F2937); // Rich Dark Charcoal
      textSecondary = PdfColor.fromInt(0xFF4B5563); // Warm Gray
      borderColor = PdfColor.fromInt(0xFFD1D5DB); // Neutral thin border
    } else if (themeType == 'executive_zen') {
      // Executive Zen: Ultra-premium minimalistic professional
      mainBg = PdfColors.white;
      surfaceColor = PdfColor.fromInt(0xFFF8FAFC); // Very light slate
      accentCyan = PdfColor.fromInt(0xFF0F172A); // Midnight Navy
      accentPink = PdfColor.fromInt(0xFFB45309); // Darker Amber/Gold
      textPrimary = PdfColor.fromInt(0xFF1E293B); // Slate 800
      textSecondary = PdfColor.fromInt(0xFF475569); // Slate 600
      borderColor = PdfColor.fromInt(0xFFE2E8F0); // Slate 200
    } else {
      // Midnight Cyber (Default)
      mainBg = PdfColor.fromInt(0xFF0D1117);
      surfaceColor = PdfColor.fromInt(0xFF161B22);
      accentCyan = PdfColor.fromInt(0xFF00E5FF); // Neon Cyan
      accentPink = PdfColor.fromInt(0xFFFF4081); // Neon Pink
      textPrimary = PdfColors.white;
      textSecondary = PdfColor.fromInt(0xFF8B949E);
      borderColor = PdfColor.fromInt(0xFF30363D);
    }

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      theme: theme,
      buildBackground: (context) {
        if (themeType == 'executive_zen') {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Stack(
              children: [
                pw.Container(color: mainBg),
                // Prestige Background Layer (Geometric Watermark)
                pw.Positioned.fill(
                  child: pw.Opacity(
                    opacity: 0.03,
                    child: pw.Column(
                      children: List.generate(15, (index) => pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        children: List.generate(8, (i) => pw.Container(
                          width: 40,
                          height: 40,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: accentCyan, width: 0.5),
                            shape: pw.BoxShape.circle,
                          ),
                        )),
                      )),
                    ),
                  ),
                ),
                // Top Accent Bar (Architectural)
                pw.Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: pw.Container(
                    height: 12,
                    decoration: pw.BoxDecoration(
                      gradient: pw.LinearGradient(
                        colors: [accentCyan, accentPink],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(color: mainBg),
        );
      },
    );

    // ========== HIGH-END REFACTOR (MultiPage) ==========
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        footer: (context) =>
            _buildFooter(isDarkTheme, textSecondary, accentCyan),
        header: (context) {
          if (context.pageNumber > 1) {
            return pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              color: surfaceColor,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ANGGA NUGRAHA PUTRA // RESUME',
                      style: pw.TextStyle(
                          color: accentCyan,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1)),
                  pw.Text('PAGE ${context.pageNumber}',
                      style: pw.TextStyle(
                          color: textSecondary,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold)),
                ],
              ),
            );
          }
          return pw.SizedBox();
        },
        build: (context) {
          final experiencesList =
              experiences.isEmpty ? allWorkExperiences : experiences;
          final projectsList = projects.isEmpty ? allProjects : projects;
          final educationList = education.isEmpty ? allEducation : education;
          final achievementsList =
              achievements.isEmpty ? allAchievements : achievements;

          if (themeType == 'elegant') {
            return _buildElegantLayout(
              projectsList,
              experiencesList,
              educationList,
              achievementsList,
              photo,
              mainBg,
              surfaceColor,
              accentCyan,
              accentPink,
              textPrimary,
              textSecondary,
              borderColor,
            );
          } else if (themeType == 'executive_zen') {
            return _buildExecutiveZenLayout(
              projectsList,
              experiencesList,
              educationList,
              achievementsList,
              photo,
              mainBg,
              surfaceColor,
              accentCyan,
              accentPink,
              textPrimary,
              textSecondary,
              borderColor,
            );
          } else {
            return _buildMidnightLayout(
              projectsList,
              experiencesList,
              educationList,
              achievementsList,
              photo,
              mainBg,
              surfaceColor,
              accentCyan,
              accentPink,
              textPrimary,
              textSecondary,
              borderColor,
              isDarkTheme,
            );
          }
        },
      ),
    );

    return pdf.save();
  }

  // --- 1. MIDNIGHT CYBER LAYOUT (Original High-Tech) ---
  List<pw.Widget> _buildMidnightLayout(
    List<ProjectModel> projects,
    List<WorkExperienceModel> experiences,
    List<EducationModel> education,
    List<AchievementModel> achievements,
    pw.MemoryImage? photo,
    PdfColor mainBg,
    PdfColor surfaceColor,
    PdfColor accentCyan,
    PdfColor accentPink,
    PdfColor textPrimary,
    PdfColor textSecondary,
    PdfColor borderColor,
    bool isDarkTheme,
  ) {
    return [
      _buildAnchor('top'),
      // --- FULL WIDTH HEADER ---
      pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(40, 40, 40, 30),
        decoration: pw.BoxDecoration(
          color: surfaceColor,
          border: pw.Border(
            bottom: pw.BorderSide(color: accentCyan, width: 1.5),
          ),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (photo != null)
              pw.UrlLink(
                destination: 'https://windstrom5profile.netlify.app',
                child: pw.Container(
                  width: 70,
                  height: 70,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    image: pw.DecorationImage(image: photo, fit: pw.BoxFit.cover),
                    border: pw.Border.all(color: accentCyan, width: 2),
                  ),
                ),
              ),
            pw.SizedBox(width: 25),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.FittedBox(
                    fit: pw.BoxFit.scaleDown,
                    child: pw.Text(
                      'ANGGA NUGRAHA PUTRA',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'FULL STACK DEVELOPER // BACKEND SPECIALIST',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: accentCyan,
                      letterSpacing: 3,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  // Minimalist Contact Row
                  pw.Row(
                    children: [
                      _cyberContactItem('LOC', 'Yogyakarta, ID', null,
                          accentCyan, textPrimary),
                      pw.SizedBox(width: 15),
                      _cyberContactItem(
                          'EML',
                          'anggagant@gmail.com',
                          'mailto:anggagant@gmail.com',
                          accentPink,
                          textPrimary),
                      pw.SizedBox(width: 15),
                      _cyberContactItem(
                          'GIT',
                          'Windstrom5',
                          'https://github.com/Windstrom5',
                          accentCyan,
                          textPrimary),
                    ],
                  ),
                ],
              ),
            ),
            pw.UrlLink(
              destination: 'https://windstrom5profile.netlify.app',
              child: pw.Container(
                width: 80,
                padding: const pw.EdgeInsets.all(0),
                decoration: pw.BoxDecoration(
                  color: surfaceColor,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: accentCyan, width: 1.5),
                ),
                child: pw.Column(
                  children: [
                    // QR Header strip
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: accentCyan,
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(4),
                          topRight: pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'SCAN_ME',
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                            color: mainBg,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    // QR Code
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: 'https://windstrom5profile.netlify.app/',
                        width: 58,
                        height: 58,
                        color: isDarkTheme ? PdfColors.white : PdfColors.black,
                      ),
                    ),
                    // Portfolio label
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: accentPink,
                        borderRadius: const pw.BorderRadius.only(
                          bottomLeft: pw.Radius.circular(4),
                          bottomRight: pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'PORTFOLIO',
                          style: pw.TextStyle(
                            fontSize: 5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      _buildInteractiveNavBar(accentCyan, textPrimary, surfaceColor),

      // --- MAIN BODY (Modular Vertical Flow) ---
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(40, 25, 40, 40),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Summary Section
            _buildAnchor('summary'),
            _sectionHeader('PROFESSIONAL_SUMMARY', accentPink),
            pw.Text(
              'Versatile Full Stack Developer and Architect with a track record of building complex, high-impact systems. '
              'Expert in Kotlin and Laravel for enterprise-grade solutions (WorkForce Management/Gym Systems), '
              'and a pioneer in high-tech immersive web experiences (Portofolio OS). Currently pushing boundaries in '
              'AI-driven audio processing and Unreal Engine 5 procedural content generation. '
              'Committed to architectural integrity and scalable cross-platform deployment.',
              style: pw.TextStyle(
                fontSize: 9,
                color: textSecondary,
                lineSpacing: 1.8,
              ),
            ),
            pw.SizedBox(height: 30),

            // Work Experience
            _buildAnchor('experience'),
            _sectionHeader('WORK_EXPERIENCE', accentCyan),
            ...experiences.map((exp) => _buildExperienceCard(
                exp, accentCyan, textPrimary, textSecondary)),
            pw.SizedBox(height: 10),

            // Technical Skills & Education (Side-by-side but protected)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildAnchor('skills'),
                      _sectionHeader('TECHNICAL_STK', accentPink),
                      _buildSkillLine('Kotlin / Android', 0.95, accentPink,
                          textPrimary, borderColor),
                      _buildSkillLine('Laravel / PHP', 0.90, accentCyan,
                          textPrimary, borderColor),
                      _buildSkillLine('Flutter / Dart', 0.88, accentPink,
                          textPrimary, borderColor),
                      _buildSkillLine('Vue.js / JS', 0.80, accentCyan,
                          textPrimary, borderColor),
                      _buildSkillLine('PostgreSQL', 0.85, accentPink,
                          textPrimary, borderColor),
                      _buildSkillLine('Git / CI-CD', 0.90, accentCyan,
                          textPrimary, borderColor),
                    ],
                  ),
                ),
                pw.SizedBox(width: 30),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildAnchor('education'),
                      _sectionHeader('EDUCATION', accentCyan),
                      ...education.map((edu) => _buildEducationItem(
                          edu, accentCyan, textPrimary, textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Projects Grid
            _buildAnchor('projects'),
            _sectionHeader('CORE_PROJECTS', accentPink),
            pw.Wrap(
              spacing: 20,
              runSpacing: 20,
              children: projects
                  .take(4)
                  .map((proj) => pw.SizedBox(
                        width: 245,
                        child: _buildProjectCard(proj, accentPink, surfaceColor,
                            textPrimary, textSecondary, borderColor),
                      ))
                  .toList(),
            ),
            pw.SizedBox(height: 30),

            // Achievements & Interests
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('ACHIEVEMENTS', accentCyan),
                      ...achievements.map((ach) => _buildAchievementItem(
                          ach, accentCyan, textPrimary, textSecondary)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 30),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('FIELD_INTERESTS', accentPink),
                      _buildInterestTag(
                          'Backend Systems', accentPink, textPrimary),
                      _buildInterestTag(
                          'Mobile Architecture', accentCyan, textPrimary),
                      _buildInterestTag(
                          'Game Development', accentPink, textPrimary),
                    ],
                  ),
                ),
              ],
            ),
            _buildFinalCTA(accentPink, textPrimary, surfaceColor),
          ],
        ),
      ),
    ];
  }

  // --- 3. PROFESSIONAL ELEGANCE LAYOUT (Premium Corporate) ---
  List<pw.Widget> _buildElegantLayout(
    List<ProjectModel> projects,
    List<WorkExperienceModel> experiences,
    List<EducationModel> education,
    List<AchievementModel> achievements,
    pw.MemoryImage? photo,
    PdfColor mainBg,
    PdfColor surfaceColor,
    PdfColor accentCyan,
    PdfColor accentPink,
    PdfColor textPrimary,
    PdfColor textSecondary,
    PdfColor borderColor,
  ) {
    final List<pw.Widget> layout = [];
    const pw.EdgeInsets horizontalPadding =
        pw.EdgeInsets.symmetric(horizontal: 40);

    // --- Premium Picture Card Header ---
    layout.add(_buildAnchor('top'));
    layout.add(pw.Container(
      width: double.infinity,
      color: accentCyan,
      padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // 1. Profile Photo (Left)
          if (photo != null)
            pw.UrlLink(
              destination: 'https://windstrom5profile.netlify.app',
              child: pw.Container(
                width: 100,
                height: 100,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: PdfColors.white, width: 3),
                  boxShadow: const [
                    pw.BoxShadow(
                      color: PdfColors.black,
                      offset: PdfPoint(0, 4),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: pw.ClipOval(
                  child: pw.Image(photo, fit: pw.BoxFit.cover),
                ),
              ),
            ),
          if (photo != null) pw.SizedBox(width: 30),
          
          // 2. Text Content (Middle)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.FittedBox(
                  fit: pw.BoxFit.scaleDown,
                  child: pw.Text(
                    'ANGGA NUGRAHA PUTRA',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: accentPink,
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                  child: pw.Text(
                    'FULL STACK DEVELOPER',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Wrap(
                  spacing: 15,
                  runSpacing: 5,
                  children: [
                    _elegantHeaderInfo('Yogyakarta, ID', accentPink),
                    pw.UrlLink(
                      destination: 'mailto:anggagant@gmail.com',
                      child: _elegantHeaderInfo('anggagant@gmail.com', accentPink),
                    ),
                    pw.UrlLink(
                      destination: 'https://github.com/Windstrom5',
                      child: _elegantHeaderInfo('github.com/Windstrom5', accentPink),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 25),
          
          // 3. QR Code (Right) — Elegant Style
          pw.UrlLink(
            destination: 'https://windstrom5profile.netlify.app',
            child: pw.Column(
              children: [
                pw.Container(
                  width: 78,
                  padding: const pw.EdgeInsets.all(0),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: accentPink, width: 2.5),
                    boxShadow: const [
                      pw.BoxShadow(
                        color: PdfColor.fromInt(0x33000000),
                        offset: PdfPoint(0, 3),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: pw.Column(
                    children: [
                      // Elegant gold header
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: accentPink,
                          borderRadius: const pw.BorderRadius.only(
                            topLeft: pw.Radius.circular(5),
                            topRight: pw.Radius.circular(5),
                          ),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'PORTFOLIO',
                            style: pw.TextStyle(
                              fontSize: 6,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ),
                      ),
                      // QR Code body
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: 'https://windstrom5profile.netlify.app/',
                          width: 55,
                          height: 55,
                          color: accentCyan,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Scan to Visit',
                  style: pw.TextStyle(
                    fontSize: 6,
                    color: accentPink,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));

    layout.add(pw.SizedBox(height: 30));
    layout.add(_buildInteractiveNavBar(accentPink, PdfColors.white, accentCyan));

    // --- Executive Summary ---
    layout.add(_buildAnchor('summary'));
    layout.add(pw.Padding(
        padding: horizontalPadding,
        child: pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border:
                  pw.Border(left: pw.BorderSide(color: accentPink, width: 3)),
              boxShadow: const [
                pw.BoxShadow(
                    color: PdfColor.fromInt(0x1A000000),
                    blurRadius: 4,
                    offset: PdfPoint(0, 2))
              ],
            ),
            child: pw.Text(
              'Results-oriented Software Engineer specializing in the design and orchestration of scalable enterprise ecosystems. Proficient in delivering robust backends with Laravel and high-integrity mobile applications with Kotlin. Demonstrated success in transforming complex business requirements into seamless digital products, from health-analytics gamification to workforce productivity suites. Dedicated to writing clean, maintainable code and steering projects from architectural conception to production-grade deployment.',
              textAlign: pw.TextAlign.justify,
              style: pw.TextStyle(
                  fontSize: 10, color: textSecondary, lineSpacing: 1.6),
            ))));

    layout.add(pw.SizedBox(height: 30));

    // --- Professional Experience ---
    layout.add(_buildAnchor('experience'));
    layout.add(pw.Padding(
        padding: horizontalPadding,
        child: _elegantSectionHeader(
            'PROFESSIONAL EXPERIENCE', accentCyan, accentPink)));

    for (var exp in experiences) {
      layout.add(pw.Padding(
          padding: horizontalPadding.copyWith(bottom: 15),
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header: Title (left) & Date (right)
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(exp.title,
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: accentCyan)),
                      pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                              color: accentCyan,
                              borderRadius: pw.BorderRadius.circular(3)),
                          child: pw.Text(exp.period.toUpperCase(),
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white)))
                    ]),
                pw.SizedBox(height: 3),
                // Company
                pw.Text(exp.company,
                    style: pw.TextStyle(
                        fontSize: 10,
                        color: accentPink,
                        fontStyle: pw.FontStyle.italic)),
                pw.SizedBox(height: 6),
                // Tiny sleek divider
                pw.Container(
                  height: 0.5,
                  width: double.infinity,
                  color: borderColor,
                ),
                pw.SizedBox(height: 8),
                // Bullet points
                ...exp.points
                    .map((pt) => pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Padding(
                                  padding: const pw.EdgeInsets.only(
                                      top: 3.5, right: 8),
                                  child: pw.Container(
                                      width: 4,
                                      height: 4,
                                      decoration: pw.BoxDecoration(
                                          color: accentCyan,
                                          shape: pw.BoxShape.circle))),
                              pw.Expanded(
                                  child: pw.Text(pt,
                                      style: pw.TextStyle(
                                          fontSize: 9.5,
                                          color: textSecondary,
                                          lineSpacing: 1.5))),
                            ])))
                    ,
              ])));
    }

    layout.add(pw.SizedBox(height: 10));

    // --- Select Projects (Grid Layout via Wrap) ---
    layout.add(_buildAnchor('projects'));
    layout.add(pw.Padding(
        padding: horizontalPadding,
        child:
            _elegantSectionHeader('SELECT PROJECTS', accentCyan, accentPink)));

    layout.add(pw.Padding(
        padding: horizontalPadding,
        child: pw.Wrap(
          spacing: 15,
          runSpacing: 15,
          children: projects
              .take(4)
              .map((proj) {
                final String? link =
                    proj.demoUrl?.isNotEmpty == true ? proj.demoUrl : proj.repoUrl;
                final card = pw.Container(
                    width: 235,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: borderColor, width: 0.5),
                      boxShadow: const [
                        pw.BoxShadow(
                            color: PdfColor.fromInt(0x0A000000),
                            blurRadius: 2,
                            offset: PdfPoint(0, 1))
                      ],
                    ),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Expanded(
                                    child: pw.Text(proj.title,
                                        style: pw.TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: pw.FontWeight.bold,
                                            color: textPrimary))),
                                if (link != null)
                                  pw.Text('LINK_ACTIVE',
                                      style: pw.TextStyle(
                                          fontSize: 7,
                                          color: accentPink,
                                          fontWeight: pw.FontWeight.bold)),
                              ]),
                          pw.SizedBox(height: 6),
                          pw.Text(proj.description,
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  color: textSecondary,
                                  lineSpacing: 1.4)),
                          pw.SizedBox(height: 8),
                          pw.Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: proj.techStack
                                  .map((tech) => pw.Container(
                                      padding: const pw.EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      decoration: pw.BoxDecoration(
                                          color: surfaceColor,
                                          borderRadius:
                                              pw.BorderRadius.circular(2)),
                                      child: pw.Text(tech,
                                          style: pw.TextStyle(
                                              fontSize: 7,
                                              color: accentCyan,
                                              fontWeight: pw.FontWeight.bold))))
                                  .toList())
                        ]));
                return link != null ? pw.UrlLink(destination: link, child: card) : card;
              })
              .toList(),
        )));

    layout.add(pw.SizedBox(height: 30));

    // --- Education & Skills (Classic Two Column) ---
    layout.add(pw.Padding(
        padding: horizontalPadding.copyWith(bottom: 30),
        child:
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          // Education Column
          pw.Expanded(
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                _buildAnchor('education'),
                _elegantSectionHeader('EDUCATION', accentCyan, accentPink),
                ...education.map((edu) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 12),
                    padding: const pw.EdgeInsets.only(bottom: 12),
                    decoration: pw.BoxDecoration(
                        border: pw.Border(
                            bottom:
                                pw.BorderSide(color: borderColor, width: 0.5))),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.Expanded(
                                    child: pw.Text(edu.schoolName.toUpperCase(),
                                        style: pw.TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: pw.FontWeight.bold,
                                            color: accentCyan))),
                                pw.SizedBox(width: 8),
                                pw.Text(edu.years,
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: accentPink)),
                              ]),
                          pw.SizedBox(height: 4),
                          pw.Text(edu.degreeType,
                              style: pw.TextStyle(
                                  fontSize: 8.5,
                                  color: textSecondary,
                                  fontWeight: pw.FontWeight.bold)),
                        ]))),
              ])),
          pw.SizedBox(width: 40),
          // Skills Column
          pw.Expanded(
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                _buildAnchor('skills'),
                _elegantSectionHeader(
                    'TECHNICAL EXPERTISE', accentCyan, accentPink),
                _buildSkillCategoryRow(
                    'Languages',
                    'Kotlin - Dart - PHP - JS - Laravel - Flutter - Vue.js',
                    accentCyan,
                    textSecondary),
                _buildSkillCategoryRow(
                    'Database & Tools',
                    'PostgreSQL - MySQL - Git - CI/CD',
                    accentCyan,
                    textSecondary),
                _buildSkillCategoryRow(
                    'Core Competencies',
                    'Backend Architecture - REST APIs - Mobile Architecture',
                    accentCyan,
                    textSecondary),
              ])),
        ])));

    layout.add(pw.Padding(
      padding: horizontalPadding,
      child: _buildFinalCTA(accentPink, textPrimary, PdfColors.white),
    ));

    return layout;
  }

  pw.Widget _elegantHeaderInfo(String text, PdfColor accent) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 3,
          height: 3,
          decoration: pw.BoxDecoration(
            color: accent,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColors.white,
            fontWeight: pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSkillCategoryRow(
      String title, String items, PdfColor primary, PdfColor secondary) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
              width: 90,
              child: pw.Text(title,
                  textAlign: pw.TextAlign.left,
                  style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: primary))),
          pw.SizedBox(width: 10),
          pw.Expanded(
              child: pw.Text(items,
                  style: pw.TextStyle(
                      fontSize: 8.5, color: secondary, lineSpacing: 1.5))),
        ],
      ),
    );
  }

  pw.Widget _elegantSectionHeader(
      String title, PdfColor accentCyan, PdfColor accentPink) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15, top: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: accentCyan,
              letterSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(height: 2, width: 40, color: accentPink),
        ],
      ),
    );
  }

  // --- PREMIUM CYBER COMPONENTS ---

  pw.Widget _sectionHeader(String title, PdfColor accent) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: accent,
              letterSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(height: 1, width: 30, color: accent),
        ],
      ),
    );
  }

  pw.Widget _cyberContactItem(String label, String value, String? url,
      PdfColor color, PdfColor textPrimary) {
    final text = pw.RichText(
      text: pw.TextSpan(children: [
        pw.TextSpan(
            text: '$label ',
            style: pw.TextStyle(
                fontSize: 7, fontWeight: pw.FontWeight.bold, color: color)),
        pw.TextSpan(
            text: value, style: pw.TextStyle(fontSize: 7, color: textPrimary)),
      ]),
    );
    return url != null ? pw.UrlLink(destination: url, child: text) : text;
  }

  pw.Widget _buildExperienceCard(WorkExperienceModel exp, PdfColor accent,
      PdfColor textPrimary, PdfColor textSec) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(exp.title.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: textPrimary)),
              pw.Text(exp.period,
                  style: pw.TextStyle(
                      fontSize: 7,
                      color: accent,
                      fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Text(exp.company,
              style: pw.TextStyle(
                  fontSize: 8.5,
                  color: accent,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          ...exp.points.map((p) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 4, bottom: 3),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                        width: 2,
                        height: 2,
                        margin: const pw.EdgeInsets.only(top: 3, right: 6),
                        color: accent),
                    pw.Expanded(
                        child: pw.Text(p,
                            style: pw.TextStyle(
                                fontSize: 8,
                                color: textSec,
                                lineSpacing: 1.4))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  pw.Widget _buildProjectCard(
      ProjectModel proj,
      PdfColor accent,
      PdfColor surface,
      PdfColor textPrimary,
      PdfColor textSec,
      PdfColor borderColor) {
    final String? link =
        proj.demoUrl?.isNotEmpty == true ? proj.demoUrl : proj.repoUrl;
    final widget = pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: surface,
        border: pw.Border.all(color: borderColor, width: 0.5),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(proj.title.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: textPrimary)),
              if (link != null)
                pw.Text('LINK_ACTIVE',
                    style: pw.TextStyle(
                        fontSize: 6,
                        color: accent,
                        fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(proj.shortDescription,
              style: pw.TextStyle(fontSize: 7.5, color: textSec)),
          pw.SizedBox(height: 5),
          pw.Text(proj.techStack.join(" // ").toUpperCase(),
              style: pw.TextStyle(
                  fontSize: 6.5,
                  color: accent,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1)),
        ],
      ),
    );
    return link != null ? pw.UrlLink(destination: link, child: widget) : widget;
  }

  pw.Widget _buildEducationItem(EducationModel edu, PdfColor accent,
      PdfColor textPrimary, PdfColor textSec) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(edu.schoolName.toUpperCase(),
              style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: textPrimary)),
          pw.Text(edu.degreeType,
              style: pw.TextStyle(fontSize: 7.5, color: accent)),
          pw.Text(edu.years, style: pw.TextStyle(fontSize: 7, color: textSec)),
        ],
      ),
    );
  }

  pw.Widget _buildSkillLine(String name, double level, PdfColor accent,
      PdfColor textPrimary, PdfColor borderColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(name,
                  style: pw.TextStyle(fontSize: 7.5, color: textPrimary)),
              pw.Text('${(level * 100).toInt()}%',
                  style: pw.TextStyle(
                      fontSize: 7,
                      color: accent,
                      fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Container(
            height: 1.5,
            width: double.infinity,
            color: borderColor,
            child: pw.Row(children: [
              pw.Expanded(
                  flex: (level * 100).toInt(),
                  child: pw.Container(color: accent)),
              pw.Spacer(flex: (100 - level * 100).toInt())
            ]),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAchievementItem(AchievementModel ach, PdfColor accent,
      PdfColor textPrimary, PdfColor textSec) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(ach.certificateName,
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: textPrimary)),
          pw.Text(ach.organizationName,
              style: pw.TextStyle(fontSize: 7, color: accent)),
        ],
      ),
    );
  }

  pw.Widget _buildInterestTag(
      String label, PdfColor accent, PdfColor textPrimary) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.Container(
              width: 3,
              height: 3,
              color: accent,
              margin: const pw.EdgeInsets.only(right: 8)),
          pw.Text(label.toUpperCase(),
              style: pw.TextStyle(
                  fontSize: 7, color: textPrimary, letterSpacing: 1)),
        ],
      ),
    );
  }

  // --- 4. EXECUTIVE ZEN LAYOUT (Ultra-Premium Portfolio) ---
  List<pw.Widget> _buildExecutiveZenLayout(
    List<ProjectModel> projects,
    List<WorkExperienceModel> experiences,
    List<EducationModel> education,
    List<AchievementModel> achievements,
    pw.MemoryImage? photo,
    PdfColor mainBg,
    PdfColor surfaceColor,
    PdfColor accentCyan,
    PdfColor accentPink,
    PdfColor textPrimary,
    PdfColor textSecondary,
    PdfColor borderColor,
  ) {
    return [
      _buildAnchor('top'),
      // Header Section (Architectural Grid)
      pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(40, 35, 40, 25),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: borderColor, width: 0.5),
          ),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // 1. Profile Photo (Left)
            if (photo != null)
              pw.UrlLink(
                destination: 'https://windstrom5profile.netlify.app',
                child: pw.Container(
                  width: 85,
                  height: 85,
                  padding: const pw.EdgeInsets.all(3),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: accentCyan, width: 1.5),
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.ClipOval(
                    child: pw.Image(photo, fit: pw.BoxFit.cover),
                  ),
                ),
              ),
            if (photo != null) pw.SizedBox(width: 25),
            
            // 2. Text Content (Middle)
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.FittedBox(
                    fit: pw.BoxFit.scaleDown,
                    child: pw.Text(
                      'ANGGA NUGRAHA PUTRA',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: accentCyan,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Container(width: 40, height: 1.5, color: accentPink),
                      pw.SizedBox(width: 10),
                      pw.Text(
                        'FULL STACK DEVELOPER // ARCHITECT',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: accentPink,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  pw.Wrap(
                    spacing: 15,
                    runSpacing: 5,
                    children: [
                      _zenContactItem('YOGYAKARTA, ID', accentCyan),
                      _zenContactItem('ANGGAGANT@GMAIL.COM', accentCyan,
                          url: 'mailto:anggagant@gmail.com'),
                      _zenContactItem('GITHUB.COM/WINDSTROM5', accentCyan,
                          url: 'https://github.com/Windstrom5'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            
            // 3. QR Code (Right) — Executive Zen Style
            pw.UrlLink(
              destination: 'https://windstrom5profile.netlify.app',
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 78,
                    padding: const pw.EdgeInsets.all(0),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: borderColor, width: 0.5),
                      boxShadow: [
                        pw.BoxShadow(
                          color: PdfColor.fromInt(0x12000000),
                          offset: const PdfPoint(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: pw.Column(
                      children: [
                        // Architectural top accent
                        pw.Container(
                          width: double.infinity,
                          height: 3,
                          decoration: pw.BoxDecoration(
                            gradient: pw.LinearGradient(
                              colors: [accentCyan, accentPink],
                            ),
                            borderRadius: const pw.BorderRadius.only(
                              topLeft: pw.Radius.circular(3),
                              topRight: pw.Radius.circular(3),
                            ),
                          ),
                        ),
                        // QR Code
                        pw.Container(
                          padding: const pw.EdgeInsets.fromLTRB(8, 8, 8, 6),
                          child: pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: 'https://windstrom5profile.netlify.app/',
                            width: 55,
                            height: 55,
                            color: accentCyan,
                          ),
                        ),
                        // Subtle URL label
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.only(bottom: 5),
                          child: pw.Center(
                            child: pw.Text(
                              'PORTFOLIO',
                              style: pw.TextStyle(
                                fontSize: 5.5,
                                fontWeight: pw.FontWeight.bold,
                                color: accentPink,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      _buildInteractiveNavBar(accentPink, accentCyan, surfaceColor),

      // Body Content
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 40),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Divider(color: borderColor, thickness: 0.5),
            pw.SizedBox(height: 20),

            // Summary
            _buildAnchor('summary'),
            pw.Text(
              'PROFESSIONAL SUMMARY',
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: accentCyan,
                  letterSpacing: 1.5),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Architectural-focused Full Stack Developer with specialized expertise in backend orchestration, mobile ecosystems, and innovative system simulations. Proven ability to deliver high-performance enterprise solutions, from automated workforce management systems to AI-powered multimedia research. Expertly bridges the gap between complex logic—such as procedural content generation in UE5 and neural vocal separation—and premium, user-centric interface design. Driven by technical excellence and the pursuit of scalable, future-proof engineering.',
              style: pw.TextStyle(
                  fontSize: 9.5, color: textSecondary, lineSpacing: 1.6),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 30),

            // Experience
            _buildAnchor('experience'),
            _zenSectionHeader('PROFESSIONAL EXPERIENCE', accentCyan, accentPink),
            ...experiences.map((exp) => _buildZenExperienceItem(
                exp, accentCyan, textPrimary, textSecondary, accentPink)),
            pw.SizedBox(height: 10),

            // Two Column for Skills & Education
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildAnchor('skills'),
                      _zenSectionHeader(
                          'TECHNICAL EXPERTISE', accentCyan, accentPink),
                      pw.Table(
                        columnWidths: {
                          0: const pw.FixedColumnWidth(100),
                          1: const pw.FlexColumnWidth(),
                        },
                        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                        children: [
                          _buildZenSkillTableRow('Languages',
                              'Kotlin, Dart, PHP, JavaScript, C++, SQL', textPrimary, textSecondary, accentPink),
                          _buildZenSkillTableRow('Frameworks',
                              'Laravel, Flutter, Vue.js, CodeIgniter, Compose', textPrimary, textSecondary, accentPink),
                          _buildZenSkillTableRow('Core Tech',
                              'PostgreSQL, MySQL, REST API, UE5, AI Integration', textPrimary, textSecondary, accentPink),
                          _buildZenSkillTableRow('DevOps/Tools',
                              'Git, CI/CD, Linux Server, Unit Testing', textPrimary, textSecondary, accentPink),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 40),
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildAnchor('education'),
                      _zenSectionHeader('EDUCATION', accentCyan, accentPink),
                      ...education.take(2).map((edu) => _buildZenEducationItem(
                          edu, accentCyan, accentPink, textPrimary, textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Projects
            _buildAnchor('projects'),
            _zenSectionHeader('SELECTED PROJECTS', accentCyan, accentPink),
            pw.Wrap(
              spacing: 20,
              runSpacing: 15,
              children: projects.take(4).map((proj) {
                return pw.Container(
                  width: 245,
                  child: _buildZenProjectItem(
                      proj, accentCyan, textPrimary, textSecondary, borderColor),
                );
              }).toList(),
            ),
            _buildFinalCTA(accentPink, accentCyan, surfaceColor),
          ],
        ),
      ),
    ];
  }

  pw.Widget _zenContactItem(String text, PdfColor color, {String? url}) {
    final widget = pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(width: 3, height: 3, color: color),
        pw.SizedBox(width: 5),
        pw.Text(text, style: pw.TextStyle(fontSize: 8, color: color)),
      ],
    );
    return url != null ? pw.UrlLink(destination: url, child: widget) : widget;
  }

  pw.Widget _zenSectionHeader(String title, PdfColor primary, PdfColor accent) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 18),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 6,
                height: 6,
                decoration: pw.BoxDecoration(
                  color: accent,
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: primary, width: 1),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: primary,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  height: 0.5,
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [accent, PdfColors.white],
                    ),
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Container(
            margin: const pw.EdgeInsets.only(left: 14),
            width: 30,
            height: 1.5,
            color: accent,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildZenExperienceItem(WorkExperienceModel exp, PdfColor primary,
      PdfColor textP, PdfColor textS, PdfColor accent) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 22),
      padding: const pw.EdgeInsets.only(left: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: accent, width: 1)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(exp.title.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: textP,
                      letterSpacing: 0.5)),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF1F5F9),
                  borderRadius: pw.BorderRadius.circular(2),
                ),
                child: pw.Text(exp.period,
                    style: pw.TextStyle(
                        fontSize: 7.5, color: textS, fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Row(
            children: [
              pw.Text(exp.company,
                  style: pw.TextStyle(
                      fontSize: 9.5, color: accent, fontWeight: pw.FontWeight.bold)),
              pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6), child: pw.Text('-', style: pw.TextStyle(color: textS))),
              pw.Text(exp.location,
                  style: pw.TextStyle(fontSize: 8, color: textS)),
            ],
          ),
          pw.SizedBox(height: 10),
          ...exp.points.map((p) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6, left: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 3.5, right: 10),
                      child: pw.Container(width: 3, height: 3, color: accent),
                    ),
                    pw.Expanded(
                        child: pw.Text(p,
                            style: pw.TextStyle(
                                fontSize: 9.3,
                                color: textS,
                                lineSpacing: 1.5,
                                letterSpacing: 0.2))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  pw.TableRow _buildZenSkillTableRow(String title, String data, PdfColor textP, PdfColor textS, PdfColor accent) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10, right: 12),
          child: pw.Row(
            children: [
              pw.Container(
                width: 3,
                height: 3,
                margin: const pw.EdgeInsets.only(right: 6),
                decoration: pw.BoxDecoration(
                  color: accent,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.Text(title,
                  style: pw.TextStyle(
                      fontSize: 9, color: textP, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Text(data,
              style: pw.TextStyle(fontSize: 9, color: textS, lineSpacing: 1.3)),
        ),
      ],
    );
  }

  pw.Widget _buildZenEducationItem(
      EducationModel edu, PdfColor primary, PdfColor accent, PdfColor textP, PdfColor textS) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(edu.schoolName.toUpperCase(),
              style: pw.TextStyle(
                  fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: textP, letterSpacing: 0.3)),
          pw.SizedBox(height: 2),
          pw.Text(edu.degreeType.toUpperCase(),
              style: pw.TextStyle(fontSize: 8, color: accent, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
          pw.Text(edu.years,
              style: pw.TextStyle(fontSize: 8, color: textS, fontStyle: pw.FontStyle.italic)),
        ],
      ),
    );
  }

  pw.Widget _buildZenProjectItem(ProjectModel proj, PdfColor primary,
      PdfColor textP, PdfColor textS, PdfColor borderColor) {
    final String? link =
        proj.demoUrl?.isNotEmpty == true ? proj.demoUrl : proj.repoUrl;
    final widget = pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor, width: 0.3),
        borderRadius: pw.BorderRadius.circular(6),
        color: PdfColor.fromInt(0xFFF8FAFC), // Brighter Zen White
        boxShadow: [
          pw.BoxShadow(
            color: PdfColor.fromInt(0xFFE2E8F0),
            offset: const PdfPoint(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(proj.title,
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: textP,
                        letterSpacing: 0.5)),
              ),
              pw.Container(
                width: 14,
                height: 14,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: primary, width: 0.5),
                ),
                child: pw.Center(
                  child: pw.Container(width: 2, height: 2, color: primary),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(proj.shortDescription,
              style: pw.TextStyle(
                  fontSize: 8.5, color: textS, lineSpacing: 1.4, letterSpacing: 0.1)),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Container(
                width: 8,
                height: 0.5,
                color: primary,
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: pw.Text(proj.techStack.take(3).join(' - ').toUpperCase(),
                    style: pw.TextStyle(
                        fontSize: 6.5,
                        fontWeight: pw.FontWeight.bold,
                        color: primary,
                        letterSpacing: 1.2)),
              ),
            ],
          ),
        ],
      ),
    );
    return link != null ? pw.UrlLink(destination: link, child: widget) : widget;
  }

  // --- INTERACTIVE ENHANCEMENTS ---

  pw.Widget _buildAnchor(String id) {
    return pw.Anchor(name: id, child: pw.SizedBox(height: 0, width: 0));
  }

  pw.Widget _buildInteractiveNavBar(PdfColor accent, PdfColor text, PdfColor bg) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      color: bg,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _navItem('SUMMARY', 'summary', accent),
          _navItem('EXPERIENCE', 'experience', accent),
          _navItem('PROJECTS', 'projects', accent),
          _navItem('SKILLS', 'skills', accent),
          _navItem('EDUCATION', 'education', accent),
        ],
      ),
    );
  }

  pw.Widget _navItem(String label, String anchor, PdfColor color) {
    return pw.UrlLink(
      destination: '#$anchor',
      child: pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  pw.Widget _buildEmailButton(PdfColor accent, PdfColor text) {
    return pw.UrlLink(
      destination: 'mailto:anggagant@gmail.com',
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: pw.BoxDecoration(
          color: accent,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          'SEND EMAIL',
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: text,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildGithubButton(PdfColor accent, PdfColor text) {
    return pw.UrlLink(
      destination: 'https://github.com/Windstrom5',
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: accent, width: 1),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          'GITHUB PROFILE',
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: accent,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildFinalCTA(PdfColor accent, PdfColor text, PdfColor bg) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 30),
      child: pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(30),
        decoration: pw.BoxDecoration(
          color: bg,
          border: pw.Border.all(color: accent, width: 1),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              "LET'S BUILD SOMETHING EXTRAORDINARY",
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: text,
                letterSpacing: 2,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              "I'm currently open to new opportunities and collaborations.",
              style: pw.TextStyle(fontSize: 10, color: text),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                _buildEmailButton(accent, bg),
                pw.SizedBox(width: 20),
                _buildGithubButton(accent, bg),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildFooter(
      bool isDarkTheme, PdfColor textSecondary, PdfColor accentCyan) {
    return pw.Container(
      height: 30,
      color: isDarkTheme ? const PdfColor.fromInt(0xFF0D1117) : PdfColors.white,
      padding: const pw.EdgeInsets.symmetric(horizontal: 40),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.UrlLink(
            destination: '#top',
            child: pw.Text('TOP',
                style: pw.TextStyle(
                    fontSize: 6,
                    color: accentCyan,
                    fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(width: 8),
          pw.Text('GEN_LINK_ACTIVE // PORTFOLIO_SYS',
              style: pw.TextStyle(fontSize: 6, color: textSecondary)),
          pw.UrlLink(
              destination: 'https://windstrom5profile.netlify.app/',
              child: pw.Text('WINDSTROM5PROFILE.NETLIFY.APP',
                  style: pw.TextStyle(
                      fontSize: 6,
                      color: accentCyan,
                      fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );
  }

  static Future<void> downloadPdfWeb(
      Uint8List pdfBytes, String filename) async {
    WebUtils.downloadFile(pdfBytes, filename, 'application/pdf');
  }
}
