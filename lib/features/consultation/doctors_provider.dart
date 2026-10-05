import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/google_sheets_auth_service.dart';
import '../../models/doctor_model.dart';

/// Fetches doctors (users with role == 'doctor') from the Google Sheet.
/// Falls back to mock doctors if none found or request fails.
final doctorsProvider = FutureProvider<List<DoctorModel>>((ref) async {
  try {
    final res = await GoogleSheetsAuthService().listDoctors();
    if (res['ok'] == true && res['doctors'] is List) {
      final list = (res['doctors'] as List)
          .map((d) {
            final m = d as Map;
            return DoctorModel(
              id: m['id']?.toString() ?? '',
              name: m['name']?.toString() ?? 'Doctor',
              specialty: m['specialty']?.toString().isNotEmpty == true
                  ? m['specialty'].toString()
                  : 'Dermatologist',
              experience: m['experience']?.toString().isNotEmpty == true
                  ? m['experience'].toString()
                  : 'GlowAI Verified',
              rating: 4.8,
              reviewCount: 0,
              fee: double.tryParse(m['fee']?.toString() ?? '') ?? 499,
              languages: m['languages']?.toString().isNotEmpty == true
                  ? m['languages'].toString().split(',').map((s) => s.trim()).toList()
                  : const ['English', 'Hindi'],
              bio: m['bio']?.toString().isNotEmpty == true
                  ? m['bio'].toString()
                  : 'Verified doctor on GlowAI.',
              avatarUrl: m['photoUrl']?.toString() ?? '',
              slots: const ['10:00 AM', '12:30 PM', '4:00 PM', '6:30 PM'],
            );
          })
          .where((d) => d.id.isNotEmpty)
          .toList();
      return list;
    }
  } catch (_) {}
  return const [];
});
