import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/reminder_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/reminder_model.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/glow_card.dart';

// TODO(module: notifications) connect to flutter_local_notifications engine

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(reminderProvider);

    return AppScaffold(
      title: 'Notification Settings',
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryDark,
        onPressed: () {
          ref.read(reminderProvider.notifier).add(
                ReminderModel(
                  id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
                  type: 'Skincare',
                  title: 'Mid-day Sunscreen Reapplication',
                  time: '01:30 PM',
                  repeat: 'Daily',
                  enabled: true,
                ),
              );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added new reminder alert')),
          );
        },
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Skincare & Medicine Alerts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Swipe left on any reminder to delete.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...reminders.map((rem) {
              return Dismissible(
                key: Key(rem.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  ref.read(reminderProvider.notifier).delete(rem.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted "${rem.title}"')),
                  );
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlowCard(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.alarm_rounded, color: AppColors.primaryDark),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rem.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '${rem.time} · ${rem.repeat}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: rem.enabled,
                          activeThumbColor: AppColors.primaryDark,
                          onChanged: (_) {
                            ref.read(reminderProvider.notifier).toggle(rem.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
