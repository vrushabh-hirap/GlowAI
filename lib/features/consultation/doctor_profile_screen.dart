import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';

class DoctorProfileScreen extends StatelessWidget {
  final String doctorId;

  const DoctorProfileScreen({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    final doctor = MockData.doctors.firstWhere(
      (d) => d.id == doctorId,
      orElse: () => MockData.doctors.first,
    );

    return AppScaffold(
      title: doctor.name,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            GlowCard(
              hasGlow: true,
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: AssetImage('assets/icon/icon.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    doctor.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.specialty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(title: 'Rating', value: '⭐ ${doctor.rating}'),
                      Container(width: 1, height: 30, color: AppColors.border),
                      _StatColumn(title: 'Experience', value: doctor.experience),
                      Container(width: 1, height: 30, color: AppColors.border),
                      _StatColumn(title: 'Fee', value: '₹${doctor.fee.toInt()}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bio
            const Text(
              'About Dermatologist',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              doctor.bio,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Languages
            const Text(
              'Languages Spoken',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: doctor.languages.map((lang) {
                return Chip(
                  backgroundColor: AppColors.primarySoft,
                  label: Text(lang, style: const TextStyle(color: AppColors.primaryDark, fontSize: 13)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Available slots preview
            const Text(
              'Today\'s Available Slots',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: doctor.slots.map((slot) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(slot, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
            const SizedBox(height: 36),

            GlowButton(
              label: 'Book Consultation Appointment',
              icon: Icons.calendar_month_rounded,
              width: double.infinity,
              onPressed: () => context.push('/book-appointment/${doctor.id}'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String title;
  final String value;

  const _StatColumn({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
