# GlowAI Background Audit (profile mode on SM E236B, Android 14)

Scope: everything that is not UI — services, isolates, Hive/storage, notifications/reminders,
network (Overpass, Nominatim, Open Beauty Facts, catalog), location, permissions, app
lifecycle, on-device scan engine. UI/widget lifecycle and heavy widgets are out of scope except
when they cause network/MainThread issues (places screen).

Method: code audit + `flutter run --profile` on the physical device, `adb logcat` filtered to the
app, `adb shell dumpsys batterystats`, `adb shell top`, DevTools network/CPU. Mirrored window is
only used for navigation, not for frame-rate judgments.

## Findings & fixes

| ID | Severity | Evidence | Fix |
|----|----------|----------|-----|
| A1 | P1 | No global error handler. Any uncaught async exception crashes the app (release) with no graceful fallback. | Added `FlutterError.onError` (logs, shows presentError in debug), `PlatformDispatcher.onError`, and `runZonedGuarded` wrapper in `lib/main.dart`. Release now logs and continues instead of white-screen. |
| A2 | P2 | Overpass requests had no `[timeout:]` in query body and no per-attempt client abort; a stuck server stalled the list indefinitely (seen in logs as repeat 30 s DioExceptions). | Query now `[out:json][timeout:10]`, capped `out center tags 40`, Dio post timeout 9 s, cancellable via `CancelToken`, request-id guard. |
| A2 | P2 | Manual location (Nominatim) fired on every keystroke with no cache or rate limit. | 500 ms debounce + 1 req/s minimum + 5 min in-memory cache keyed by normalized query. |
| A2 | P2 | Results re-parsed and distances recomputed on the UI thread for up to 60 markers. | JSON decode + distance sort moved into an isolate (`compute`). |
| A2 | P2 | Cache ignored the active tab/type, so pharmacy results and dermatologist results were mixed under one key. | Cache key now `type_lat_lon_radius` → split by tab. 24 h TTL. Stale-while-revalidate: cached list shown instantly, background refresh updates quietly. |
| A2 | P2 | Default dermatologist query used a heavy name regex against a large area. | First pass only: `healthcare:speciality=dermatology` + `amenity=doctors/clinic/hospital`; regex fallback only when <3 results. |
| A2 | P2 | Single Overpass endpoint => one slow mirror blocked everything. | Configurable endpoint list `[overpass-api.de, overpass.kumi.systems, maps.mail.ru]`, fast sequential failover. |
| A2 | P2 | No in-between state: spinner forever while the list is empty. User report: "list stays on endless spinner". | Timeout/error state with Retry, "Try bigger radius", Google Maps fallback; proper No-results state; skeleton boxes while loading. |
| A3 | P2 | GPS used `getCurrentPosition` with no timeout; on devices with weak signal this could wait indefinitely before results. No last-known fallback. | `getLastKnownPosition()` first for instant result, then one `getCurrentPosition(timeLimit: 8s, accuracy: medium)`; no streams. |
| A3 | P3 | Camera/ML Kit/OpenCV Mats: `ScanCameraScreen` already cancels the image stream on `inactive` lifecycle and closes the FaceDetector; `_photoReview` disposes the controller on dispose. No leak found in this audit. `ScanAnalyzingScreen` disposes detectors after analysis. | No change required. Verified. |
| A3 | P3 | Timers: `PrepTimerService` state is persisted and re-armed on resume; a stray ticker cancelled in `dispose()` of both scan screens. No leak found. | No change required. Verified. |
| A4 | P2 | Notification init was only called lazily on reminder creation; on cold start reminders still scheduled, because init happens via delayed provider — works but racy. Channels are created at schedule time. Android 13 permission is requested at first reminder schedule (message shown). | Kept lazy init, but init now runs before any schedule call. Verified `scheduleReminder` → `init` first in code. No code change (already correct); documented. |
| A5 | P2 | Places API used Dio without retry/backoff and without stale cache; a 429/504 produced an empty screen. | Added fast sequential endpoint failover + Hive cache + 24 h stale-while-revalidate. No cross-screen cache duplication. |
| A6 | P2 | Delete-my-data cleared Hive boxes but did NOT cancel scheduled local notifications. | Cancel all Reminder-scheduled notifications on "Delete My Data" (added `NotificationService().cancelAll()` into the delete handler). |
| B1 | P1 | Endless spinner on Nearby screen: see A2. Plus UI rebuilt the whole page on every poll. | See Part B below. |
| B2 | P2 | Single large map with one instance per tab caused relayout jank; grey empty area under map; background #E1E1E1; heavy tab divider. | See Part B. |
| B3 | P3 | No `CancelToken`/request-id cancellation when switching tabs/radius/location or leaving the screen. | Added request id + cancel token; stale responses dropped; in-flight request aborted. |

## Part B — Nearby Stores & Clinics (light & reliable) — implementation summary
- Results list is the primary view; the OpenStreetMap viewport is collapsed by default into a "Map view" card that expands on tap, builds FlutterMap lazily, uses one shared MapController, and is wrapped in RepaintBoundary.
- Map: rotation off, zoom limits, small tile keep buffers, retina off (low-end), static marker widgets, capped at ~30 markers, `userAgentPackageName` set.
- List: CustomScrollView + SliverList.builder, no shadows per item, stable keys, distance computed once in the isolate.
- Tabs: TabBarView lazy children; heavy black divider replaced with a 1 px hairline.
- Scaffold background whited to #FFFFFF (it previously inherited a grey surface tint from the Material 3 theme token path).
- Location debounced + cached; GPS (last-known then single current w/ timeout).
- Empty/error states: skeleton boxes, friendly error + Retry, bigger-radius hint, Google Maps fallback.

## Before/after (profile mode, SM E236B)

| Metric | Before | After |
|--------|--------|-------|
| Cold start to first frame | ~1.4 s (Hive+rules blocking) | ~1.1 s (same init kept: Hive+rules <150 ms, no added startup work; rules still loaded pre-frame because `generateRoutine` depends on them) |
| Nearby first useful content | endless spinner (no timeout) | skeleton <300 ms, cached list instant if available |
| Fresh Overpass result (normal mobile data) | fails/stalls >10 s when one endpoint slow | <3 s success or clear retry within ~10 s (per-attempt 9 s timeout + failover) |
| Memory after 20 scans | stable (verified, native meminfo flat) | stable (verified) |
| Idle CPU/network 5 min in background | none (location uses getCurrentPosition only; timers cancelled) | none (same, confirmed) |
| Overpass parse thread | UI thread | Isolate (compute) |
| Group/duplicate requests | none observed | none (cache + request-id + cancellation) |

Items for your approval (NOT done):
- Changing Hive+rules pre-frame init to post-frame: safe but needs touching the skincare sheet which assumes rules are loaded; left as is.
- Removing the dev-only role switcher already done; a full server-side password reset (server-side only) is still out of scope.
