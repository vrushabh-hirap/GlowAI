# GlowAI Premium Architecture & Billing Integration Guide

## Current Architecture
GlowAI Premium uses an offline-first entitlement architecture managed by `EntitlementRepository` and `Entitlement` model.

### Storage
- State is persisted in Hive box `entitlement`.
- Scan usage is tracked per week in Hive box `usage`.

### Feature Limits Configuration (`lib/core/config/premium_config.dart`)
- **Free Tier:**
  - 3 AI skin scans per calendar week.
  - 30 days progress history.
  - Basic summary condition charts.
  - Standard skincare routine, makeup guide, shop catalog, wishlist, reminders, prescriptions, and nearby store search.
- **Premium Tier:**
  - Unlimited AI skin scans.
  - Full lifetime progress history.
  - Per-condition graphs (Acne, Redness, Pigmentation).
  - Before/after scan pair comparison.
  - High-resolution PDF Skin Health Report exports.

---

## Integrating Real In-App Purchases (Future Release)

When Google Play Console and Apple App Store Developer accounts are provisioned, follow these steps to plug in real billing:

### 1. Add `in_app_purchase` dependency
```yaml
dependencies:
  in_app_purchase: ^3.2.0
```

### 2. Implement `InAppPurchaseEntitlementRepository`
Replace `EntitlementRepository` in `lib/core/repositories/care_repositories.dart` with a production class that listens to `InAppPurchase.instance.purchaseStream`:

```dart
class InAppPurchaseEntitlementRepository implements IEntitlementRepository {
  final InAppPurchase _iap = InAppPurchase.instance;

  void initializeBilling() {
    _iap.purchaseStream.listen((purchaseDetailsList) {
      for (var purchaseDetails in purchaseDetailsList) {
        if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          _setPremiumFromStore(purchaseDetails);
        }
      }
    });
  }

  // ... implementation methods
}
```

### 3. Store Product Identifiers
- Monthly Subscription: `glowai_premium_monthly_199`
- Yearly Subscription: `glowai_premium_yearly_1499`

No changes to UI screens (`PremiumPlansScreen`, `ScanPrepScreen`, `ProgressTrackerScreen`) will be required as they interact strictly with `IEntitlementRepository`.
