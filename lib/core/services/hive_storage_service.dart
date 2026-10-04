// lib/core/services/hive_storage_service.dart
// Central manager for opening and accessing all 10 Hive boxes.

import 'package:hive_flutter/hive_flutter.dart';

class HiveStorageService {
  static bool _isInitialized = false;

  static const String boxProfile = 'profile';
  static const String boxRoutineLogs = 'routine_logs';
  static const String boxWishlist = 'wishlist';
  static const String boxProductCache = 'product_cache';
  static const String boxPrescriptions = 'prescriptions';
  static const String boxDoseLogs = 'dose_logs';
  static const String boxReminders = 'reminders';
  static const String boxPlaceCache = 'place_cache';
  static const String boxEntitlement = 'entitlement';
  static const String boxUsage = 'usage';

  static Future<void> init() async {
    if (_isInitialized) return;
    await Hive.initFlutter();

    await Future.wait([
      Hive.openBox<String>(boxProfile),
      Hive.openBox<String>(boxRoutineLogs),
      Hive.openBox<String>(boxWishlist),
      Hive.openBox<String>(boxProductCache),
      Hive.openBox<String>(boxPrescriptions),
      Hive.openBox<String>(boxDoseLogs),
      Hive.openBox<String>(boxReminders),
      Hive.openBox<String>(boxPlaceCache),
      Hive.openBox<String>(boxEntitlement),
      Hive.openBox<String>(boxUsage),
    ]);

    _isInitialized = true;
  }

  static Box<String> get profileBox => Hive.box<String>(boxProfile);
  static Box<String> get routineLogsBox => Hive.box<String>(boxRoutineLogs);
  static Box<String> get wishlistBox => Hive.box<String>(boxWishlist);
  static Box<String> get productCacheBox => Hive.box<String>(boxProductCache);
  static Box<String> get prescriptionsBox => Hive.box<String>(boxPrescriptions);
  static Box<String> get doseLogsBox => Hive.box<String>(boxDoseLogs);
  static Box<String> get remindersBox => Hive.box<String>(boxReminders);
  static Box<String> get placeCacheBox => Hive.box<String>(boxPlaceCache);
  static Box<String> get entitlementBox => Hive.box<String>(boxEntitlement);
  static Box<String> get usageBox => Hive.box<String>(boxUsage);

  /// Complete privacy data wipe ("Delete my data")
  static Future<void> clearAllUserData() async {
    await profileBox.clear();
    await routineLogsBox.clear();
    await wishlistBox.clear();
    await prescriptionsBox.clear();
    await doseLogsBox.clear();
    await remindersBox.clear();
    await usageBox.clear();
  }
}
