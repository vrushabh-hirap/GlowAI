// lib/core/repositories/care_repositories.dart
// Repositories for Care & Beauty Hub features with Riverpod providers.

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/care_models.dart';
import '../services/hive_storage_service.dart';

// ── Profile Repository ────────────────────────────────────────────────────────
abstract class IProfileRepository {
  Future<UserProfile> getProfile();
  Future<void> saveProfile(UserProfile profile);
}

class ProfileRepository implements IProfileRepository {
  static const String _key = 'user_profile';

  @override
  Future<UserProfile> getProfile() async {
    final raw = HiveStorageService.profileBox.get(_key);
    if (raw == null) return const UserProfile();
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const UserProfile();
    }
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await HiveStorageService.profileBox.put(_key, jsonEncode(profile.toJson()));
  }
}

final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  return ProfileRepository();
});

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier(ref.watch(profileRepositoryProvider));
});

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final IProfileRepository _repo;

  UserProfileNotifier(this._repo) : super(const UserProfile()) {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.getProfile();
  }

  Future<void> updateProfile(UserProfile profile) async {
    state = profile;
    await _repo.saveProfile(profile);
  }
}

// ── Routine Repository ────────────────────────────────────────────────────────
abstract class IRoutineRepository {
  Future<List<RoutineLog>> getLogsForDate(String dateStr);
  Future<void> saveLog(RoutineLog log);
  Future<int> getStreakDays();
}

class RoutineRepository implements IRoutineRepository {
  @override
  Future<List<RoutineLog>> getLogsForDate(String dateStr) async {
    final box = HiveStorageService.routineLogsBox;
    final logs = <RoutineLog>[];
    for (final key in box.keys) {
      if (key.toString().startsWith(dateStr)) {
        final raw = box.get(key);
        if (raw != null) {
          try {
            logs.add(RoutineLog.fromJson(jsonDecode(raw) as Map<String, dynamic>));
          } catch (_) {}
        }
      }
    }
    return logs;
  }

  @override
  Future<void> saveLog(RoutineLog log) async {
    final key = '${log.dateStr}_${log.session}';
    await HiveStorageService.routineLogsBox.put(key, jsonEncode(log.toJson()));
  }

  @override
  Future<int> getStreakDays() async {
    final box = HiveStorageService.routineLogsBox;
    if (box.isEmpty) return 0;
    
    // Count consecutive past days with at least one completed session
    int streak = 0;
    var current = DateTime.now();
    
    while (true) {
      final dateStr = current.toIso8601String().substring(0, 10);
      final amKey = '${dateStr}_AM';
      final pmKey = '${dateStr}_PM';
      
      final amRaw = box.get(amKey);
      final pmRaw = box.get(pmKey);
      
      bool hasActivity = false;
      if (amRaw != null) {
        final log = RoutineLog.fromJson(jsonDecode(amRaw));
        if (log.completedStepIds.isNotEmpty) hasActivity = true;
      }
      if (pmRaw != null) {
        final log = RoutineLog.fromJson(jsonDecode(pmRaw));
        if (log.completedStepIds.isNotEmpty) hasActivity = true;
      }
      
      if (hasActivity) {
        streak++;
        current = current.subtract(const Duration(days: 1));
      } else {
        // Allow current day to be incomplete
        if (dateStr == DateTime.now().toIso8601String().substring(0, 10)) {
          current = current.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
    }
    return streak;
  }
}

final routineRepositoryProvider = Provider<IRoutineRepository>((ref) {
  return RoutineRepository();
});

// ── Wishlist Repository ───────────────────────────────────────────────────────
abstract class IWishlistRepository {
  Future<List<String>> getWishlistProductIds();
  Future<void> addToWishlist(String productId);
  Future<void> removeFromWishlist(String productId);
  Future<bool> isWishlisted(String productId);
}

class WishlistRepository implements IWishlistRepository {
  @override
  Future<List<String>> getWishlistProductIds() async {
    return HiveStorageService.wishlistBox.values.toList();
  }

  @override
  Future<void> addToWishlist(String productId) async {
    await HiveStorageService.wishlistBox.put(productId, productId);
  }

  @override
  Future<void> removeFromWishlist(String productId) async {
    await HiveStorageService.wishlistBox.delete(productId);
  }

  @override
  Future<bool> isWishlisted(String productId) async {
    return HiveStorageService.wishlistBox.containsKey(productId);
  }
}

final wishlistRepositoryProvider = Provider<IWishlistRepository>((ref) {
  return WishlistRepository();
});

// ── Prescription Repository ───────────────────────────────────────────────────
abstract class IPrescriptionRepository {
  Future<List<PatientPrescription>> getAllPrescriptions();
  Future<PatientPrescription?> getPrescriptionById(String id);
  Future<void> savePrescription(PatientPrescription prescription);
  Future<void> deletePrescription(String id);
  Future<List<DoseLog>> getDoseLogs(String prescriptionId);
  Future<void> saveDoseLog(DoseLog log);
}

class PrescriptionRepository implements IPrescriptionRepository {
  @override
  Future<List<PatientPrescription>> getAllPrescriptions() async {
    final box = HiveStorageService.prescriptionsBox;
    final list = <PatientPrescription>[];
    for (final raw in box.values) {
      try {
        list.add(PatientPrescription.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {}
    }
    list.sort((a, b) => b.dateStr.compareTo(a.dateStr));
    return list;
  }

  @override
  Future<PatientPrescription?> getPrescriptionById(String id) async {
    final raw = HiveStorageService.prescriptionsBox.get(id);
    if (raw == null) return null;
    try {
      return PatientPrescription.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePrescription(PatientPrescription prescription) async {
    await HiveStorageService.prescriptionsBox.put(
      prescription.id,
      jsonEncode(prescription.toJson()),
    );
  }

  @override
  Future<void> deletePrescription(String id) async {
    await HiveStorageService.prescriptionsBox.delete(id);
  }

  @override
  Future<List<DoseLog>> getDoseLogs(String prescriptionId) async {
    final box = HiveStorageService.doseLogsBox;
    final list = <DoseLog>[];
    for (final raw in box.values) {
      try {
        final log = DoseLog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (log.prescriptionId == prescriptionId) list.add(log);
      } catch (_) {}
    }
    return list;
  }

  @override
  Future<void> saveDoseLog(DoseLog log) async {
    final key = '${log.prescriptionId}_${log.medicineId}_${log.scheduledTimeStr}';
    await HiveStorageService.doseLogsBox.put(key, jsonEncode(log.toJson()));
  }
}

final prescriptionRepositoryProvider = Provider<IPrescriptionRepository>((ref) {
  return PrescriptionRepository();
});

// ── Reminder Repository ───────────────────────────────────────────────────────
abstract class IReminderRepository {
  Future<List<AppReminder>> getAllReminders();
  Future<void> saveReminder(AppReminder reminder);
  Future<void> deleteReminder(String id);
  Future<void> toggleReminder(String id, bool enabled);
}

class ReminderRepository implements IReminderRepository {
  @override
  Future<List<AppReminder>> getAllReminders() async {
    final box = HiveStorageService.remindersBox;
    final list = <AppReminder>[];
    for (final raw in box.values) {
      try {
        list.add(AppReminder.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {}
    }
    return list;
  }

  @override
  Future<void> saveReminder(AppReminder reminder) async {
    await HiveStorageService.remindersBox.put(
      reminder.id,
      jsonEncode(reminder.toJson()),
    );
  }

  @override
  Future<void> deleteReminder(String id) async {
    await HiveStorageService.remindersBox.delete(id);
  }

  @override
  Future<void> toggleReminder(String id, bool enabled) async {
    final raw = HiveStorageService.remindersBox.get(id);
    if (raw != null) {
      final rem = AppReminder.fromJson(jsonDecode(raw)).copyWith(isEnabled: enabled);
      await saveReminder(rem);
    }
  }
}

final reminderRepositoryProvider = Provider<IReminderRepository>((ref) {
  return ReminderRepository();
});

// ── Entitlement Repository ────────────────────────────────────────────────────
abstract class IEntitlementRepository {
  Future<Entitlement> getEntitlement();
  Future<void> setPremium(bool isPremium, String planName);
  Future<UsageCounter> getUsageCounter();
  Future<void> incrementScanCount();
}

class EntitlementRepository implements IEntitlementRepository {
  static const String _entKey = 'entitlement_state';
  static const String _usageKey = 'usage_counter';

  @override
  Future<Entitlement> getEntitlement() async {
    final raw = HiveStorageService.entitlementBox.get(_entKey);
    if (raw == null) return const Entitlement();
    try {
      return Entitlement.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const Entitlement();
    }
  }

  @override
  Future<void> setPremium(bool isPremium, String planName) async {
    final ent = Entitlement(
      isPremium: isPremium,
      planName: planName,
      activatedAt: DateTime.now().toIso8601String(),
    );
    await HiveStorageService.entitlementBox.put(_entKey, jsonEncode(ent.toJson()));
  }

  @override
  Future<UsageCounter> getUsageCounter() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartStr = weekStart.toIso8601String().substring(0, 10);

    final raw = HiveStorageService.usageBox.get(_usageKey);
    if (raw == null) {
      return UsageCounter(scanCountThisWeek: 0, weekStartDateStr: weekStartStr);
    }
    try {
      final counter = UsageCounter.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (counter.weekStartDateStr != weekStartStr) {
        // Reset counter for new week
        final resetCounter = UsageCounter(scanCountThisWeek: 0, weekStartDateStr: weekStartStr);
        await HiveStorageService.usageBox.put(_usageKey, jsonEncode(resetCounter.toJson()));
        return resetCounter;
      }
      return counter;
    } catch (_) {
      return UsageCounter(scanCountThisWeek: 0, weekStartDateStr: weekStartStr);
    }
  }

  @override
  Future<void> incrementScanCount() async {
    final current = await getUsageCounter();
    final updated = UsageCounter(
      scanCountThisWeek: current.scanCountThisWeek + 1,
      weekStartDateStr: current.weekStartDateStr,
    );
    await HiveStorageService.usageBox.put(_usageKey, jsonEncode(updated.toJson()));
  }
}

final entitlementRepositoryProvider = Provider<IEntitlementRepository>((ref) {
  return EntitlementRepository();
});
