import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/mock/mock_data.dart';
import '../../core/services/appointment_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/chip_tag.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  final String doctorId;

  const BookAppointmentScreen({super.key, required this.doctorId});

  @override
  ConsumerState<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  String _selectedSlot = '10:30 AM';
  ConsultationMode _selectedMode = ConsultationMode.video;

  @override
  Widget build(BuildContext context) {
    final doctor = MockData.doctors.firstWhere(
      (d) => d.id == widget.doctorId,
      orElse: () => MockData.doctors.first,
    );

    return AppScaffold(
      title: 'Book Appointment',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Summary Header
            GlowCard(
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      doctor.name.split(' ').length >= 2
                          ? '${doctor.name.split(' ')[0][0]}${doctor.name.split(' ')[1][0]}'.toUpperCase()
                          : 'DR',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          doctor.specialty,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date Picker Calendar
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GlowCard(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 60)),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Time Slots
            const Text(
              'Select Time Slot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: doctor.slots.map((slot) {
                return ChipTag(
                  label: slot,
                  isSelected: _selectedSlot == slot,
                  onTap: () => setState(() => _selectedSlot = slot),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Consultation Mode Picker
            const Text(
              'Consultation Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ModeCard(
                    icon: Icons.video_call_rounded,
                    label: 'Video Call',
                    isSelected: _selectedMode == ConsultationMode.video,
                    onTap: () => setState(() => _selectedMode = ConsultationMode.video),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeCard(
                    icon: Icons.phone_rounded,
                    label: 'Voice Call',
                    isSelected: _selectedMode == ConsultationMode.voice,
                    onTap: () => setState(() => _selectedMode = ConsultationMode.voice),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeCard(
                    icon: Icons.chat_rounded,
                    label: 'Chat',
                    isSelected: _selectedMode == ConsultationMode.chat,
                    onTap: () => setState(() => _selectedMode = ConsultationMode.chat),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Confirm Booking Button
            GlowButton(
              label: 'Confirm Consultation Booking',
              width: double.infinity,
              onPressed: () {
                ref.read(appointmentProvider.notifier).book(
                      doctorId: doctor.id,
                      doctorName: doctor.name,
                      doctorSpecialty: doctor.specialty,
                      dateTime: _selectedDay,
                      timeSlot: _selectedSlot,
                      mode: _selectedMode,
                    );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Appointment booked with ${doctor.name}!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                context.push('/my-appointments');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16),
      backgroundColor: isSelected ? AppColors.primarySoft : AppColors.surface,
      border: Border.all(
        color: isSelected ? AppColors.primaryDark : AppColors.border,
        width: isSelected ? 1.5 : 1.0,
      ),
      child: Column(
        children: [
          Icon(icon, color: isSelected ? AppColors.primaryDark : AppColors.textSecondary),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
