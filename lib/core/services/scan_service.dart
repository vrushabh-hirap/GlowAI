import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/scan_result_model.dart';
import '../mock/mock_data.dart';

// TODO(module: scan) connect to Python FastAPI backend at /analyze

abstract class ScanService {
  Future<ScanResultModel> analyzeFaceImage(String imagePath);
  ScanResultModel? get latestResult;
}

class FakeScanService implements ScanService {
  ScanResultModel _latest = MockData.sampleScanResult;

  @override
  ScanResultModel? get latestResult => _latest;

  @override
  Future<ScanResultModel> analyzeFaceImage(String imagePath) async {
    // TODO(module: scan) upload multipart image to http://10.0.2.2:8000/analyze
    await Future.delayed(const Duration(seconds: 2));
    _latest = ScanResultModel(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'usr_patient_1',
      timestamp: DateTime.now(),
      imagePath: imagePath.isNotEmpty ? imagePath : MockData.sampleScanResult.imagePath,
      skinType: 'Combination',
      skinToneLevel: 'Level 3 - Medium',
      undertone: 'Warm',
      toneHex: '#C68E6B',
      scores: const ConditionScores(
        acne: 36,
        pimples: 30,
        darkSpots: 22,
        pigmentation: 25,
        redness: 42,
      ),
      severity: 'Mild-Moderate',
      risk: 'Low-Medium',
      overallScore: 78,
      recommendedSpecialty: 'Dermatologist & Clinical Aesthetician',
      seeDoctor: true,
    );
    return _latest;
  }
}

final scanServiceProvider = Provider<ScanService>((ref) => FakeScanService());

class ScanResultNotifier extends StateNotifier<ScanResultModel> {
  final ScanService _service;
  ScanResultNotifier(this._service) : super(_service.latestResult ?? MockData.sampleScanResult);

  Future<void> runMockScan(String path) async {
    final result = await _service.analyzeFaceImage(path);
    state = result;
  }
}

final scanResultProvider = StateNotifierProvider<ScanResultNotifier, ScanResultModel>((ref) {
  final service = ref.watch(scanServiceProvider);
  return ScanResultNotifier(service);
});
