import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_register_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/care/care_hub_screen.dart';
import '../../features/consultation/book_appointment_screen.dart';
import '../../features/consultation/call_placeholder_screen.dart';
import '../../features/consultation/chat_screen.dart';
import '../../features/consultation/doctor_list_screen.dart';
import '../../features/consultation/doctor_profile_screen.dart';
import '../../features/consultation/my_appointments_screen.dart';
import '../../features/doctor_mode/doctor_appointment_detail_screen.dart';
import '../../features/doctor_mode/doctor_dashboard_screen.dart';
import '../../features/doctor_mode/doctor_patient_report_screen.dart';
import '../../features/doctor_mode/doctor_prescription_form_screen.dart';
import '../../features/doctor_mode/doctor_prescription_preview_screen.dart';
import '../../features/doctor_mode/doctor_shell_screen.dart';
import '../../features/home/patient_home_screen.dart';
import '../../features/home/patient_shell_screen.dart';
import '../../features/makeup/makeup_recommendations_screen.dart';
import '../../features/notifications/notification_settings_screen.dart';
import '../../features/premium/premium_plans_screen.dart';
import '../../features/prescription/prescription_detail_screen.dart';
import '../../features/prescription/prescriptions_list_screen.dart';
import '../../features/profile/profile_settings_screen.dart';
import '../../features/progress/progress_tracker_screen.dart';
import '../../features/report/skin_health_report_screen.dart';
import '../../features/scan/scan_analyzing_screen.dart';
import '../../features/scan/scan_camera_screen.dart';
import '../../features/scan/scan_consent_screen.dart';
import '../../features/scan/scan_result_screen.dart';
import '../../features/shop/shop_screen.dart';
import '../../features/skincare/skincare_routine_screen.dart';
import '../../features/stores/nearby_stores_screen.dart';
import 'page_transitions.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // Auth Routes
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: const LoginRegisterScreen(),
      ),
    ),

    // Patient Shell Routes
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return PatientShellScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/patient/home',
              builder: (context, state) => const PatientHomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/patient/scan',
              builder: (context, state) => const ScanConsentScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/patient/consult',
              builder: (context, state) => const DoctorListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/patient/care',
              builder: (context, state) => const CareHubScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/patient/profile',
              builder: (context, state) => const ProfileSettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Doctor Shell Routes
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return DoctorShellScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/doctor/dashboard',
              builder: (context, state) => const DoctorDashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/doctor/appointments',
              builder: (context, state) => const MyAppointmentsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/doctor/patients',
              builder: (context, state) => const DoctorDashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/doctor/profile',
              builder: (context, state) => const ProfileSettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Standalone Fullscreen Feature Routes
    GoRoute(
      path: '/scan/consent',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: const ScanConsentScreen(),
      ),
    ),
    GoRoute(
      path: '/scan/camera',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: const ScanCameraScreen(),
      ),
    ),
    GoRoute(
      path: '/scan/analyzing',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: const ScanAnalyzingScreen(),
      ),
    ),
    GoRoute(
      path: '/scan/result',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: const ScanResultScreen(),
      ),
    ),
    GoRoute(
      path: '/report',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: const SkinHealthReportScreen(),
      ),
    ),
    GoRoute(
      path: '/doctor-profile/:id',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: DoctorProfileScreen(doctorId: state.pathParameters['id'] ?? 'doc_1'),
      ),
    ),
    GoRoute(
      path: '/book-appointment/:id',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: BookAppointmentScreen(doctorId: state.pathParameters['id'] ?? 'doc_1'),
      ),
    ),
    GoRoute(
      path: '/my-appointments',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: const MyAppointmentsScreen(),
      ),
    ),
    GoRoute(
      path: '/chat/:id',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: ChatScreen(appointmentId: state.pathParameters['id'] ?? 'app_1'),
      ),
    ),
    GoRoute(
      path: '/call/:id',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: CallPlaceholderScreen(appointmentId: state.pathParameters['id'] ?? 'app_1'),
      ),
    ),
    GoRoute(
      path: '/prescriptions',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: const PrescriptionsListScreen(),
      ),
    ),
    GoRoute(
      path: '/prescription/:id',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: PrescriptionDetailScreen(prescriptionId: state.pathParameters['id'] ?? 'rx_501'),
      ),
    ),
    GoRoute(
      path: '/stores',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: const NearbyStoresScreen(),
      ),
    ),
    GoRoute(
      path: '/routine',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: const SkincareRoutineScreen(),
      ),
    ),
    GoRoute(
      path: '/makeup',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: const MakeupRecommendationsScreen(),
      ),
    ),
    GoRoute(
      path: '/shop',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: const ShopScreen(),
      ),
    ),
    GoRoute(
      path: '/progress',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: const ProgressTrackerScreen(),
      ),
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: const NotificationSettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/premium',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: const PremiumPlansScreen(),
      ),
    ),
    GoRoute(
      path: '/doctor/appointment/:id',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: DoctorAppointmentDetailScreen(appointmentId: state.pathParameters['id'] ?? 'app_1'),
      ),
    ),
    GoRoute(
      path: '/doctor/patient-report/:scanId',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: DoctorPatientReportScreen(scanId: state.pathParameters['scanId'] ?? 'scan_101'),
      ),
    ),
    GoRoute(
      path: '/doctor/prescription-form/:id',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: DoctorPrescriptionFormScreen(appointmentId: state.pathParameters['id'] ?? 'app_1'),
      ),
    ),
    GoRoute(
      path: '/doctor/prescription-preview',
      pageBuilder: (context, state) => buildFadeSlideTransition(
        context: context,
        state: state,
        child: const DoctorPrescriptionPreviewScreen(),
      ),
    ),
  ],
);
