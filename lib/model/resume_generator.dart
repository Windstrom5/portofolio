import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;

class ResumePdf {
  final pw.Document pdf = pw.Document();

  Future<Uint8List> generate() async {
    final Uint8List photoBytes = await rootBundle.load('assets/myself.jpg').then((data) => data.buffer.asUint8List());
    final pw.MemoryImage photo = pw.MemoryImage(photoBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(10), // very small margin to fit all content
        build: (context) {
          return pw.Container(
            width: PdfPageFormat.a4.width - 20,
            height: PdfPageFormat.a4.height - 20,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header: smaller photo + name + contact info
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

                // Personal Details Table
                _sectionTitle('Personal Details', fontSize: 14),
                _personalDetailsTable(fontSize: 9),
                pw.SizedBox(height: 12),

                // Profile
                _sectionTitle('Profile', fontSize: 14),
                pw.Text(
                  'Enthusiastic and detail-oriented Full Stack Developer with strong foundations in modern web and mobile development. Recently graduated, I bring hands-on experience building responsive, user-friendly applications using technologies like Laravel, Kotlin, Java, and Vue.js. Passionate about clean architecture, scalable backend systems, and intuitive UIs. I\'m eager to grow in a collaborative and innovative environment.',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.black),
                ),
                pw.SizedBox(height: 12),

                // Skills
                _sectionTitle('Skills', fontSize: 14),
                _skillsWrap([
                  'Vue.js', 'Kotlin', 'Laravel', 'Java', 'PostgreSQL', 'MySQL',
                  'Android Studio', 'VS Code', 'CodeIgniter', 'Premiere Pro', 'Photoshop', 'NetBeans IDE',
                ]),
                pw.SizedBox(height: 12),

                // Professional Experience
                _sectionTitle('Professional Experience', fontSize: 14),
                _jobItem(
                  title: 'Software Programmer - PT. Kilang Pertamina Internasional RU VII Kasim',
                  duration: 'September 2023 - Januari 2024',
                  points: [
                    'Developed a mobile overtime tracking application using Kotlin (Android) for internal employee use.',
                    'Integrated a secure and scalable backend with Laravel and PostgreSQL to manage overtime submissions and approvals.',
                    'Collaborated with HR and IT teams to ensure accurate data handling and seamless user experience across departments.',
                  ],
                  fontSize: 9,
                ),
                pw.SizedBox(height: 8),
                _jobItem(
                  title: 'Volunteer Instructor - SDN Sendangsari (KKN Program)',
                  duration: 'July 2023',
                  points: [
                    'Conducted Microsoft Word and Excel training sessions for elementary school students over 2 Times.',
                    'Designed easy-to-understand materials tailored for young learners.',
                    'Supported students in developing basic computer literacy skills during community service (KKN).',
                  ],
                  fontSize: 9,
                ),
                pw.SizedBox(height: 12),

                // Education
                _sectionTitle('Education', fontSize: 14),
                pw.Text(
                  'Bachelor of Science in Informatics\nUniversitas Atma Jaya Yogyakarta (2020 - 2025)\n\n'
                  'Biological and Physical Sciences\nSMAN 8 Samarinda (2016 - 2020)',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.black),
                ),
                pw.SizedBox(height: 12),

                // Certificates
                _sectionTitle('Certificates', fontSize: 14),
                pw.Bullet(text: 'Researcher Management and Leadership Training, 2024', style: pw.TextStyle(fontSize: 9)),
                pw.Bullet(text: 'EnglishScore, 2025', style: pw.TextStyle(fontSize: 9)),
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
          decorationColor: PdfColors.blue600,
          decorationThickness: 1.8,
          decorationStyle: pw.TextDecorationStyle.solid,
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
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800, fontSize: fontSize),
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
              .map((p) => pw.Bullet(text: p, style: pw.TextStyle(fontSize: fontSize)))
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
