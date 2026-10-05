// lib/core/services/pdf_service.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/care_models.dart';

abstract class PdfService {
  Future<String> generateScanReportPdf(dynamic scan);
  Future<String> generatePrescriptionPdf(PatientPrescription rx, UserProfile profile);
}

class RealPdfService implements PdfService {
  @override
  Future<String> generateScanReportPdf(dynamic scan) async {
    // Support both ScanResult object and plain scanId string
    final isModel = scan is! String;
    final scanId = isModel ? (scan.id as String) : scan as String;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final widgets = <pw.Widget>[
            pw.Header(
              level: 0,
              child: pw.Text('GlowAI - Skin Analysis Summary Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Report ID: $scanId'),
            pw.Text('Date: ${DateTime.now().toIso8601String().substring(0, 10)}'),
            pw.SizedBox(height: 20),
          ];

          if (isModel) {
            widgets.addAll([
              pw.Text('Skin Type: ${scan.skinType?.label ?? 'N/A'}'),
              pw.Text('Severity: ${scan.severity}'),
              pw.Text('Overall Score: ${scan.overallScore}/100'),
              if (scan.skinTone != null)
                pw.Text('Tone: ${scan.skinTone!.label} (${scan.skinTone!.undertone})'),
              pw.SizedBox(height: 16),
              pw.Text('Conditions', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              if (scan.conditions != null) ...[
                pw.Text('  Acne Index: ${scan.conditions!.acne.score}% (${scan.conditions!.acne.severity})'),
                pw.Text('  Dark Spots: ${scan.conditions!.darkSpots.score}% (${scan.conditions!.darkSpots.severity})'),
                pw.Text('  Redness: ${scan.conditions!.redness.score}% (${scan.conditions!.redness.severity})'),
                pw.Text('  Texture: ${scan.conditions!.texture.score}% (${scan.conditions!.texture.severity})'),
              ],
              pw.SizedBox(height: 16),
              if (scan.recommendedSpecialty.isNotEmpty)
                pw.Text('Recommended: ${scan.recommendedSpecialty}'),
              pw.SizedBox(height: 16),
              pw.Text('Insights', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              for (final insight in scan.insights) pw.Bullet(text: insight.toString()),
            ]);
          }

          widgets.addAll([
            pw.SizedBox(height: 20),
            pw.Text('General guidance only. Not a medical diagnosis. Consult a qualified dermatologist for clinical evaluation.'),
          ]);

          return widgets;
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/scan_report_$scanId.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  @override
  Future<String> generatePrescriptionPdf(PatientPrescription rx, UserProfile profile) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(rx.doctorName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text(rx.clinicName.isNotEmpty ? rx.clinicName : 'Dermatology & Skin Clinic', style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  pw.Text('GlowAI Digital Rx', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.pink700)),
                ],
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),

              // Patient Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Patient: ${profile.ageRange.isNotEmpty ? "Patient (${profile.ageRange})" : "Patient"}'),
                  pw.Text('Rx Date: ${rx.dateStr}'),
                ],
              ),
              if (rx.diagnosis.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text('Diagnosis / Notes: ${rx.diagnosis}', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
              ],

              pw.SizedBox(height: 16),
              pw.Text('Prescribed Medicines', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),

              // Medicine Table
              pw.TableHelper.fromTextArray(
                headers: ['Medicine Name', 'Form', 'Dose', 'Frequency', 'Duration', 'Instructions'],
                data: rx.medicines.map((m) {
                  return [
                    m.name,
                    m.form,
                    m.dose,
                    m.frequency,
                    '${m.durationDays} days',
                    m.instructions,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.pink800),
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                  5: pw.Alignment.centerLeft,
                },
              ),

              pw.SizedBox(height: 20),
              if (rx.followUpDateStr.isNotEmpty) ...[
                pw.Text('Follow-up Date: ${rx.followUpDateStr}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
              ],

              pw.Spacer(),
              pw.Divider(),
              pw.Text(
                'DISCLAIMER: This digital prescription record is maintained by the patient. Always follow your doctor\'s direct instructions and consult a certified dermatologist for any prescription queries.',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          );
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/prescription_${rx.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}

final pdfServiceProvider = Provider<PdfService>((ref) => RealPdfService());
