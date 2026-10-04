// lib/features/reminders/reminders_screen.dart
// Module 7: Real Reminders & Notifications screen.
// Grouped by type with toggles, time picker, repeat days, test notification, and system permission banner.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/care_repositories.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/care_models.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _systemPermissionGranted = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await _notificationService.areNotificationsEnabled();
    if (mounted) {
      setState(() => _systemPermissionGranted = granted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminderRepo = ref.watch(reminderRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Reminders & Notifications',
        subtitle: 'Routine, Medicine & Scan Alerts',
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.plus_circle_fill, color: AppColors.primary),
            tooltip: 'Add Reminder',
            onPressed: () => _showAddEditSheet(context),
          ),
        ],
      ),
      body: FutureBuilder<List<AppReminder>>(
        future: reminderRepo.getAllReminders(),
        builder: (context, snapshot) {
          final reminders = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // System Permission Card
                if (!_systemPermissionGranted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.bell_slash_fill, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Notifications are disabled in system settings. Turn them on to receive timely alerts.',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textPrimary),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final ok = await _notificationService.requestPermissions();
                            setState(() => _systemPermissionGranted = ok);
                          },
                          child: const Text('Enable', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),

                // Quick Action: Test Notification
                GlowCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Test Notification', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('Fires a sample alert in 5 seconds', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(CupertinoIcons.paperplane_fill, size: 14, color: Colors.white),
                        label: const Text('Test', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white)),
                        onPressed: () async {
                          await _notificationService.scheduleTestNotification();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Test notification scheduled for 5 seconds from now.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (reminders.isEmpty)
                  _buildEmptyState()
                else ...[
                  _buildGroup('Skincare Routines', reminders.where((r) => r.type == 'routine').toList()),
                  _buildGroup('Medicine & Doses', reminders.where((r) => r.type == 'medicine').toList()),
                  _buildGroup('Skin Re-Scan Alerts', reminders.where((r) => r.type == 'rescan').toList()),
                  _buildGroup('Other Reminders', reminders.where((r) => r.type != 'routine' && r.type != 'medicine' && r.type != 'rescan').toList()),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
        children: [
          const Icon(CupertinoIcons.bell_fill, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          const Text(
            'No Reminders Yet',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Set reminders for your morning skincare, evening routine, and medicines.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          GlowButton(
            label: 'Add First Reminder',
            onPressed: () => _showAddEditSheet(context),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildGroup(String title, List<AppReminder> groupReminders) {
    if (groupReminders.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 12),
          child: Text(
            title,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
        ),
        ...groupReminders.map((r) => Dismissible(
              key: Key(r.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(12)),
                child: const Icon(CupertinoIcons.delete, color: Colors.white),
              ),
              onDismissed: (_) async {
                await ref.read(reminderRepositoryProvider).deleteReminder(r.id);
                await _notificationService.cancelReminder(r.id);
                setState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted "${r.title}"')),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: GlowCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          r.timeStr,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(r.body, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Switch(
                        activeThumbColor: AppColors.primary,
                        value: r.isEnabled,
                        onChanged: (val) async {
                          await ref.read(reminderRepositoryProvider).toggleReminder(r.id, val);
                          final updated = r.copyWith(isEnabled: val);
                          await _notificationService.scheduleReminder(updated);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  void _showAddEditSheet(BuildContext context) {
    String title = 'Morning Skincare';
    String body = 'Time for Cleanser, Toner, Serum & Sunscreen!';
    String type = 'routine';
    TimeOfDay time = const TimeOfDay(hour: 8, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Reminder', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'routine', child: Text('Skincare Routine')),
                  DropdownMenuItem(value: 'medicine', child: Text('Medicine Dose')),
                  DropdownMenuItem(value: 'rescan', child: Text('Skin Re-Scan Alert')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom Reminder')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => type = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: title,
                decoration: const InputDecoration(labelText: 'Title'),
                onChanged: (val) => title = val,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: body,
                decoration: const InputDecoration(labelText: 'Details / Description'),
                onChanged: (val) => body = val,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Time: ${time.format(context)}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(context: context, initialTime: time);
                      if (picked != null) setModalState(() => time = picked);
                    },
                    child: const Text('Change Time', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GlowButton(
                label: 'Save & Schedule',
                onPressed: () async {
                  final formattedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  final reminder = AppReminder(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    body: body,
                    type: type,
                    timeStr: formattedTime,
                    repeatDays: const [1, 2, 3, 4, 5, 6, 7], // Every day
                    isEnabled: true,
                  );

                  await ref.read(reminderRepositoryProvider).saveReminder(reminder);
                  await _notificationService.scheduleReminder(reminder);
                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {});
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
