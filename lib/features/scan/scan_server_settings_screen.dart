// lib/features/scan/scan_server_settings_screen.dart
// On-device analysis info screen — explains that all analysis runs locally on the device.
// No server needed. Replaces the old server settings screen.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/glow_card.dart';

class ScanServerSettingsScreen extends StatelessWidget {
  const ScanServerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'On-Device Analysis',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            GlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(CupertinoIcons.lock_shield_fill,
                            color: AppColors.primaryDark, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Completely Private',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Your photos never leave your phone',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'GlowAI performs all skin analysis directly on your device using computer vision algorithms. '
                    'No photo, no data, and no result is ever sent to any server.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // How it works
            GlowCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'How On-Device Analysis Works',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12),
                  _StepItem(
                    icon: CupertinoIcons.camera_fill,
                    title: '1. Capture',
                    description: 'Your front camera takes a high-resolution photo.',
                  ),
                  SizedBox(height: 10),
                  _StepItem(
                    icon: CupertinoIcons.person_crop_square_fill,
                    title: '2. Face Detection',
                    description: 'ML Kit detects your face landmarks directly on-chip (no internet required).',
                  ),
                  SizedBox(height: 10),
                  _StepItem(
                    icon: Icons.auto_awesome_rounded,
                    title: '3. Skin Analysis',
                    description:
                        'A computer vision pipeline measures skin tone, shine balance, '
                        'acne spots, redness, dark marks, and texture — all in a background thread.',
                  ),
                  SizedBox(height: 10),
                  _StepItem(
                    icon: CupertinoIcons.chart_bar_alt_fill,
                    title: '4. Results',
                    description:
                        'Results are stored only on your device in an encrypted local database. '
                        'You can delete them at any time from Settings → Delete All Scans.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Works offline badge
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.wifi_slash,
                      color: AppColors.textSecondary, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Works fully offline. No Wi-Fi or mobile data required for scanning or viewing results.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _StepItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryDark),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
