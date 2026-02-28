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
      photo = pw.MemoryImage(photoBytes);
    } catch (e) {
      print("Error loading profile image asset: $e");
      // Fallback is handled by checking for null later in build
    }

    // ========== HIGH-END REFACTOR (MultiPage) ==========
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        theme: theme,
        footer: (context) => _buildFooter(),
        build: (context) {
          final experiencesList =
              experiences.isEmpty ? allWorkExperiences : experiences;
          final projectsList = projects.isEmpty ? allProjects : projects;
          final educationList = education.isEmpty ? allEducation : education;
          final achievementsList =
              achievements.isEmpty ? allAchievements : achievements;

          return [
            // TOP HEADER (Sporty/Anime HUD)
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 30),
              decoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey900,
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Profile Photo (Small in header)
                      if (photo != null)
                        pw.Container(
                          width: 60,
                          height: 60,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            image: pw.DecorationImage(
                                image: photo, fit: pw.BoxFit.cover),
                            border: pw.Border.all(
                                color: PdfColors.cyanAccent, width: 2),
                          ),
                        ),
                      pw.SizedBox(width: 20),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'ANGGA NUGRAHA PUTRA',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                letterSpacing: 2,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.UrlLink(
                              destination: 'https://windstrom5profile.netlify.app',
                              child: pw.Text(
                                'FULL STACK DEVELOPER // BACKEND SPECIALIST',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.cyanAccent,
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // QR Code linking to portfolio
                      pw.Container(
                        width: 55,
                        height: 55,
                        padding: const pw.EdgeInsets.all(3),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(4)),
                          border: pw.Border.all(
                              color: PdfColors.cyanAccent, width: 1.5),
                        ),
                        child: pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: 'https://windstrom5profile.netlify.app',
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 15),
                  // Contact HUD Bar
                  pw.Container(
                    height: 1,
                    color: PdfColors.blueGrey700,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _contactTag('LOC', 'Yogyakarta, ID'),
                      _contactTagLink(
                          'TEL', '+62 812-5311-0040', 'tel:+6281253110040'),
                      _contactTagLink('EML', 'anggagant@gmail.com',
                          'mailto:anggagant@gmail.com'),
                      _contactTagLink('WEB', 'windstrom5profile.netlify.app',
                          'https://windstrom5profile.netlify.app'),
                      _contactTagLink(
                          'GIT', 'Windstrom5', 'https://github.com/Windstrom5'),
                    ],
                  ),
                ],
              ),
            ),

            // PROFESSIONAL SUMMARY
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              decoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey800,
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 3,
                    height: 30,
                    color: PdfColors.cyanAccent,
                    margin: const pw.EdgeInsets.only(right: 10),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      'Full Stack Developer with hands-on experience in Laravel, Kotlin, and Flutter. '
                      'Passionate about building clean, scalable systems — from hospital management '
                      'software to interactive portfolio websites. Strong in backend architecture, '
                      'REST API design, and cross-platform mobile development.',
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfColors.white,
                        lineSpacing: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            pw.Partitions(
              children: [
                // LEFT COLUMN (Partition)
                pw.Partition(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.fromLTRB(30, 20, 15, 20),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('WORK EXPERIENCE'),
                        ...experiencesList
                            .map((exp) => _buildWorkExperience(exp)),
                        pw.SizedBox(height: 15),
                        _sectionHeader('CORE PROJECTS'),
                        ...projectsList
                            .take(4)
                            .map((proj) => _buildProject(proj)),
                      ],
                    ),
                  ),
                ),

                // RIGHT COLUMN (Partition)
                pw.Partition(
                  width: 210,
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.fromLTRB(15, 20, 30, 20),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('EDUCATION'),
                        ...educationList.map((edu) => _buildEducation(edu)),
                        pw.SizedBox(height: 15),
                        _sectionHeader('SKILLS'),
                        _buildSkillsSidebar('LANGUAGES',
                            ['Kotlin', 'Dart', 'Java', 'PHP', 'JS', 'SQL']),
                        pw.SizedBox(height: 10),
                        _buildSkillsSidebar('FRAMEWORKS',
                            ['Flutter', 'Laravel', 'Vue.js', 'Android']),
                        pw.SizedBox(height: 10),
                        _buildSkillsSidebar('TOOLS',
                            ['Git', 'Postgres', 'Firebase', 'UE5', 'Docker']),
                        pw.SizedBox(height: 15),
                        _sectionHeader('ACHIEVEMENTS'),
                        ...achievementsList
                            .map((ach) => _buildAchievement(ach)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _sectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15, top: 15),
      child: pw.Row(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey900,
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.cyanAccent,
                  letterSpacing: 2),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              height: 2,
              color: PdfColors.blueGrey900,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _sidebarHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.cyanAccent,
            letterSpacing: 2.5,
          ),
        ),
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 2, bottom: 8),
          height: 1,
          width: 40,
          color: PdfColors.cyanAccent,
        ),
      ],
    );
  }

  // Non-clickable contact tag (for location, etc.)
  pw.Widget _contactTag(String label, String value) {
    return pw.Row(
      children: [
        pw.Text('[$label]',
            style: pw.TextStyle(
                fontSize: 6,
                color: PdfColors.cyanAccent,
                fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(width: 4),
        pw.Text(value,
            style: const pw.TextStyle(fontSize: 6, color: PdfColors.white)),
      ],
    );
  }

  // Clickable contact tag with URL link
  pw.Widget _contactTagLink(String label, String value, String url) {
    return pw.Row(
      children: [
        pw.Text('[$label]',
            style: pw.TextStyle(
                fontSize: 6,
                color: PdfColors.cyanAccent,
                fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(width: 4),
        pw.UrlLink(
          destination: url,
          child: pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 6,
                  color: PdfColors.white,
                  decoration: pw.TextDecoration.underline)),
        ),
      ],
    );
  }

  pw.Widget _buildWorkExperience(WorkExperienceModel exp) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 18),
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
                      color: PdfColors.blueGrey900)),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey100,
                ),
                child: pw.Text(exp.period,
                    style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey700)),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(exp.company,
              style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.cyan800,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          ...exp.points.map((p) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 4, bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 3, right: 6),
                      width: 3,
                      height: 3,
                      decoration: const pw.BoxDecoration(
                          color: PdfColors.cyanAccent,
                          shape: pw.BoxShape.circle),
                    ),
                    pw.Expanded(
                        child: pw.Text(p,
                            style: const pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.blueGrey800,
                                lineSpacing: 1.4))),
                  ],
                ),
              )),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Text('TECH_STACK: ',
                  style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey400)),
              pw.Text(exp.techStack.join(" // "),
                  style: const pw.TextStyle(
                      fontSize: 7, color: PdfColors.blueGrey600)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProject(ProjectModel proj) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            left: pw.BorderSide(color: PdfColors.cyanAccent, width: 2)),
        color: PdfColors.blueGrey50,
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                proj.repoUrl != null
                    ? pw.UrlLink(
                        destination: proj.repoUrl!,
                        child: pw.Text(proj.title.toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue800,
                                decoration: pw.TextDecoration.underline)))
                    : pw.Text(proj.title.toUpperCase(),
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900)),
                pw.SizedBox(height: 2),
                pw.Text(proj.shortDescription,
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.blueGrey700)),
                pw.SizedBox(height: 4),
                pw.Text(proj.techStack.take(4).join(" . ").toUpperCase(),
                    style: pw.TextStyle(
                        fontSize: 6.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey400,
                        letterSpacing: 1)),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          // Decorative Right Box
          pw.Container(
            width: 35,
            height: 35,
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey900,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('PROJ',
                      style: pw.TextStyle(
                          fontSize: 6,
                          color: PdfColors.cyanAccent,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Container(
                      width: 15,
                      height: 1,
                      color: PdfColors.cyanAccent,
                      margin: const pw.EdgeInsets.symmetric(vertical: 2)),
                  pw.Text(
                      '#${proj.id.substring(0, proj.id.length < 3 ? proj.id.length : 3)}'
                          .toUpperCase(),
                      style: pw.TextStyle(fontSize: 5, color: PdfColors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildEducation(EducationModel edu) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(6),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blueGrey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(edu.degreeType.toUpperCase(),
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900)),
                    pw.Text(edu.schoolName,
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.cyan800)),
                    pw.Text('${edu.location} | ${edu.years}',
                        style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey400)),
                  ],
                ),
              ),
              pw.Container(
                width: 30,
                height: 30,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blueGrey300, width: 1),
                  color: PdfColors.white,
                ),
                child: pw.Center(
                  child: pw.Text("EDU",
                      style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey400)),
                ),
              ),
            ],
          ),
          // Learnings bullet points
          if (edu.learnings.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            ...edu.learnings.split('\n').where((l) => l.trim().isNotEmpty).map(
                  (line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text(
                      line.trim(),
                      style: const pw.TextStyle(
                          fontSize: 6.5, color: PdfColors.blueGrey600),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildAchievement(AchievementModel ach) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(ach.certificateName.toUpperCase(),
                    style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900)),
              ),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey100,
                ),
                child: pw.Text(ach.date,
                    style: pw.TextStyle(
                        fontSize: 6,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey600)),
              ),
            ],
          ),
          pw.Text(ach.organizationName,
              style: pw.TextStyle(
                  fontSize: 7.5,
                  color: PdfColors.blueGrey600,
                  fontStyle: pw.FontStyle.italic)),
          if (ach.description.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(ach.description,
                style: const pw.TextStyle(
                    fontSize: 6.5,
                    color: PdfColors.blueGrey500,
                    lineSpacing: 1.2)),
          ],
          pw.Container(
            height: 0.5,
            width: 50,
            color: PdfColors.blueGrey200,
            margin: const pw.EdgeInsets.only(top: 4),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSkillsSidebar(String title, List<String> skills) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.cyanAccent,
                letterSpacing: 1.5)),
        pw.SizedBox(height: 5),
        pw.Wrap(
          spacing: 5,
          runSpacing: 5,
          children: skills
              .map((s) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blueGrey800,
                      border: pw.Border.all(
                          color: PdfColors.blueGrey700, width: 0.5),
                    ),
                    child: pw.Text(s,
                        style: const pw.TextStyle(
                            fontSize: 6, color: PdfColors.white)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // Footer with clickable portfolio link
  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 8),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blueGrey900,
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.cyanAccent, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('ANGGA NUGRAHA // RESUME',
              style: pw.TextStyle(
                  fontSize: 6, color: PdfColors.blueGrey400, letterSpacing: 1)),
          pw.UrlLink(
            destination: 'https://windstrom5profile.netlify.app',
            child: pw.Row(
              children: [
                pw.Text('VIEW LIVE PORTFOLIO ',
                    style: pw.TextStyle(
                        fontSize: 6,
                        color: PdfColors.cyanAccent,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1)),
                pw.Text('windstrom5profile.netlify.app',
                    style: pw.TextStyle(
                        fontSize: 6,
                        color: PdfColors.white,
                        decoration: pw.TextDecoration.underline)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> downloadPdfWeb(Uint8List pdfBytes, String filename) async {
    WebUtils.downloadFile(pdfBytes, filename, 'application/pdf');
  }
}
