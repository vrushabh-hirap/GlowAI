import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';

class ScanConsentScreen extends StatelessWidget {
  const ScanConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Scan Consent & Privacy',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.privacy_tip_rounded,
                size: 32,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Privacy Belongs to You',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Before starting your AI face scan, please review how GlowAI processes your facial image data.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GlowCard(
              child: Column(
                children: const [
                  _ConsentPoint(
                    icon: Icons.shield_rounded,
                    title: 'On-Device & Secure Local Processing',
                    description: 'Your photo stays on your device and is only transmitted to your authorized local analysis server.',
                  ),
                  Divider(height: 24),
                  _ConsentPoint(
                    icon: Icons.cleaning_services_rounded,
                    title: 'Auto-Deletion After Analysis',
                    description: 'Images are erased from memory immediately after feature extraction.',
                  ),
                  Divider(height: 24),
                  _ConsentPoint(
                    icon: Icons.medical_information_rounded,
                    title: 'Informational Screening Only',
                    description: 'Results provide non-diagnostic insights and should be confirmed by a licensed doctor.',
                  ),
                ],
              ),
            ),
            const Spacer(),
            GlowButton(
              label: 'I Agree & Start Scan',
              width: double.infinity,
              onPressed: () => context.push('/scan/camera'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ConsentPoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ConsentPoint({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryDark, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
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
