# GlowAI – Smart Beauty, Healthy You (UI Shell Prototype)

GlowAI is a Flutter application providing AI-powered face and skin analysis, personalized skincare routines, makeup recommendations, and dermatologist consultation services.

---

## 📱 Modules & Entry Files

| Module | Location | Core Files & Entry | `TODO` Marker |
|---|---|---|---|
| **Auth** | `lib/features/auth/` | `splash_screen.dart`, `onboarding_screen.dart`, `login_register_screen.dart` | `// TODO(module: auth)` |
| **Home** | `lib/features/home/` | `patient_shell_screen.dart`, `patient_home_screen.dart` | `// TODO(module: home)` |
| **Scan** | `lib/features/scan/` | `scan_consent_screen.dart`, `scan_camera_screen.dart`, `scan_analyzing_screen.dart`, `scan_result_screen.dart` | `// TODO(module: scan)` |
| **AI Report** | `lib/features/report/` | `skin_health_report_screen.dart` | `// TODO(module: pdf)` |
| **Consultation** | `lib/features/consultation/` | `doctor_list_screen.dart`, `doctor_profile_screen.dart`, `book_appointment_screen.dart`, `my_appointments_screen.dart`, `chat_screen.dart`, `call_placeholder_screen.dart` | `// TODO(module: consultation)` |
| **Prescription** | `lib/features/prescription/` | `prescriptions_list_screen.dart`, `prescription_detail_screen.dart` | `// TODO(module: prescription)` |
| **Stores Map** | `lib/features/stores/` | `nearby_stores_screen.dart` | `// TODO(module: stores)` |
| **Skincare Routine**| `lib/features/skincare/` | `skincare_routine_screen.dart` | `// TODO(module: skincare)` |
| **Makeup Guide** | `lib/features/makeup/` | `makeup_recommendations_screen.dart` | `// TODO(module: makeup)` |
| **Shop Catalog** | `lib/features/shop/` | `shop_screen.dart` | `// TODO(module: shop)` |
| **Progress Tracker**| `lib/features/progress/` | `progress_tracker_screen.dart` | `// TODO(module: progress)` |
| **Notifications** | `lib/features/notifications/` | `notification_settings_screen.dart` | `// TODO(module: notifications)` |
| **Premium Plans** | `lib/features/premium/` | `premium_plans_screen.dart` | `// TODO(module: premium)` |
| **Profile / Settings**| `lib/features/profile/` | `profile_settings_screen.dart` | `// TODO(module: settings)` |
| **Doctor Mode** | `lib/features/doctor_mode/` | `doctor_shell_screen.dart`, `doctor_dashboard_screen.dart`, `doctor_appointment_detail_screen.dart`, `doctor_patient_report_screen.dart`, `doctor_prescription_form_screen.dart`, `doctor_prescription_preview_screen.dart` | `// TODO(module: doctor_mode)` |

---

## 🎨 Design System

- **Primary Color:** `#FF8FB8` (Light Glowing Pink)
- **Primary Dark:** `#F0609A`
- **Primary Soft:** `#FFE4EF`
- **Glow Shadow:** `#FF8FB8` at 35% opacity (blur: 24, spread: 2)
- **Background:** `#FFFBFD`
- **Typography:** Poppins (`google_fonts`)
- **Corner Radius:** Cards 20px, Buttons 16px (Pill shape)

---

## 🚀 How to Run

```bash
flutter pub get
flutter run
```
