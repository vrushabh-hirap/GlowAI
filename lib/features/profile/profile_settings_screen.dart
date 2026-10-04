import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/soft_button.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final TextEditingController _serverController = TextEditingController(text: ApiConfig.defaultServerUrl);

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  void _confirmLogout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout_rounded, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              const Text(
                'Confirm Logout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to log out of GlowAI?',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SoftButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlowButton(
                      label: 'Logout',
                      onPressed: () {
                        Navigator.of(context).pop();
                        ref.read(authProvider.notifier).logout();
                        context.go('/login');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteData() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete All My Data?'),
          content: const Text('This action will permanently erase your local face scan history, appointments, and prescriptions.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All local data cleared (mock reset)')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    return AppScaffold(
      title: 'Profile & Settings',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Banner
            GlowCard(
              hasGlow: true,
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      user.role == UserRole.doctor ? Icons.medical_services_rounded : Icons.person_rounded,
                      size: 32,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(user.email, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            user.role == UserRole.doctor ? 'DOCTOR MODE' : 'PATIENT MODE',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Role Switcher Tile
            const Text('Switch Account Role', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GlowCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.role == UserRole.doctor ? 'Currently: Doctor Account' : 'Currently: Patient Account',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      const Text('Toggle to preview both app experiences', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  Switch(
                    value: user.role == UserRole.doctor,
                    activeThumbColor: AppColors.primaryDark,
                    onChanged: (val) {
                      final newRole = val ? UserRole.doctor : UserRole.patient;
                      ref.read(authProvider.notifier).switchRole(newRole);
                      if (newRole == UserRole.doctor) {
                        context.go('/doctor/dashboard');
                      } else {
                        context.go('/patient/home');
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // FastAPI Server URL Configuration
            const Text('Python Backend API Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: 'FastAPI Server Base URL',
                    hintText: 'http://10.0.2.2:8000',
                    controller: _serverController,
                  ),
                  const SizedBox(height: 12),
                  SoftButton(
                    label: 'Save Server Endpoint',
                    height: 38,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Saved API endpoint: ${_serverController.text}')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Navigation Links List
            GlowCard(
              child: Column(
                children: [
                  _SettingsListTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notification Settings',
                    onTap: () => context.push('/notifications'),
                  ),
                  const Divider(height: 16),
                  _SettingsListTile(
                    icon: Icons.workspace_premium_rounded,
                    title: 'GlowAI Premium',
                    onTap: () => context.push('/premium'),
                  ),
                  const Divider(height: 16),
                  _SettingsListTile(
                    icon: Icons.delete_outline_rounded,
                    title: 'Delete My Data',
                    textColor: AppColors.danger,
                    onTap: _confirmDeleteData,
                  ),
                  const Divider(height: 16),
                  _SettingsListTile(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    textColor: AppColors.danger,
                    onTap: _confirmLogout,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Center(
              child: Text(
                'GlowAI Prototype v1.0.0 (UI Shell)',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SettingsListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color textColor;
  final VoidCallback onTap;

  const _SettingsListTile({
    required this.icon,
    required this.title,
    this.textColor = AppColors.textPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 14),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
