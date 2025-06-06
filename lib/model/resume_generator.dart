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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(10),
        build: (context) {
          return pw.Container(
            child: pw.Column(
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
                        border:
                            pw.Border.all(color: PdfColors.blue800, width: 2),
                        borderRadius: pw.BorderRadius.circular(40),
                      ),
                      child: pw.ClipOval(
                        child: pw.Image(photo, fit: pw.BoxFit.cover),
                      ),
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
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey800,
                              height: 1.2,
                            ),
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
                    'Enthusiastic and detail-oriented Full Stack Developer with strong foundations in modern web and mobile development. ',
                  style: pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 12),

                _sectionTitle('Skills', fontSize: 14),
                _skillsWrap([
                  'Vue.js',
                  'Kotlin',
                  'Laravel',
                  'Java',
                  'PostgreSQL',
                  'MySQL',
                  'Android Studio',
                  'VS Code',
                  'CodeIgniter',
                  'Premiere Pro',
                  'Photoshop',
                  'NetBeans IDE',
                ]),
                pw.SizedBox(height: 12),

                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Professional Experience',
                              fontSize: 14),
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
                            title:
                                'Volunteer Instructor - SDN Sendangsari (KKN Program)',
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
                            'Bachelor of Computer Science - Universitas Atma Jaya Yogyakarta (2020 - 2025)\nGPA: 3.59 / 4.00\n\nSMAN 8 Samarinda (2016 - 2020)',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                          pw.SizedBox(height: 12),
                          _sectionTitle('Certificates', fontSize: 14),
                          pw.Bullet(
                              text:
                                  'Researcher Management and Leadership Training, 2024',
                              style: pw.TextStyle(fontSize: 9)),
                          pw.Bullet(
                              text: 'EnglishScore, 2025',
                              style: pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                    pw.Container(
                      width: 1,
                      height: 400,
                      margin: pw.EdgeInsets.symmetric(horizontal: 10),
                      color: PdfColors.grey400,
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Projects', fontSize: 14),
                          _jobItem(
                            title: 'Diet Gamifikasi Android App',
                            duration: '2024',
                            points: [
                              'Gamified fitness & diet tracker in Kotlin.',
                              'Use Laravel for backend/auth.',
                              'Use Postgree As Server.',
                            ],
                            fontSize: 9,
                          ),
                          pw.SizedBox(height: 8),
                          _jobItem(
                            title: 'Personal Portfolio Website',
                            duration: '2024',
                            points: [
                              'Built with Flutter Web.',
                              'Animated UI with resume PDF export.',
                              'Includes project & education showcase.',
                            ],
                            fontSize: 9,
                          ),
                          pw.SizedBox(height: 8),
                          _jobItem(
                            title: 'Workhubs',
                            duration: '2024',
                            points: [
                              'Android app to track employee activities and manage company data.',
                              'Supports QR-based attendance system for daily presence.',
                              'Includes overtime and official duty logging features.',
                              'Enables company and employee data management in one platform.',
                              'Built with Kotlin (Android) and Laravel + PostgreSQL (Backend).',
                            ],
                            fontSize: 9,
                          ),
                          pw.SizedBox(height: 8),
                          _jobItem(
                            title: 'Go-Fit Android App',
                            duration: '2023 - 2024',
                            points: [
                              'Gym operational management app for instructors and member.',
                              'Tracks daily gym activities and attendance.',
                              'Supports multiple instructors and class management.',
                              'Built with Kotlin (Android) and Laravel + Vue.Js (Web Version).',
                            ],
                            fontSize: 9,
                          ),
                          pw.SizedBox(height: 8),
                          pw.UrlLink(
                            destination: 'https://github.com/Windstrom5',
                            child: pw.Text('See more on GitHub',
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.blue,
                                    decoration: pw.TextDecoration.underline)),
                          ),
                          pw.SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

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
        _tableRow('Languages', 'English (Fluent), Bahasa Indonesia (Native)',
            fontSize),
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
              fontSize: fontSize),
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
      children: skills.map((skill) {
        return pw.Container(
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
        );
      }).toList(),
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
          children: points
              .map((p) =>
                  pw.Bullet(text: p, style: pw.TextStyle(fontSize: fontSize)))
              .toList(),
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
