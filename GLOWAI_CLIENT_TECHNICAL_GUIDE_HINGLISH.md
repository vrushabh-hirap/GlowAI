# GlowAI — Client Technical Walkthrough (Hinglish)

Yeh guide repo ke maujooda code ko dekh kar banayi gayi hai. Iska use client demo, technical discussion aur scope/payment conversation mein karo. “AI”, “doctor”, “secure”, “live”, “cloud” jaise shabdon ko tabhi use karo jab yahan di hui current implementation un claims ko support karti ho.

## 1. 30-second introduction

**Simple:** GlowAI ek Flutter based beauty aur skincare app prototype hai. User face photo leta hai, app us photo se kuch visual skin indicators estimate karta hai, phir rule-based skincare aur makeup suggestions dikhata hai. Report informational hai, medical diagnosis nahi.

**Technical:** Mobile UI Flutter/Dart mein hai. Navigation GoRouter, app state Riverpod, local structured storage Hive, aur lightweight preferences SharedPreferences use karte hain. Face detection Google ML Kit se hota hai; uske baad custom Dart computer-vision pipeline background isolate mein image quality, facial regions, colour/texture metrics aur heuristic scores nikalti hai. Project mein ek alag Python FastAPI reference backend bhi hai, lekin current mobile scan flow us backend ko call nahi karta.

## 2. Architecture ko client ko kaise samjhayen

```text
Flutter screens (lib/features)
        ↓ user actions / navigation
Riverpod providers + repositories/services
        ├── on-device scan: ML Kit → Dart CV pipeline
        ├── local records: Hive / app documents directory
        ├── bundled rules/catalog: assets/data/*.json
        ├── account & doctor directory: Google Apps Script endpoint
        └── nearby places: public OpenStreetMap/Overpass services

Separate reference backend:
Python FastAPI + OpenCV/MediaPipe style processing + API routers
(present in tools/reference_backend; not the active mobile scan transport)
```

**Analogy:** Flutter screens front desk hain; repository/service data lane ka kaam karta hai; local Hive phone ki filing cabinet hai. Scan ka main processing phone par hota hai. FastAPI ka code alag server-side route ka prototype/reference hai.

## 3. Project stack aur har technology ka role

| Technology | Is project mein role | Client-friendly explanation |
|---|---|---|
| Flutter / Dart | Android, iOS aur desktop/web targets ke liye UI/app code | Ek shared codebase se app screens banana |
| GoRouter | Screen routes aur patient/doctor shells | App ke screens ke beech navigation |
| Riverpod | State/providers; repositories ko screens tak dena | Screen par data update aur refresh karna |
| Google ML Kit Face Detection | Photo mein face, face boundary, contours/pose detect karna | Photo mein face sahi position mein hai ya nahi check karna |
| Custom Dart CV | Image normalization, CIELAB colour conversion, skin masks, detectors, score/insights | Image ke visual patterns se approximate indicators banana |
| Hive | On-device key-value/local records | Is device par app data save karna |
| SharedPreferences | Chhoti settings/session flags | Simple preferences rakhna |
| JSON assets | Routine/makeup rules aur product/store/doctor seed data | App ke saath bundle hue content/rules |
| Google Apps Script | Login/signup/doctor actions ke liye HTTP integration | Google-hosted script ke zariye kuch account data exchange |
| FastAPI / Python | Separate backend code for analyze/auth/doctor/appointment/prescription routes | Server-side implementation/reference, app scan flow se alag |
| OpenStreetMap / Overpass | Nearby place search / map tiles | Bahari map/place services se aas-paas ke results |
| `pdf` package | Local report/prescription PDF generation | Phone par PDF banana |

## 4. Launch se scan result tak: exact scan flow

1. User scan prep/consent screen par guidance dekhta hai.
2. Camera/gallery flow image leta hai; camera UI guidance aur image quality ke liye input deta hai.
3. `ScanRepository` (`lib/core/services/scan_repository.dart`) `InputImage.fromFile` banata hai aur ML Kit `FaceDetector` chalata hai.
4. Zero face ya multiple faces hon to scan rukta hai. ML Kit se bounding box, pose aur face contour points nikale jaate hain.
5. `SkinAnalyzer.analyze()` ko image path aur plain face geometry di jaati hai. Woh Flutter `compute()` se `_runPipeline` background isolate par chalata hai; UI thread ko block na karne ke liye.
6. Image decode/EXIF normalize aur resize hoti hai; RGB se CIELAB channels calculate hote hain.
7. Quality gate lighting, resolution/face size aur image metrics check karta hai. Quality weak ho to skin result ke bajay issues/unknown score aata hai.
8. Face landmarks se forehead/T-zone/cheeks/nose jaise regions bante hain; colour rules se non-skin pixels/highlights kam kiye jaate hain.
9. Detectors skin tone, skin type, redness, acne-like spots, dark spots aur texture/pigmentation metrics nikalte hain.
10. Scoring/insights heuristics se overall score, severity/risk aur suggested specialty banate hain. Overlay/region data report/result UI ko milta hai.
11. `ScanAnalyzingScreen` result ko `ScanRepository.saveLocally()` se local Hive `scans` box aur app documents folder mein image ke saath save karta hai; history/latest/delete yahin se hoti hai.

**Zaroori wording:** Yeh learned clinical AI/doctor nahi hai. Current mobile analyzer conventional image processing aur heuristic/classical CV hai. Lighting, camera, makeup, skin tone aur photo quality result ko badal sakte hain. Sirf “informational screening/visual estimate” bolo.

**Privacy wording:** Scan code ka current path photo ko analysis ke liye network par upload nahi karta. Original image aur scan record local app documents/Hive mein persist ho sakte hain, jab save call hoti hai. “Kahin store hi nahi hota” ya “fully secure” mat bolo; local storage hona security certification ka saboot nahi.

## 5. FastAPI backend: repo mein kya hai aur kya wired hai

`tools/reference_backend/app/main.py` mein `/health` aur `/analyze` endpoints hain. `/analyze` multipart image aur optional `minutes_since_wash`/`prepared` fields leta hai; file-size/type validate karta hai; image normalize, landmarks, quality gate, regions, detectors, scoring, insights aur overlay banata hai. Alag routers auth, doctors, appointments, prescriptions ke liye bhi hain.

**Client ko precise answer:** “Backend implementation repo mein maujood hai. Current Flutter scan service on-device analyzer call karti hai; app se is FastAPI `/analyze` endpoint tak active request wired nahi hai. Server deployment, production database, auth hardening aur mobile/backend contract integration alag kaam honge.”

Project ka `README.md`, project plan ya server settings UI backend ke irade ko describe kar sakta hai; actual current source-of-truth mobile scan flow `scan_repository.dart` hai. Demo mein README ke “AI server” description ko current behavior ke roop mein present mat karo.

## 6. Feature-by-feature: kya kaam karta hai aur data kahan se aata hai

### Scan, report, history, progress

- Scan pipeline on-device hai (upar flow dekho); no server call in active `ScanRepository` path.
- Result model `lib/models/scan_result_model.dart` mein parse/serialize hota hai.
- History `scans` Hive box mein; image file app documents directory mein.
- PDF report local `PdfService` se ban sakti hai; report mein explicitly “not a medical diagnosis” disclaimer hai.
- Progress screen saved scans/metrics ko compare karne ke liye app data use karti hai. Yeh clinical outcome validation nahi.

### Skincare routine aur makeup

- `RecommendationEngine` deterministic/rule-based hai, generative AI service nahi.
- `assets/data/routine_rules.json` aur `makeup_rules.json` load hote hain.
- Routine skin type, scan confidence/manual profile ke hisaab se select hoti hai; AM/PM steps aur profile flags ke kuch adjustments hain.
- Makeup shade mapping skin-tone level/undertone ko JSON mapping se match karti hai. Confidence kam ho to result low-confidence mark kiya jaata hai.
- Isliye bolo: “personalized, rules-based suggestions”; “AI ne medically verified routine likhi” mat bolo.

### Products/shop

- Product catalog app asset `assets/data/catalog.json` se load hota hai; optional cached catalog Hive se pehle read kiya jaata hai.
- Filters/search/sort/personalization local product metadata aur profile/scan fields par hote hain.
- Buy link Nykaa/Amazon/Flipkart/Purplle par search URL bana sakta hai; app mein apna checkout/payment ya live inventory confirm nahi hota.
- Prices/availability ko live retailer API se verify kiya gaya kehne se pehle alag check chahiye.

### Profile/care hub/routine logs/wishlist

- `HiveStorageService` 10 local boxes initialize karta hai, including profile, routine logs, wishlist, product cache, prescriptions, reminders, place cache, entitlement, usage.
- Care repositories profile save/load, daily routine completion/streak aur wishlist jaisi cheezein Hive par chalate hain.
- Yeh device-local persistence hai; user doosre phone par login kare to automatic cloud sync assume mat karo.

### Account/auth aur doctors

- `GoogleSheetsAuthService` `Dio` se hard-coded Google Apps Script URL par GET query parameters ke roop mein signup/login/reset/profile/listDoctors actions bhejta hai.
- Login UI ke `AuthNotifier` mein response success hone par local session/preferences aur in-memory state set hoti hai. `FakeAuthService` aur `MockData` fallback/current role defaults bhi code mein hain.
- Doctor list provider Google Sheet/Apps Script se list laane ki koshish karta hai; result na aaye/exception ho to `MockData.doctors` deta hai.
- Yeh conventional production backend/auth stack ka equivalent nahi. Password handling, transport/query exposure, Google Script access controls, doctor credential verification aur privacy configuration ko deploy se pehle audit karna hoga.
- Client se secret/key/security par sawaal aaye to guess na karo; bolo security review aur deployment configuration verify karke likhit jawab doge.

### Appointments, chat, video, doctor mode, prescriptions

- UI screens patient booking/appointments aur doctor mode/prescription forms provide karte hain.
- Current `AppointmentService` `FakeAppointmentService` hai: appointments in-memory `MockData.initialAppointments` se; TODO hai Hive persistence connect karna. App restart/cloud multi-user sync ke baad reliable record assume nahi.
- Consultation chat `MockData` se initial conversation dikhata hai; source mein live WebSocket ko TODO/comment kiya gaya hai. Yeh production real-time chat nahi.
- `call_placeholder_screen.dart` Jitsi room URL banata hai, lekin file TODO kehti hai actual `url_launcher` se connect karna. UI placeholder/flow hai; completed live consultation na kaho.
- Doctor/prescription UI aur PDF generation code maujood hai. `PrescriptionService` par Hive connect karne ka TODO hai; screen flow ka persistence/API/auth linkage feature-by-feature verify karna hoga.
- Doctor identity/medical licence verification, secure patient-provider relationship, telemedicine compliance aur production scheduling ko implemented maan kar promise mat karo.

### Notifications/reminders

- Notification plugin aur kuch scheduling code (`PrepTimerService`) project mein hai.
- `notification_settings_screen.dart` aur `reminder_service.dart` mein TODO markers ke mutabik settings/reminder wiring poori tarah connected nahi hai.
- Safe claim: reminder/notification screens aur partial local scheduling code maujood hain. Har reminder type har device/platform par reliably fire karta hai—yeh test/verification ke bina mat bolo.

### Nearby stores/maps

- Places repository Overpass/Nominatim jaise public services ke zariye nearby data la sakta hai, cache Hive mein ho sakta hai.
- UI OpenStreetMap tiles dikhati hai aur location permission/network/service par depend karti hai.
- Data completeness, availability aur response time third-party public services par depend karte hain; guaranteed store directory nahi.

### Premium plans

- Pricing/benefit strings aur free weekly limit config/UI mein defined hain (`PremiumConfig`, premium screen).
- Entitlement local Hive flags ke liye hai. App Store/Play billing ya payment verification wired hai, aisa repo se claim nahi karna chahiye.
- Safe claim: “premium UI/plan presentation prototype”; real subscription purchase/renewal/payment receipt validation separate integration.

## 7. Data flow aur storage summary

| Data | Current source/destination | Caveat |
|---|---|---|
| Scan photo | Camera/gallery → analysis → optional copy in app documents | Local; auto cloud backup/sync ka claim nahi |
| Scan metrics/history | `ScanResult` JSON → Hive `scans` | Device-local; delete implementation available |
| User profile/care progress/wishlist | Hive boxes | Device-local |
| Session preferences | SharedPreferences, plus in-memory service state | Auth/security posture production-grade kehne se pehle audit |
| Login/signup/doctor list | Google Apps Script URL via HTTP client | External integration; script/deployment controls verify karne hain |
| Catalog/rules | Bundled JSON assets; optional Hive catalog cache | Curated static data unless external source is configured |
| Nearby places/tiles | Public OpenStreetMap ecosystem | Network and third-party availability dependent |
| Appointment/chat | Primarily mock/in-memory in current service/UI | Multi-device/live backend flow complete nahi |
| Premium status | Local config/entitlement storage | Store payment/receipt verification nahi dikh rahi |

## 8. Client demo ka recommended narration

1. **Problem:** “Skin-care choices confusing ho sakti hain; app scan-based starting point aur organized care journey deti hai.”
2. **Scan:** Consent/prep → one-face capture → quality checks → on-device visual metrics → informational report. “Estimate” shabd use karo.
3. **Personalization:** “Scan aur profile fields ko fixed rules/catalog se map karke routine/shade suggestions dikhte hain.”
4. **Care journey:** Product, store, doctor, appointment aur prescription screens product concept dikhate hain; har flow ka backend completion alag status ke roop mein transparent rakho.
5. **Scope:** “Current demo mein [verified flows] hain. Production release ke liye agreed next phase mein [backend/auth, live appointments/chat, billing, privacy/security, QA, store release] ko integrate/validate karna hoga.”

Demo se pehle apne device par har screen khol kar dekho, account/network fallback verify karo, aur ek scan sample run karo. Repo docs/current code ke mismatch ki wajah se client ko feature status source code ke basis par batao.

## 9. Likely questions: seedhe, confident, sachche jawab

**“Kya yeh AI hai?”**  
“Current scan custom computer-vision heuristics use karta hai; yeh clinical trained diagnostic AI model nahi. Routine aur makeup matching rules-based hai.”

**“Result kitna accurate hai?”**  
“Abhi clinically validated accuracy number claim nahi karunga. Photo quality, light, pose aur skin tone se result affect ho sakta hai. Clinical validation/data study next requirement hogi.”

**“Kya yeh disease diagnose karta hai?”**  
“Nahi. Yeh visual indicators ka informational screening prototype hai; diagnosis doctor hi karega.”

**“Photo server par upload hoti hai?”**  
“Current mobile scan path local analysis karta hai aur scan history local device par store ho sakti hai. Repo mein separate FastAPI analysis backend bhi hai, lekin current scan flow usse call nahi karta.”

**“Kya data cloud mein sync hai?”**  
“Scan/care data ke liye current implementation local storage use karti hai. Account/doctor listing Google Apps Script integration use karti hai. Complete cross-device cloud sync implemented hai, aisa main claim nahi karunga.”

**“Doctors real/verified hain?”**  
“Doctor directory external Apps Script response ya mock fallback se aa sakti hai. Medical licence verification ko deploy configuration/code se confirm kiye bina verified claim nahi karunga.”

**“Appointment/chat/call abhi live hai?”**  
“Screens aur demo flow hain. Current appointment service in-memory mock hai, chat mein live WebSocket TODO hai, aur call screen placeholder hai. Production live consultation ke liye backend/provider integration chahiye.”

**“Payment/premium kaise charge hoga?”**  
“Abhi plan/pricing UI aur local entitlement logic hai. Store billing/receipt validation implementation ko alag se add/verify karna hoga.”

**“Kab production launch kar sakte hain?”**  
“Timeline final backend, privacy/security, doctor/telemedicine requirements, device QA aur store-review scope par depend karti hai. Main confirmed scope aur estimate dene ke baad date commit karunga.”

## 10. Jawab na pata ho to kaise handle karein

Sawaal dodge ya fake certainty mat do. Yeh line use karo:

> “Is point par main guess nahi karna chahta. Main current implementation/configuration verify karke [specific date/time] tak aapko confirmed written answer dunga.”

Phir sawaal note karo: exact expected behavior, affected user, deadline, acceptance criteria. Verify karke promised time par reply bhejo. Agar jawab is waqt repo mein nahi hai, bolo “yeh current build mein confirmed nahi hai” aur usko estimate/scope item banao.

## 11. Payment aur scope boundary

> “Abhi kaam agreed scope aur paid milestone tak hai. Yeh naya request current scope mein listed nahi hai. Main pehle effort, cost, timeline aur acceptance criteria likh kar share karunga; written approval aur agreed payment milestone ke baad implementation schedule karunga.”

Process:

1. Client request ko apne shabdon mein likh kar confirm karo.
2. Current agreement/proposal ke against check karo.
3. In-scope ho to current milestone ke acceptance criteria ke mutabik deliver karo.
4. Out-of-scope ho to estimate + milestone/payment terms bhejo; approval se pehle start/date promise nahi.
5. Demo ko delivered production service ke roop mein misrepresent mat karo; known blockers/limitations meeting notes mein likho.

## 12. Current gaps / risks jo scope mein saamne rakhne hain

- Scan CV output ke liye clinical benchmark/validation evidence repo mein nahi dikh raha.
- Active app scan on-device hai; separate FastAPI backend mobile scan se wired nahi.
- Auth/doctor listing Google Apps Script plus mock/in-memory pieces use karti hai; security review required.
- Appointment in-memory/mock; chat WebSocket TODO; call placeholder; prescription persistence TODO present.
- Premium UI/local entitlement ke saath store billing evidence nahi.
- Notification settings/reminder integration partial/TODO markers present.
- Local data ka automatic server backup/device sync nahi dikh raha.
- Product/store data third-party/static sources par dependent; availability guarantee nahi.
- Production launch ke liye privacy policy/data retention, consent, access control, verified clinicians, deployment monitoring, supported-device QA, release signing/store setup scope define karna hoga.

Yeh risks client se chhupane ke liye nahi, realistic next milestone/cost define karne ke liye hain.

## 13. Repo map: live discussion ke waqt files dhoondhne ke liye

| Area | Main files |
|---|---|
| App startup | `lib/main.dart`, `lib/app.dart` |
| Navigation | `lib/core/router/app_router.dart` |
| Scan orchestration | `lib/core/services/scan_repository.dart`, `lib/features/scan/scan_analyzing_screen.dart` |
| CV pipeline | `lib/core/analysis/skin_analyzer.dart`, `lib/core/analysis/detectors/*.dart`, `regions.dart`, `quality.dart`, `scoring.dart` |
| Result data model | `lib/models/scan_result_model.dart` |
| Local storage | `lib/core/services/hive_storage_service.dart`, `lib/core/repositories/care_repositories.dart` |
| Auth/Google script | `lib/core/services/auth_service.dart`, `google_sheets_auth_service.dart` |
| Doctors/appointments/chat | `lib/features/consultation/doctors_provider.dart`, `lib/core/services/appointment_service.dart`, `lib/features/consultation/chat_screen.dart` |
| Recommendation rules | `lib/core/recommendation/recommendation_engine.dart`, `assets/data/routine_rules.json`, `makeup_rules.json` |
| Product catalog | `lib/core/repositories/catalog_repository.dart`, `assets/data/catalog.json` |
| PDF | `lib/core/services/pdf_service.dart` |
| Separate server code | `tools/reference_backend/app/main.py`, routers and detector modules |
| Project overview/planned design | `README.md`, `GlowAI_Project_Plan.md` (compare with current source; docs may describe intended architecture) |

## 14. Final checklist before client call

- Ek real device/demo build par scan flow chala kar dekha.
- Network off/on karke Google Sheets/places fallbacks ka behavior samjha.
- Client ko “prototype / current build” aur “next production phase” ka farq bataya.
- Mock flows ko mock/placeholder hi label kiya.
- Current contract, paid milestone, included revisions aur change-request rate ready rakhe.
- Unknown questions ke liye follow-up date likhi; medical/security/payment claims verify kiye bina nahi kiye.
- Koi extra implementation shuru nahi ki jab tak written scope/payment agreement na ho.
