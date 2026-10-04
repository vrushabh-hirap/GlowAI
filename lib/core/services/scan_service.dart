// lib/core/services/scan_service.dart
// DEPRECATED: FakeScanService and ScanResultModel have been removed.
// All scan logic now lives in:
//   - lib/core/services/scan_repository.dart (ScanRepository, real API upload + Hive storage)
//   - lib/models/scan_result_model.dart (ScanResult, all fields from real API)
//   - lib/core/services/prep_timer_service.dart (30-minute prep timer)
//
// This file is kept as a stub so old imports don't break until they're all migrated.
// DO NOT add mock or fake scan data here.

export '../services/scan_repository.dart';
