import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;

class ResumePdf {
  final pw.Document pdf = pw.Document();

  Future<Uint8List> generate() async {
    final Uint8List photoBytes = await rootBundle
        .load('assets/myself.jpg')
        .then((data) => data.buffer.asUint8List());
    final pw.MemoryImage photo = pw.MemoryImage(photoBytes);

    // ========== PAGE 1 ==========
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(10),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 80,
                    height: 80,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blue800, width: 2),
                      borderRadius: pw.BorderRadius.circular(40),
                    ),
                    child: pw.ClipOval(child: pw.Image(photo, fit: pw.BoxFit.cover)),
                  ),
                  pw.SizedBox(width: 15),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Angga Nugraha Putra S.Kom',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Full Stack Developer\n'
                          'Yogyakarta, Indonesia\n'
                          'anggagant@gmail.com | +62 812-5311-0040\n'
                          'LinkedIn: linkedin.com/in/angga-nugraha-putra\n'
                          'GitHub: github.com/Windstrom5',
                          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800, height: 1.2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 15),

              _sectionTitle('Personal Details', fontSize: 14),
              _personalDetailsTable(fontSize: 9),
              pw.SizedBox(height: 12),

              _sectionTitle('Profile', fontSize: 14),
              pw.Text(
                'Enthusiastic and detail-oriented Full Stack Developer with strong foundations in modern web and mobile development.',
                style: pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 12),

              _sectionTitle('Skills', fontSize: 14),
              _skillsWrap([
                'Vue.js', 'Kotlin', 'Laravel', 'Java', 'PostgreSQL', 'MySQL',
                'Android Studio', 'VS Code', 'CodeIgniter', 'Premiere Pro',
                'Photoshop', 'NetBeans IDE',
              ]),
              pw.SizedBox(height: 12),

              // Two columns
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left column
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Professional Experience', fontSize: 14),
                        _jobItem(
                          title:
                              'Software Programmer - PT. Kilang Pertamina Internasional RU VII Kasim',
                          duration: 'Sep 2023 - Jan 2024',
                          points: [
                            'Developed mobile overtime tracking app with Kotlin.',
                            'Backend with Laravel + PostgreSQL.',
                            'Collaborated with HR and IT teams.',
                          ],
                          fontSize: 9,
                        ),
                        pw.SizedBox(height: 8),
                        _jobItem(
                          title: 'Volunteer Instructor - SDN Sendangsari (KKN Program)',
                          duration: 'July 2023',
                          points: [
                            'Trained students in Word/Excel.',
                            'Designed tailored learning materials.',
                            'Supported computer literacy.',
                          ],
                          fontSize: 9,
                        ),
                        pw.SizedBox(height: 12),
                        _sectionTitle('Education', fontSize: 14),
                        pw.Text(
                          'Bachelor of Computer Science - Universitas Atma Jaya Yogyakarta (2020 - 2025)\n'
                          'GPA: 3.52 / 4.00\n\n'
                          'SMAN 8 Samarinda (2016 - 2020)',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  pw.Container(
                    width: 1,
                    height: 400,
                    margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                    color: PdfColors.grey400,
                  ),

                  // Right column
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Professional Summary & Highlights', fontSize: 14),
                        pw.Text(
                          'Driven developer with a strong commitment to delivering clean, maintainable, and scalable code. Proven track record in end-to-end project delivery across web and mobile platforms.',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Bullet(
                          text: 'Specializes in Kotlin and Laravel for high-performance applications.',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                        pw.Bullet(
                          text: 'Skilled at integrating front-end and back-end systems seamlessly.',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                        pw.Bullet(
                          text: 'Passionate about mentoring and knowledge sharing.',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                        pw.Bullet(
                          text: 'Adaptable to emerging technologies and agile workflows.',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                        pw.SizedBox(height: 12),

                        _sectionTitle('Certificates', fontSize: 14),
                        pw.Bullet(
                          text: 'Researcher Management and Leadership Training, 2024',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                        pw.Bullet(
                          text: 'EnglishScore, 2025',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // ========== PAGE 2 (Professional layout) ==========
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(14),
        build: (context) {
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // LEFT — Finished Projects
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _sectionHeaderPro('Finished Projects'),
                    pw.UrlLink(
                      destination: 'https://github.com/Windstrom5/Diet_Gamification',
                      child: _projectCard(
                        title: 'Diet Gamifikasi Android App',
                        year: '2025',
                        tags: ['Kotlin', 'Laravel', 'PostgreSQL'],
                        bullets: [
                          'Gamified fitness & diet tracker with streaks and challenges.',
                          'Authentication & API with Laravel; secure data flows.',
                          'Normalized PostgreSQL schema for analytics-friendly queries.',
                        ],
                      ),
                    ),

                    pw.UrlLink(
                      destination: 'https://github.com/Windstrom5/portofolio',
                      child: _projectCard(
                        title: 'Personal Portfolio Website',
                        year: '2025',
                        tags: ['Flutter Web', 'Animations', 'PDF Export'],
                        bullets: [
                          'Responsive multi-page portfolio with micro-interactions.',
                          'Built-in resume exporter to PDF using custom templates.',
                          'Modular content blocks for quick updates.',
                        ],
                      ),
                    ),

                    pw.UrlLink(
                      destination: 'https://github.com/Windstrom5/WorkHubs',
                      child: _projectCard(
                        title: 'Workhubs',
                        year: '2024',
                        tags: ['Android', 'QR Attendance', 'Kotlin', 'Laravel'],
                        bullets: [
                          'Employee activity tracking and daily attendance via QR.',
                          'Overtime & official duty logging with approvals.',
                          'REST backend (Laravel) with PostgreSQL; role-based access.',
                        ],
                      ),
                    ),

                    pw.UrlLink(
                      destination: 'https://github.com/Windstrom5/Go-Fit-android',
                      child: _projectCard(
                        title: 'Go-Fit Android App',
                        year: '2023 - 2024',
                        tags: ['Kotlin', 'Laravel', 'Vue.js'],
                        bullets: [
                          'Gym operations suite for members and instructors.',
                          'Schedule/class management with attendance tracking.',
                          'Web admin built with Vue.js for multi-instructor setups.',
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 8),
                    pw.UrlLink(
                      destination: 'https://github.com/Windstrom5',
                      child: pw.Text(
                        'See more on GitHub',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.blue,
                          decoration: pw.TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              pw.Container(
                width: 1,
                height: 800,
                margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                color: PdfColors.grey400,
              ),
              // RIGHT — Work In Progress
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _sectionHeaderPro('Work In Progress'),
                    _projectCard(
                      title: 'Karaoke App',
                      year: '2025 (WIP)',
                      tags: ['Ktor', 'Compose Multiplatform', 'AI', 'Python', 'Demucs', 'Whisper'],
                      bullets: [
                        'Real-time vocal/instrument separation via Python backend (Demucs, MoviePy, Torch).',
                        'AI-powered automatic lyrics generation with Whisper, transliteration, and translation tools.',
                        'Seamless multiplatform experience across devices.',
                      ],
                    ),
                  _projectCard(
                      title: 'Fatebound Quest',
                      year: '2025 (WIP)',
                      tags: ['UE5', 'Roguelike', 'RNG Training'],
                      bullets: [
                        'Tile & dice-based gameplay inspired by D&D mechanics.',
                        'RNG-driven training progression.',
                        'Built in Unreal Engine 5 with data-driven content.',
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ===== Helpers =====
  pw.Widget _sectionTitle(String title, {double fontSize = 20}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue600,
          letterSpacing: 1.1,
          decoration: pw.TextDecoration.underline,
        ),
      ),
    );
  }

  pw.Widget _sectionHeaderPro(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: .6,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(height: 1, color: PdfColors.grey400),
        ],
      ),
    );
  }

  pw.Widget _projectCard({
    required String title,
    required String year,
    required List<String> bullets,
    List<String>? tags,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Title + year
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
              pw.Text(
                year,
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
          if (tags != null && tags.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _chipRow(tags),
          ],
          pw.SizedBox(height: 6),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: bullets
                .map((b) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Bullet(text: b, style: pw.TextStyle(fontSize: 9, height: 1.2)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  pw.Widget _chipRow(List<String> tags) {
    return pw.Wrap(
      spacing: 4,
      runSpacing: 4,
      children: tags
          .map((t) => pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Text(
                  t,
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                ),
              ))
          .toList(),
    );
  }

  pw.Widget _personalDetailsTable({double fontSize = 12}) {
    return pw.Table(
      columnWidths: {
        0: const pw.FixedColumnWidth(130),
        1: const pw.FlexColumnWidth(),
      },
      border: pw.TableBorder.all(width: 0, color: PdfColor(0, 0, 0, 0)),
      children: [
        _tableRow('Date of Birth', 'November 20, 2002', fontSize),
        _tableRow('Address', 'Sleman, Yogyakarta', fontSize),
        _tableRow('Nationality', 'Indonesian', fontSize),
        _tableRow('Languages', 'English (Fluent), Bahasa Indonesia (Native)', fontSize),
      ],
    );
  }

  pw.TableRow _tableRow(String label, String value, double fontSize) {
    return pw.TableRow(children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
            fontSize: fontSize,
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(value, style: pw.TextStyle(fontSize: fontSize)),
      ),
    ]);
  }

  pw.Widget _skillsWrap(List<String> skills) {
    return pw.Wrap(
      spacing: 6,
      runSpacing: 4,
      children: skills
          .map(
            (skill) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 10),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue800,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Text(
                skill,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _jobItem({
    required String title,
    required String duration,
    required List<String> points,
    double fontSize = 12,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: fontSize + 2,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.Text(
          duration,
          style: pw.TextStyle(
            fontSize: fontSize - 2,
            fontStyle: pw.FontStyle.italic,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children:
              points.map((p) => pw.Bullet(text: p, style: pw.TextStyle(fontSize: fontSize))).toList(),
        ),
      ],
    );
  }

  Future<void> downloadPdfWeb(Uint8List pdfBytes, String filename) async {
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement()
      ..href = url
      ..style.display = 'none'
      ..download = filename;
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}
