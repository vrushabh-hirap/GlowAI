// lib/core/config/premium_config.dart

class PremiumConfig {
  static const int freeWeeklyScanLimit = 3;
  static const int freeProgressHistoryDays = 30;

  static const String monthlyPlanPrice = '₹199 / month';
  static const String yearlyPlanPrice = '₹1,499 / year (Save 37%)';

  static const List<String> premiumBenefits = [
    'Unlimited AI skin scans every week',
    'Full lifetime progress history & charts',
    'Per-condition tracking (Acne, Redness, Pigmentation)',
    'Before & After comparison for any scan pair',
    'Export high-res PDF Skin Health Summary Reports',
    'Priority dermatologist booking matching',
  ];
}
