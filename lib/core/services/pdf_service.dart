import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO(module: pdf) implement pdf package document generator and printing preview

abstract class PdfService {
  Future<String> generateScanReportPdf(String scanId);
  Future<String> generatePrescriptionPdf(String prescriptionId);
}

class FakePdfService implements PdfService {
  @override
  Future<String> generateScanReportPdf(String scanId) async {
    // TODO(module: pdf) build report PDF with image, scores, disclaimer
    await Future.delayed(const Duration(seconds: 1));
    return 'mock_pdf_path_scan_$scanId.pdf';
  }

  @override
  Future<String> generatePrescriptionPdf(String prescriptionId) async {
    // TODO(module: pdf) build prescription PDF with medicine table and images
    await Future.delayed(const Duration(seconds: 1));
    return 'mock_pdf_path_rx_$prescriptionId.pdf';
  }
}

final pdfServiceProvider = Provider<PdfService>((ref) => FakePdfService());
