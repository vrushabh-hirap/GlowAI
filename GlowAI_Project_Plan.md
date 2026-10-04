# GlowAI – Smart Beauty, Healthy You
### AI-Powered Skin Analysis, Beauty Recommendations & Dermatologist Consultation App

**Stack:** Flutter (Dart) + Python (FastAPI + OpenCV + MediaPipe, later PyTorch/TensorFlow) + Hive (local storage)
**Cost:** 100% free tools and libraries.

> ⚠️ **Medical safety rule:** The AI only produces a *screening / informational report*. It must **never** claim a diagnosis. Prescriptions are created only by a real doctor (Doctor Mode). Show a disclaimer on every result, report and prescription: *"Informational screening only. Not a medical diagnosis."*

---

## 1. Project Overview

A user scans their face and receives:

1. Skin type, skin tone and skin condition analysis
2. An informational AI skin health report with severity and risk indicators
3. A personalized skincare routine and makeup recommendations
4. Consultation with a dermatologist (chat / voice / video)
5. A PDF prescription (medicine names + medicine images)
6. Reminders, progress tracking and a premium tier (local flag)

---

## 2. How It Works (Architecture)

| Need | Solution |
|---|---|
| Database | **Hive** (local NoSQL) + `shared_preferences` |
| Auth | Local auth: salted hash in Hive + `flutter_secure_storage` |
| Image storage | App documents folder (`path_provider`); only file paths in Hive |
| AI / face analysis | **Python + OpenCV + MediaPipe** (FastAPI), later a fine-tuned model |
| Notifications | `flutter_local_notifications` (on-device scheduling) |
| Voice/video call | **Jitsi Meet** public room link |
| Chat | Local storage + optional WebSocket on your FastAPI server (LAN) |
| Maps / stores | **OpenStreetMap** via `flutter_map` + local JSON of stores |
| Prescription sharing | Share sheet / `wa.me` link (`share_plus`, `url_launcher`) |
| Premium | Local flag in Hive |

```
┌───────────────────────── Flutter App ─────────────────────────┐
│ UI (screens) → Riverpod providers → Repositories              │
│                                  ├─ Hive (local DB)           │
│                                  ├─ File storage (images/PDF) │
│                                  ├─ Local notifications       │
│                                  └─ Dio → Python server       │
└───────────────────────────────────────┬───────────────────────┘
                                        │ HTTP (multipart/JSON)
                         ┌──────────────▼──────────────┐
                         │ FastAPI (Python, local)     │
                         │ OpenCV + MediaPipe + ML     │
                         │  /analyze  /ws/chat/{id}    │
                         └─────────────────────────────┘
```

### Where the Python code runs
Python cannot run inside a Flutter app, so run FastAPI on your laptop. Phone and laptop must be on the same Wi-Fi.

- Android emulator → `http://10.0.2.2:8000`
- Real phone → your PC's LAN IP, e.g. `http://192.168.1.5:8000`
- **Later upgrade:** export the model to **TFLite** and run it on-device with `tflite_flutter` (fully offline).

---

## 3. Feature List

### 3.1 Authentication
- Register (name, email/phone, password, age, gender, skin goals); login/logout; "remember me"
- Roles: **Patient** and **Doctor**
- Password stored as salted SHA-256 hash (never plain text)

### 3.2 AI Face Scan
- Camera or gallery; face-oval guidance overlay and lighting hint
- Image sent to the Python backend, JSON returned; image stored locally and linked to the scan record

### 3.3 Skin Type Detection
- Output: **Oily / Dry / Combination / Normal**
- Method: T-zone (forehead + nose) vs. cheek shine and texture comparison

### 3.4 Skin Tone Detection
- 6-step scale (Fair → Deep), undertone (Warm / Cool / Neutral), hex swatch
- Used later for foundation/lipstick shade matching

### 3.5 Skin Condition Analysis
- Informational detection of **Acne, Pimples, Dark spots, Pigmentation, Redness**
- Each has a score 0–100 and region highlights

### 3.6 AI Dermatologist Module
| Sub-feature | Implementation |
|---|---|
| Concern detection | Screening labels only ("possible acne-type concern") |
| Severity analysis | Mild / Moderate / Severe from scores |
| Risk assessment | Low / Medium / High + "see a doctor" trigger |
| Doctor recommendation | Match concern → specialty from local doctor list |
| AI skin health report | In-app screen + exportable PDF |

### 3.7 Consultation Services
- **Appointment booking:** pick doctor, date, time slot (stored locally, conflict check)
- **Online consultation:** chat (local + optional LAN WebSocket); voice/video via Jitsi room `https://meet.jit.si/GlowAI-<appointmentId>`
- **Doctor Mode:** appointments, patient scan reports, prescription writing
- **E-Prescription:** diagnosis note, medicines (name, dosage, frequency, duration, instructions, image), follow-up date
- **Prescription PDF** with medicine names and images
- **WhatsApp sharing** through the system share sheet
- **Nearby medical stores:** OpenStreetMap + local store list, call and directions buttons

### 3.8 Personalized Skincare Routine
- Morning and night routine from skin type + concerns
- Steps: Face wash → Toner → Serum → Moisturizer → Sunscreen → Night cream
- Ingredient suggestions (salicylic acid for oily/acne-prone, hyaluronic acid for dry)
- Routine reminders

### 3.9 AI Makeup Recommendation
- Foundation, concealer, blush, lipstick, eyeshadow, mascara, eyeliner, primer
- Shade chosen by skin tone + undertone (rule-based JSON lookup)
- Occasion guide: Wedding, Party, Office, College, Festival, Casual
- "Buy" button opens a product link in the browser (`url_launcher`)

### 3.10 Shop (Makeup + Hair Extensions)
- Local product catalog (JSON in assets with images), wishlist, "Buy" → external link

### 3.11 Notifications & Reminders
- Skincare routine, medicine, appointment, follow-up reminders

### 3.12 Progress Tracker & Skin Health Score
- Compare scans over time (before/after slider)
- Charts for acne / redness / pigmentation / overall score
- Optional lifestyle log (water, sleep)

### 3.13 Premium Services (local flag)
- Unlimited scans, advanced reports, priority consultation
- Free tier: e.g., 3 scans/week (counter in Hive); "Upgrade" toggles a local flag

---

## 4. Flutter Packages (all free)

Use `flutter pub add <name>` to get the latest compatible versions.

### Core / Architecture
| Package | Why |
|---|---|
| `flutter_riverpod` | State management |
| `go_router` | Navigation, role-based redirects |
| `uuid` | Unique IDs |
| `intl` | Date/time formatting |
| `equatable` | Model comparison |

### Local Storage
| Package | Why |
|---|---|
| `hive` + `hive_flutter` | Local NoSQL DB for users, scans, appointments, prescriptions, chats |
| `shared_preferences` | Small flags (onboarding, theme, scan counter) |
| `flutter_secure_storage` | Session token / user id |
| `crypto` | SHA-256 hashing (with random salt) |
| `path_provider`, `path` | App folder and path joining |

### Camera & Images
| Package | Why |
|---|---|
| `camera` | Live preview with face-oval overlay |
| `image_picker` | Gallery pick / quick capture |
| `image` | Resize/compress before upload |
| `google_mlkit_face_detection` | Optional on-device check that a face exists |
| `permission_handler` | Camera, notification, location permissions |

### Networking
| Package | Why |
|---|---|
| `dio` | Multipart upload, timeouts |
| `web_socket_channel` | Real-time chat |
| `connectivity_plus` | "Server unreachable" message |

### PDF & Sharing
| Package | Why |
|---|---|
| `pdf` | Build PDFs (text, tables, images) |
| `printing` | Preview, print, save |
| `share_plus` | Share to WhatsApp, email |
| `open_filex` | Open generated PDF |
| `signature` | Optional doctor signature pad |

### Consultation & Maps
| Package | Why |
|---|---|
| `url_launcher` | Jitsi links, WhatsApp, dialer, product links |
| `table_calendar` | Appointment date picker |
| `flutter_map` + `latlong2` | OpenStreetMap |
| `geolocator` | User location |

### Notifications
`flutter_local_notifications`, `timezone`, `flutter_timezone`

### UI & Charts
`fl_chart`, `google_fonts`, `flutter_svg`, `lottie`, `percent_indicator`, `shimmer`, `carousel_slider`

### Dev
`hive_generator`, `build_runner`, `flutter_lints`, `mocktail`

---

## 5. Flutter Project Structure (Feature-first)

```
glowai_app/
├─ pubspec.yaml
├─ assets/
│  ├─ data/
│  │  ├─ doctors.json
│  │  ├─ medicines.json        # name, use, image path
│  │  ├─ products.json         # makeup + skincare + hair extensions
│  │  ├─ stores.json           # medical stores (lat/lng)
│  │  └─ routines.json         # rule tables for routines/makeup
│  ├─ images/medicines/
│  ├─ images/products/
│  ├─ lottie/
│  └─ fonts/
└─ lib/
   ├─ main.dart
   ├─ app.dart
   ├─ core/
   │  ├─ theme/                # purple/teal/pink palette, text styles
   │  ├─ router/app_router.dart
   │  ├─ constants/            # api_config.dart, keys
   │  ├─ services/             # hive_service, notification_service, pdf_service, api_client
   │  └─ utils/                # validators, date helpers, hashing
   ├─ models/                  # user, scan_result, doctor, appointment,
   │                           # prescription, medicine, chat_message, product, reminder
   ├─ features/
   │  ├─ auth/  home/  scan/  report/  consultation/  doctor_mode/
   │  ├─ prescription/  stores/  skincare/  makeup/  shop/
   │  └─ progress/  notifications/  premium/
   └─ shared/widgets/
```

---

## 6. Local Database Design (Hive Boxes)

| Box | Key | Stores |
|---|---|---|
| `users` | userId | id, name, email, passwordHash, salt, role, age, gender, goals, isPremium |
| `scans` | scanId | userId, imagePath, date, skinType, tone, undertone, toneHex, scores {acne, pimples, darkSpots, pigmentation, redness}, severity, risk, overallScore |
| `doctors` | doctorId | name, specialty, experience, languages, fee (display only), slots, rating |
| `appointments` | appointmentId | patientId, doctorId, dateTime, mode, status, scanId, jitsiRoom |
| `chats` | appointmentId | messages (senderId, text, time, optional imagePath) |
| `prescriptions` | prescriptionId | appointmentId, doctorId, patientId, date, notes, followUpDate, medicines[] |
| `reminders` | reminderId | type, title, time, repeat, enabled, notificationId |
| `wishlist` | productId | saved products |
| `settings` | key | server URL, theme, scan counter |

**Medicine entry:** `{ name, dosage, frequency, durationDays, instructions, imageAsset }`

**Rules:** keep file paths (not image bytes) in Hive; register adapters with `hive_generator`; seed `doctors` from `assets/data/doctors.json` on first launch.

---

## 7. PDF Reports

### 7.1 AI Skin Health Report (patient)
GlowAI header, patient name/age/date, scan photo, skin type, tone swatch, condition score bars, severity, risk, suggested routine, **disclaimer**.

### 7.2 Prescription PDF (doctor → patient)
1. Header: GlowAI + doctor name, specialty, registration no.
2. Patient details
3. Doctor's notes / diagnosis
4. **Medicine table:** Image | Name | Dosage | Frequency | Duration | Instructions
5. Follow-up date
6. Optional signature and date
7. Footer disclaimer

### 7.3 Code sketch (`pdf_service.dart`)
```dart
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

Future<File> buildPrescriptionPdf(Prescription rx, Patient patient, Doctor doc) async {
  final pdf = pw.Document();

  final images = <String, pw.MemoryImage>{};
  for (final m in rx.medicines) {
    final bytes = (await rootBundle.load(m.imageAsset)).buffer.asUint8List();
    images[m.name] = pw.MemoryImage(bytes);
  }

  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    build: (ctx) => [
      pw.Text('GlowAI – Prescription', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
      pw.Text('Dr. ${doc.name} (${doc.specialty})'),
      pw.Divider(),
      pw.Text('Patient: ${patient.name}, ${patient.age}'),
      pw.SizedBox(height: 8),
      pw.Text('Notes: ${rx.notes}'),
      pw.SizedBox(height: 12),
      pw.Table(
        border: pw.TableBorder.all(),
        columnWidths: {0: const pw.FixedColumnWidth(60)},
        children: [
          pw.TableRow(children: ['Image','Medicine','Dosage','Frequency','Duration']
              .map((h) => pw.Padding(padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)))).toList()),
          for (final m in rx.medicines)
            pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(4),
                  child: pw.Image(images[m.name]!, height: 48, width: 48)),
              pw.Text(m.name), pw.Text(m.dosage), pw.Text(m.frequency), pw.Text('${m.durationDays} days'),
            ]),
        ],
      ),
      pw.SizedBox(height: 16),
      pw.Text('Follow-up: ${rx.followUpDate}'),
      pw.SizedBox(height: 20),
      pw.Text('This is a clinician-issued prescription via GlowAI. AI reports are informational only.',
          style: const pw.TextStyle(fontSize: 9)),
    ],
  ));

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/prescription_${rx.id}.pdf');
  return file.writeAsBytes(await pdf.save());
}
```
**Share to WhatsApp:**
```dart
await Share.shareXFiles([XFile(file.path)], text: 'Your GlowAI prescription');
```

### 7.4 Medicine images
- Store in `assets/images/medicines/` (your own photos or royalty-free images)
- Doctor picks medicines from `medicines.json` (autocomplete) so each has its image automatically
- Declare folders under `flutter: assets:` in `pubspec.yaml`

---

## 8. Consultation Flow

```
Patient: Scan → Report → "Consult a Doctor" (suggested specialty)
   → Choose doctor → Choose date/time + mode (Chat/Voice/Video)
   → Appointment saved (status: booked) → reminder scheduled

At time:
   Chat        → Chat screen (local DB; optional WebSocket for 2-device chat)
   Voice/Video → "Join" opens https://meet.jit.si/GlowAI-<appointmentId>
                 (doctor opens the same link from Doctor Mode)

Doctor Mode:
   Appointments → open patient's AI report → consult
   → "Write Prescription" (medicines from catalog, with images)
   → Save → PDF generated → patient sees it in "My Prescriptions"
   → Share to WhatsApp / Download / Print
   → Medicine reminders auto-created
   → "Nearby Medical Stores" suggestion
```

| Scenario | How |
|---|---|
| **Single-device demo** | Log in as Patient, book; switch to Doctor account, write prescription. Works fully offline. |
| **Two real phones** | Both connect to your FastAPI server on the same Wi-Fi; the server relays chat over WebSocket. |
| **Voice/Video** | Jitsi public room; anyone with the link joins. |

Doctors in the app are **demo doctors** unless you onboard real, licensed dermatologists. Do not present fake credentials as real.

---

## 9. Python Backend (FastAPI)

### 9.1 Install
```bash
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install fastapi "uvicorn[standard]" python-multipart opencv-python mediapipe numpy scikit-learn pillow
```
(Add `ultralytics`, `torch`, `timm` or `tensorflow` in Version 2, see Section 10.)

### 9.2 Folder structure
```
glowai_backend/
├─ main.py            # FastAPI app, routes
├─ analyzer.py        # face + skin analysis logic
├─ regions.py         # MediaPipe landmarks → face regions
├─ rules.py           # severity / risk / specialty rules
├─ chat.py            # optional WebSocket chat relay
└─ requirements.txt
```

### 9.3 Packages
| Package | Why |
|---|---|
| `fastapi` + `uvicorn` | REST API and WebSocket server |
| `python-multipart` | Receive uploaded images |
| `opencv-python` | Color spaces, blur, blob detection |
| `mediapipe` | Face detection + 468-point FaceMesh |
| `numpy` | Pixel math |
| `scikit-learn` | KMeans for dominant skin color; optional classifiers |
| `pillow` | Image decoding / EXIF rotation fix |

### 9.4 API contract
**`POST /analyze`** (multipart: `image`)
```json
{
  "face_detected": true,
  "skin_type": "Combination",
  "skin_tone": { "level": 3, "label": "Medium", "undertone": "Warm", "hex": "#C68E6B" },
  "conditions": { "acne": 42, "pimples": 35, "dark_spots": 20, "pigmentation": 28, "redness": 51 },
  "severity": "Moderate",
  "risk": "Medium",
  "overall_score": 68,
  "recommended_specialty": "Dermatologist",
  "see_doctor": true,
  "disclaimer": "Informational screening only. Not a medical diagnosis."
}
```
Also: `GET /health` (connection test) and `WS /ws/chat/{appointment_id}` (optional).

> This contract stays **fixed** across all versions, so the AI can be upgraded without changing the Flutter app.

### 9.5 How each detection works (Version 1: classical CV)

1. **Face detection & regions:** MediaPipe FaceMesh landmarks → masks for forehead, nose, left cheek, right cheek, chin. No face → `face_detected: false`.
2. **Skin mask:** keep pixels inside the face mask within a YCrCb/HSV skin range; exclude eyes, lips, brows.
3. **Skin tone:** KMeans (k=3) on cheek skin pixels, pick dominant → LAB → map L to levels 1–6; undertone from `a*` vs `b*` (warm: higher b*; cool: higher a* with lower b*).
4. **Skin type:** HSV ratio of bright + low-saturation (shine) pixels in T-zone vs cheeks, plus texture (Laplacian variance).
   - High shine everywhere → Oily
   - High T-zone shine, normal cheeks → Combination
   - Low shine + rough texture → Dry
   - Otherwise → Normal
5. **Redness:** mean `a*` (LAB) relative to the person's own baseline skin.
6. **Acne/pimples:** threshold small red blobs on `a*`, morphological open, `cv2.SimpleBlobDetector` or contour area → count and total area → score.
7. **Dark spots/pigmentation:** `L` channel minus heavy Gaussian blur; locally darker areas → spots; broad darker patches → pigmentation.
8. **Severity / risk (`rules.py`):** `severity = max(acne, redness)`: <35 Mild, 35–65 Moderate, >65 Severe. Risk = High if severe or if the concern persists across scans.
9. **Doctor recommendation:** rules map concern → specialty (acne → Dermatologist, pigmentation → Dermatologist/Cosmetologist, etc.).

### 9.6 Minimal `main.py`
```python
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import numpy as np, cv2
from analyzer import analyze_face

app = FastAPI(title="GlowAI API")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/analyze")
async def analyze(image: UploadFile = File(...)):
    data = np.frombuffer(await image.read(), np.uint8)
    img = cv2.imdecode(data, cv2.IMREAD_COLOR)
    if img is None:
        return {"face_detected": False, "error": "Invalid image"}
    return analyze_face(img)
```
Run (reachable from the phone):
```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

---

## 10. AI Upgrade Path (Pre-built Libraries, Models, Datasets)

### 10.1 Three versions

| Version | What | Effort |
|---|---|---|
| **V1** | Classical CV for skin type, tone, redness; blob counting for acne. The whole app is built around this. | A few days |
| **V2** | Replace acne/pigmentation scoring with a fine-tuned model behind the same `/analyze` contract. | 1–2 weeks |
| **V3 (optional)** | Export to TFLite and run on-device with `tflite_flutter` (fully offline). | Optional |

Classical CV works well for **tone, type and redness**. It is weak for acne, dark spots and pigmentation because lighting changes the results a lot. That is where a trained model helps.

### 10.2 Ready-made libraries / models

| Need | Option |
|---|---|
| Image classifier | TensorFlow/Keras or PyTorch with `timm`; fine-tune **MobileNetV3 / EfficientNet-B0** from ImageNet weights |
| Acne lesion detection | **Ultralytics YOLO** (`pip install ultralytics`) fine-tuned on an acne dataset |
| Better skin masking | Face-parsing models (BiSeNet) or MediaPipe face segmentation |
| On-device inference | **TFLite** + `tflite_flutter` |
| Pretrained skin models | Search Hugging Face for skin/acne classifiers; check license and training data first |

### 10.3 Datasets (free; check each license and skin-tone diversity)
- **ACNE04**: acne severity grading on face photos (best match for the face scan)
- **SCIN, Fitzpatrick17k, DDI**: diverse skin tones, clinical (non-dermoscopic) photos
- **DermNet**: broader skin conditions
- **Kaggle** skin-type datasets (oily / dry / normal)
- **HAM10000 / ISIC**: dermoscopic close-ups. Useful for literature and background, but **do not train the face-scan model on them**: they look very different from phone selfies and will not transfer well.

### 10.4 Training tips
- Collect/label images only with consent
- Test across lighting conditions and all skin tones
- Report accuracy per skin tone, not just overall
- Ask users for natural, even light at scan time

---

## 11. Flutter ↔ Python Integration

`api_client.dart`:
```dart
final dio = Dio(BaseOptions(
  baseUrl: serverUrl, // from settings; default http://10.0.2.2:8000
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 30),
));

Future<ScanResult> analyze(File imageFile) async {
  final form = FormData.fromMap({
    'image': await MultipartFile.fromFile(imageFile.path, filename: 'face.jpg'),
  });
  final res = await dio.post('/analyze', data: form);
  return ScanResult.fromJson(res.data);
}
```
**Notes**
- Add a **Server URL** field in Settings so you can change the IP without rebuilding
- Android HTTP on LAN: add `android:usesCleartextTraffic="true"` in `AndroidManifest.xml` (dev only)
- Compress the image to ~1024px before upload (`image` package)
- If the server is unreachable, show a friendly retry message

---

## 12. Screens List

1. Splash + Onboarding
2. Login / Register (+ role)
3. Home dashboard (skin score, quick actions, today's routine, upcoming appointment)
4. Face Scan (camera with oval guide) → Analyzing animation
5. Scan Result (type, tone, conditions, severity, risk)
6. AI Skin Health Report (+ Export PDF)
7. Doctor list → Doctor profile → Book appointment
8. My Appointments → Chat / Join Voice / Join Video
9. Prescriptions list → Detail (medicine images) → PDF / Share
10. Nearby Medical Stores (map)
11. Skincare Routine (AM/PM) + reminder settings
12. Makeup Recommendation + Occasion guide
13. Shop (makeup, skincare, hair extensions) + wishlist
14. Progress tracker (charts + before/after)
15. Notification settings
16. Premium plans (local flag)
17. Profile / Settings (server URL, theme, logout, delete my data)
18. **Doctor Mode:** dashboard, appointment detail, patient report, prescription form

---

## 13. Build Order (Milestones)

| Phase | Goal | Done when |
|---|---|---|
| 1 | Project setup, theme, router, Hive init | App launches with navigation |
| 2 | Local auth (patient + doctor roles) | Register/login/logout works offline |
| 3 | Python backend `/analyze` (V1 classical CV) | `curl` with a selfie returns JSON |
| 4 | Camera + upload + result screen | Scan shows real results |
| 5 | Report screen + PDF export | PDF opens/shares |
| 6 | Skincare routine + makeup engine (JSON rules) | Recommendations match skin type/tone |
| 7 | Doctors, booking, appointments | Booking persists after restart |
| 8 | Chat + Jitsi call launcher | Join link opens meeting |
| 9 | Doctor Mode + prescription PDF with medicine images | PDF has names + images |
| 10 | WhatsApp share + nearby stores map | Share sheet and map work |
| 11 | Notifications / reminders | Scheduled alerts fire |
| 12 | Progress tracker + charts | Multi-scan comparison |
| 13 | Premium flag, polish, testing | Demo-ready |
| 14 | **AI upgrade (V2):** fine-tuned acne/pigmentation model | Better scores, same API contract |

---

## 14. Setup Commands

```bash
# Flutter
flutter create glowai_app && cd glowai_app
flutter pub add flutter_riverpod go_router uuid intl equatable \
  hive hive_flutter shared_preferences flutter_secure_storage crypto path_provider path \
  camera image_picker image google_mlkit_face_detection permission_handler \
  dio web_socket_channel connectivity_plus \
  pdf printing share_plus open_filex signature \
  url_launcher table_calendar flutter_map latlong2 geolocator \
  flutter_local_notifications timezone flutter_timezone \
  fl_chart google_fonts flutter_svg lottie percent_indicator shimmer carousel_slider
flutter pub add --dev hive_generator build_runner mocktail
dart run build_runner build --delete-conflicting-outputs
```

**Android permissions** (`AndroidManifest.xml`): `CAMERA`, `INTERNET`, `POST_NOTIFICATIONS`, `ACCESS_FINE_LOCATION`, `SCHEDULE_EXACT_ALARM`; set `minSdkVersion 21+` (camera/mlkit may need 21–24).

**iOS** (`Info.plist`): `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSLocationWhenInUseUsageDescription`.

---

## 15. Privacy, Safety & Legal Notes

- Face photos are sensitive: keep them **on device**; send only to your own local server and delete from the server after analysis
- Consent screen before the first scan, and a "Delete all my data" option
- Disclaimer on result, report and prescription screens
- The AI must not suggest prescription drugs. Only a doctor adds prescription medicines; the AI may suggest over-the-counter *skincare ingredients*
- If ever launched publicly: real doctor verification, telemedicine rules (e.g., India's Telemedicine Practice Guidelines) and data-protection law (e.g., DPDP Act) apply. For a college/portfolio project, label the app as a **prototype**

---

## 16. Limitations (Be Upfront)

- Local storage means data lives on one phone; reinstalling erases it (add Export/Import backup as JSON)
- Real multi-user consultation needs a server; the free route is your own local FastAPI server
- Classical-CV skin analysis is approximate and depends on lighting and image quality
- Jitsi public rooms are not private by default; use a hard-to-guess room name (appointment UUID)

---

## 17. Reference Papers (IEEE)

**Most relevant to this project**
- *Detection and classification of acne lesions in acne patients: A mobile application*: https://ieeexplore.ieee.org/document/7535331 — compares segmentation methods such as k-means and HSV, close to the OpenCV approach in the Python backend.
- *Deep Learning for Skin Disease Diagnosis with End-to-End Data Security*: https://ieeexplore.ieee.org/document/10421188/ — secure sharing of diagnostic data among healthcare professionals; useful for prescription and report sharing.
- *Skin Disease Identification and Skincare Solutions Using Deep Learning Approach* (base paper): https://ieeexplore.ieee.org/document/10859493/

**Additional background**
- Skin Disease Detection using Deep Learning: https://ieeexplore.ieee.org/document/10047465/
- A Novel Predictive Analysis of Skin Disease Diagnosis Using Optimized Deep Learning Techniques: https://ieeexplore.ieee.org/document/11080776/
- Deep learning based skin cancer diagnosis: https://ieeexplore.ieee.org/document/7960452/
- A Skin Disease Detection using various methods of Deep Learning, a Comprehensive Approach: https://ieeexplore.ieee.org/document/10391783/
- Skin Disease Diagnosis System Using Machine and Deep Learning Algorithms: https://ieeexplore.ieee.org/document/10990791/
- An Efficient Approach for Skin Disease Detection using Deep Learning: https://ieeexplore.ieee.org/document/9718427/
- An effective classification of Skin Disease using Deep Learning Techniques: https://ieeexplore.ieee.org/document/10048840
- Machine learning methods for binary and multiclass classification of melanoma thickness from dermoscopic images (IEEE TMI, 2016): https://doi.org/10.1109/TMI.2015.2506270

> Note: many of these papers use dermoscopic datasets (HAM10000 / ISIC). Use them as literature background; for the face-scan model prefer face-photo datasets (Section 10.3).

---

## 18. Suggested Start

Begin with **Phase 3 (Python `analyzer.py`)** so you can test real results on selfies immediately, then **Phase 1 + 2** (project setup, theme, Hive, local auth), then continue in order.
