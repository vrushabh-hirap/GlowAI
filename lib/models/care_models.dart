// lib/models/care_models.dart
// Unified data models for Care & Beauty Hub.
// Plain Dart classes with toJson/fromJson for Hive JSON storage. No code generation.

/// User Safety & Preference Profile
class UserProfile {
  final String ageRange; // e.g. "18-24", "25-34", "35-44", "45+"
  final bool isSensitive;
  final List<String> allergies; // e.g. ["fragrance", "essential_oils", "parabens"]
  final bool isPregnantOrBreastfeeding;
  final String budgetPreference; // 'Budget', 'Mid', 'Premium', 'Any'
  final bool fragranceFreePreference;
  final String preferredRetailer; // 'Nykaa', 'Amazon', 'Flipkart', 'Purplle', 'Any'
  final String? manualSkinType; // Override skin type if scan is unclear

  const UserProfile({
    this.ageRange = '18-24',
    this.isSensitive = false,
    this.allergies = const [],
    this.isPregnantOrBreastfeeding = false,
    this.budgetPreference = 'Any',
    this.fragranceFreePreference = false,
    this.preferredRetailer = 'Any',
    this.manualSkinType,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        ageRange: j['ageRange'] as String? ?? '18-24',
        isSensitive: j['isSensitive'] as bool? ?? false,
        allergies: (j['allergies'] as List?)?.cast<String>() ?? const [],
        isPregnantOrBreastfeeding: j['isPregnantOrBreastfeeding'] as bool? ?? false,
        budgetPreference: j['budgetPreference'] as String? ?? 'Any',
        fragranceFreePreference: j['fragranceFreePreference'] as bool? ?? false,
        preferredRetailer: j['preferredRetailer'] as String? ?? 'Any',
        manualSkinType: j['manualSkinType'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'ageRange': ageRange,
        'isSensitive': isSensitive,
        'allergies': allergies,
        'isPregnantOrBreastfeeding': isPregnantOrBreastfeeding,
        'budgetPreference': budgetPreference,
        'fragranceFreePreference': fragranceFreePreference,
        'preferredRetailer': preferredRetailer,
        'manualSkinType': manualSkinType,
      };

  UserProfile copyWith({
    String? ageRange,
    bool? isSensitive,
    List<String>? allergies,
    bool? isPregnantOrBreastfeeding,
    String? budgetPreference,
    bool? fragranceFreePreference,
    String? preferredRetailer,
    String? manualSkinType,
  }) =>
      UserProfile(
        ageRange: ageRange ?? this.ageRange,
        isSensitive: isSensitive ?? this.isSensitive,
        allergies: allergies ?? this.allergies,
        isPregnantOrBreastfeeding:
            isPregnantOrBreastfeeding ?? this.isPregnantOrBreastfeeding,
        budgetPreference: budgetPreference ?? this.budgetPreference,
        fragranceFreePreference:
            fragranceFreePreference ?? this.fragranceFreePreference,
        preferredRetailer: preferredRetailer ?? this.preferredRetailer,
        manualSkinType: manualSkinType ?? this.manualSkinType,
      );
}

/// Routine Step Definition
class RoutineStep {
  final String id;
  final String title;
  final String category; // 'Cleanser', 'Toner', 'Serum', 'Moisturizer', 'Sunscreen', 'Night Treatment'
  final int stepNumber;
  final String session; // 'AM', 'PM', 'both'
  final bool isOptional;
  final String texture;
  final List<String> keyIngredients;
  final List<String> howToApply; // Numbered micro-steps
  final String whyItHelps;
  final String avoidNotes;
  final int waitTimeMinutes;
  final String productCategory;

  const RoutineStep({
    required this.id,
    required this.title,
    required this.category,
    required this.stepNumber,
    required this.session,
    this.isOptional = false,
    required this.texture,
    required this.keyIngredients,
    required this.howToApply,
    required this.whyItHelps,
    required this.avoidNotes,
    this.waitTimeMinutes = 1,
    required this.productCategory,
  });

  factory RoutineStep.fromJson(Map<String, dynamic> j) => RoutineStep(
        id: j['id'] as String,
        title: j['title'] as String,
        category: j['category'] as String,
        stepNumber: (j['stepNumber'] as num).toInt(),
        session: j['session'] as String,
        isOptional: j['isOptional'] as bool? ?? false,
        texture: j['texture'] as String,
        keyIngredients: (j['keyIngredients'] as List).cast<String>(),
        howToApply: (j['howToApply'] as List).cast<String>(),
        whyItHelps: j['whyItHelps'] as String,
        avoidNotes: j['avoidNotes'] as String,
        waitTimeMinutes: (j['waitTimeMinutes'] as num? ?? 1).toInt(),
        productCategory: j['productCategory'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'stepNumber': stepNumber,
        'session': session,
        'isOptional': isOptional,
        'texture': texture,
        'keyIngredients': keyIngredients,
        'howToApply': howToApply,
        'whyItHelps': whyItHelps,
        'avoidNotes': avoidNotes,
        'waitTimeMinutes': waitTimeMinutes,
        'productCategory': productCategory,
      };
}

/// Generated Routine Plan
class RoutinePlan {
  final String skinType;
  final List<String> concerns;
  final List<RoutineStep> amSteps;
  final List<RoutineStep> pmSteps;
  final List<String> weeklyExtras;
  final String sourceSummary;
  final String generatedAt;

  const RoutinePlan({
    required this.skinType,
    required this.concerns,
    required this.amSteps,
    required this.pmSteps,
    required this.weeklyExtras,
    required this.sourceSummary,
    required this.generatedAt,
  });

  factory RoutinePlan.fromJson(Map<String, dynamic> j) => RoutinePlan(
        skinType: j['skinType'] as String,
        concerns: (j['concerns'] as List).cast<String>(),
        amSteps: (j['amSteps'] as List)
            .map((e) => RoutineStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        pmSteps: (j['pmSteps'] as List)
            .map((e) => RoutineStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        weeklyExtras: (j['weeklyExtras'] as List).cast<String>(),
        sourceSummary: j['sourceSummary'] as String,
        generatedAt: j['generatedAt'] as String,
      );

  Map<String, dynamic> toJson() => {
        'skinType': skinType,
        'concerns': concerns,
        'amSteps': amSteps.map((e) => e.toJson()).toList(),
        'pmSteps': pmSteps.map((e) => e.toJson()).toList(),
        'weeklyExtras': weeklyExtras,
        'sourceSummary': sourceSummary,
        'generatedAt': generatedAt,
      };
}

/// Daily Routine Execution Log
class RoutineLog {
  final String dateStr; // 'YYYY-MM-DD'
  final String session; // 'AM' or 'PM'
  final List<String> completedStepIds;

  const RoutineLog({
    required this.dateStr,
    required this.session,
    required this.completedStepIds,
  });

  factory RoutineLog.fromJson(Map<String, dynamic> j) => RoutineLog(
        dateStr: j['dateStr'] as String,
        session: j['session'] as String,
        completedStepIds: (j['completedStepIds'] as List).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'dateStr': dateStr,
        'session': session,
        'completedStepIds': completedStepIds,
      };
}

/// Product Item in Catalog
class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String tier; // 'Budget', 'Mid', 'Premium'
  final int priceMinInr;
  final int priceMaxInr;
  final String priceCheckedAt;
  final String size;
  final List<String> keyIngredients;
  final List<String> suitableSkinTypes;
  final List<String> concerns;
  final List<String> avoidIf;
  final Map<String, dynamic> flags; // fragrance_free, non_comedogenic, spf, pa_rating, mineral_filter
  final List<String> shadeFamilies; // for makeup: depth bucket + undertone
  final String? barcode;
  final String? image;
  final List<String> retailers; // e.g. ["Nykaa", "Amazon", "Flipkart", "Purplle"]
  final bool verified;
  final String notes;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.tier,
    required this.priceMinInr,
    required this.priceMaxInr,
    required this.priceCheckedAt,
    required this.size,
    required this.keyIngredients,
    required this.suitableSkinTypes,
    required this.concerns,
    required this.avoidIf,
    required this.flags,
    this.shadeFamilies = const [],
    this.barcode,
    this.image,
    required this.retailers,
    this.verified = true,
    this.notes = '',
  });

  bool get fragranceFree => flags['fragrance_free'] == true;
  bool get nonComedogenic => flags['non_comedogenic'] == true;
  String get priceDisplay => priceMinInr == priceMaxInr ? '₹$priceMinInr' : '₹$priceMinInr – ₹$priceMaxInr';

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        name: j['name'] as String,
        brand: j['brand'] as String,
        category: j['category'] as String,
        tier: j['tier'] as String,
        priceMinInr: (j['price_min_inr'] as num).toInt(),
        priceMaxInr: (j['price_max_inr'] as num).toInt(),
        priceCheckedAt: j['price_checked_at'] as String? ?? '',
        size: j['size'] as String? ?? '',
        keyIngredients: (j['key_ingredients'] as List?)?.cast<String>() ?? [],
        suitableSkinTypes: (j['suitable_skin_types'] as List?)?.cast<String>() ?? [],
        concerns: (j['concerns'] as List?)?.cast<String>() ?? [],
        avoidIf: (j['avoid_if'] as List?)?.cast<String>() ?? [],
        flags: (j['flags'] as Map<String, dynamic>?) ?? {},
        shadeFamilies: (j['shade_families'] as List?)?.cast<String>() ?? [],
        barcode: j['barcode'] as String?,
        image: j['image'] as String?,
        retailers: (j['retailers'] as List?)?.cast<String>() ?? ['Amazon', 'Nykaa'],
        verified: j['verified'] as bool? ?? true,
        notes: j['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'category': category,
        'tier': tier,
        'price_min_inr': priceMinInr,
        'price_max_inr': priceMaxInr,
        'price_checked_at': priceCheckedAt,
        'size': size,
        'key_ingredients': keyIngredients,
        'suitable_skin_types': suitableSkinTypes,
        'concerns': concerns,
        'avoid_if': avoidIf,
        'flags': flags,
        'shade_families': shadeFamilies,
        'barcode': barcode,
        'image': image,
        'retailers': retailers,
        'verified': verified,
        'notes': notes,
      };
}

/// Prescription & Medicine Models
class MedicineItem {
  final String id;
  final String name;
  final String strength; // e.g. "500 mg", "0.05% w/w"
  final String form; // 'Tablet', 'Cream', 'Gel', 'Lotion', 'Syrup', 'Capsule'
  final String dose; // e.g. "1 tablet", "Thin layer"
  final String frequency; // e.g. "Twice daily at 08:00 & 20:00"
  final List<String> scheduledTimes; // ["08:00", "20:00"]
  final int durationDays;
  final String instructions; // e.g. "Apply after washing face"
  final String? imagePath;

  const MedicineItem({
    required this.id,
    required this.name,
    required this.strength,
    required this.form,
    required this.dose,
    required this.frequency,
    required this.scheduledTimes,
    required this.durationDays,
    required this.instructions,
    this.imagePath,
  });

  factory MedicineItem.fromJson(Map<String, dynamic> j) => MedicineItem(
        id: j['id'] as String,
        name: j['name'] as String,
        strength: j['strength'] as String? ?? '',
        form: j['form'] as String,
        dose: j['dose'] as String,
        frequency: j['frequency'] as String,
        scheduledTimes: (j['scheduledTimes'] as List?)?.cast<String>() ?? [],
        durationDays: (j['durationDays'] as num? ?? 7).toInt(),
        instructions: j['instructions'] as String? ?? '',
        imagePath: j['imagePath'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'strength': strength,
        'form': form,
        'dose': dose,
        'frequency': frequency,
        'scheduledTimes': scheduledTimes,
        'durationDays': durationDays,
        'instructions': instructions,
        'imagePath': imagePath,
      };
}

class PatientPrescription {
  final String id;
  final String doctorName;
  final String clinicName;
  final String dateStr;
  final String diagnosis;
  final String followUpDateStr;
  final List<String> attachmentPaths;
  final List<MedicineItem> medicines;
  final bool isActive;

  const PatientPrescription({
    required this.id,
    required this.doctorName,
    required this.clinicName,
    required this.dateStr,
    required this.diagnosis,
    required this.followUpDateStr,
    required this.attachmentPaths,
    required this.medicines,
    this.isActive = true,
  });

  factory PatientPrescription.fromJson(Map<String, dynamic> j) =>
      PatientPrescription(
        id: j['id'] as String,
        doctorName: j['doctorName'] as String,
        clinicName: j['clinicName'] as String? ?? '',
        dateStr: j['dateStr'] as String,
        diagnosis: j['diagnosis'] as String? ?? '',
        followUpDateStr: j['followUpDateStr'] as String? ?? '',
        attachmentPaths: (j['attachmentPaths'] as List?)?.cast<String>() ?? [],
        medicines: (j['medicines'] as List)
            .map((e) => MedicineItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        isActive: j['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'doctorName': doctorName,
        'clinicName': clinicName,
        'dateStr': dateStr,
        'diagnosis': diagnosis,
        'followUpDateStr': followUpDateStr,
        'attachmentPaths': attachmentPaths,
        'medicines': medicines.map((e) => e.toJson()).toList(),
        'isActive': isActive,
      };
}

/// Dose Log Entry
class DoseLog {
  final String prescriptionId;
  final String medicineId;
  final String scheduledTimeStr; // ISO or date string
  final String takenAtStr;
  final bool isTaken;

  const DoseLog({
    required this.prescriptionId,
    required this.medicineId,
    required this.scheduledTimeStr,
    required this.takenAtStr,
    required this.isTaken,
  });

  factory DoseLog.fromJson(Map<String, dynamic> j) => DoseLog(
        prescriptionId: j['prescriptionId'] as String,
        medicineId: j['medicineId'] as String,
        scheduledTimeStr: j['scheduledTimeStr'] as String,
        takenAtStr: j['takenAtStr'] as String,
        isTaken: j['isTaken'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'prescriptionId': prescriptionId,
        'medicineId': medicineId,
        'scheduledTimeStr': scheduledTimeStr,
        'takenAtStr': takenAtStr,
        'isTaken': isTaken,
      };
}

/// Reminder Entity
class AppReminder {
  final String id;
  final String title;
  final String body;
  final String type; // 'routine', 'medicine', 'rescan', 'sunscreen', 'appointment', 'custom'
  final String timeStr; // 'HH:mm'
  final List<int> repeatDays; // 1 = Monday .. 7 = Sunday
  final bool isEnabled;
  final String? linkedId; // e.g. prescriptionId or stepId

  const AppReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timeStr,
    required this.repeatDays,
    this.isEnabled = true,
    this.linkedId,
  });

  factory AppReminder.fromJson(Map<String, dynamic> j) => AppReminder(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        type: j['type'] as String,
        timeStr: j['timeStr'] as String,
        repeatDays: (j['repeatDays'] as List).cast<int>(),
        isEnabled: j['isEnabled'] as bool? ?? true,
        linkedId: j['linkedId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'timeStr': timeStr,
        'repeatDays': repeatDays,
        'isEnabled': isEnabled,
        'linkedId': linkedId,
      };

  AppReminder copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? timeStr,
    List<int>? repeatDays,
    bool? isEnabled,
    String? linkedId,
  }) =>
      AppReminder(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        type: type ?? this.type,
        timeStr: timeStr ?? this.timeStr,
        repeatDays: repeatDays ?? this.repeatDays,
        isEnabled: isEnabled ?? this.isEnabled,
        linkedId: linkedId ?? this.linkedId,
      );
}

/// Nearby Place Result
class PlaceResult {
  final String id;
  final String name;
  final String type; // 'pharmacy' or 'dermatologist'
  final String address;
  final double distanceKm;
  final double lat;
  final double lon;
  final String? phone;
  final bool is24Hours;
  final String? openHours;

  String get openingHours => openHours ?? '';

  const PlaceResult({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.distanceKm,
    required this.lat,
    required this.lon,
    this.phone,
    this.is24Hours = false,
    this.openHours,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> j) => PlaceResult(
        id: j['id'] as String,
        name: j['name'] as String,
        type: j['type'] as String,
        address: j['address'] as String,
        distanceKm: (j['distanceKm'] as num).toDouble(),
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        phone: j['phone'] as String?,
        is24Hours: j['is24Hours'] as bool? ?? false,
        openHours: j['openHours'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'address': address,
        'distanceKm': distanceKm,
        'lat': lat,
        'lon': lon,
        'phone': phone,
        'is24Hours': is24Hours,
        'openHours': openHours,
      };
}

/// Entitlement & Usage Limiter Models
class Entitlement {
  final bool isPremium;
  final String planName; // 'free', 'monthly', 'yearly'
  final String? activatedAt;

  const Entitlement({
    this.isPremium = false,
    this.planName = 'free',
    this.activatedAt,
  });

  factory Entitlement.fromJson(Map<String, dynamic> j) => Entitlement(
        isPremium: j['isPremium'] as bool? ?? false,
        planName: j['planName'] as String? ?? 'free',
        activatedAt: j['activatedAt'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'isPremium': isPremium,
        'planName': planName,
        'activatedAt': activatedAt,
      };
}

class UsageCounter {
  final int scanCountThisWeek;
  final String weekStartDateStr; // 'YYYY-MM-DD'

  const UsageCounter({
    required this.scanCountThisWeek,
    required this.weekStartDateStr,
  });

  factory UsageCounter.fromJson(Map<String, dynamic> j) => UsageCounter(
        scanCountThisWeek: (j['scanCountThisWeek'] as num? ?? 0).toInt(),
        weekStartDateStr: j['weekStartDateStr'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'scanCountThisWeek': scanCountThisWeek,
        'weekStartDateStr': weekStartDateStr,
      };
}
