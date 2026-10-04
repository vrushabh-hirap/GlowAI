import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../models/doctor_model.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/chip_tag.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/soft_button.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  String _selectedSpecialty = 'All';

  final List<String> _specialties = const [
    'All',
    'Dermatologist',
    'Cosmetic',
    'Pediatric',
    'Trichologist',
  ];

  @override
  Widget build(BuildContext context) {
    final filteredDoctors = _selectedSpecialty == 'All'
        ? MockData.doctors
        : MockData.doctors
            .where((d) => d.specialty.toLowerCase().contains(_selectedSpecialty.toLowerCase()))
            .toList();

    return AppScaffold(
      title: 'Consult Dermatologists',
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded),
          onPressed: () => context.push('/my-appointments'),
        ),
      ],
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: _specialties.map((spec) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChipTag(
                    label: spec,
                    isSelected: _selectedSpecialty == spec,
                    onTap: () => setState(() => _selectedSpecialty = spec),
                  ),
                );
              }).toList(),
            ),
          ),

          // Doctor List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: filteredDoctors.length,
              itemBuilder: (context, index) {
                final doc = filteredDoctors[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _DoctorCard(doctor: doc),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorModel doctor;

  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      onTap: () => context.push('/doctor-profile/${doctor.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: AssetImage('assets/icon/icon.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doctor.specialty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${doctor.rating} (${doctor.reviewCount})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      doctor.experience,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${doctor.fee.toInt()} / session',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SoftButton(
                      label: 'Book Slot',
                      height: 36,
                      onPressed: () => context.push('/book-appointment/${doctor.id}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
