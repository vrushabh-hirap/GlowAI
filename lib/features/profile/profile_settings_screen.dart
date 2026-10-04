import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../shared/utils/toast_helper.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/tappable.dart';

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
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE8E8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.square_arrow_right_fill, size: 26, color: AppColors.danger),
              ),
              const SizedBox(height: 14),
              const Text(
                'Confirm Logout',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Are you sure you want to log out of GlowAI?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GlowButton(
                      label: 'Cancel',
                      style: GlowButtonStyle.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlowButton(
                      label: 'Logout',
                      style: GlowButtonStyle.primary,
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
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE8E8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.trash_fill, size: 26, color: AppColors.danger),
              ),
              const SizedBox(height: 14),
              const Text(
                'Delete All Data?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'This will permanently erase your local face scan history, appointments, and prescriptions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GlowButton(
                      label: 'Cancel',
                      style: GlowButtonStyle.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlowButton(
                      label: 'Delete Data',
                      style: GlowButtonStyle.primary,
                      onPressed: () {
                        Navigator.of(context).pop();
                        showAppToast(context, 'All local data cleared');
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(
        title: 'Profile & Settings',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Banner Card
            GlowCard(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user.name.isNotEmpty ? user.name.substring(0, 2).toUpperCase() : 'SM',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user.role == UserRole.doctor ? 'DOCTOR MODE' : 'PATIENT MODE',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Developer Preview: Role Switcher
            const Text(
              'Developer Preview',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            GlowCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.role == UserRole.doctor ? 'Doctor Mode Active' : 'Patient Mode Active',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Switch role to test both UI shells (Dev only)',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: user.role == UserRole.doctor,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.surfaceMuted,
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

            // Analysis Server URL Settings
            const Text(
              'API Server Configuration',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            GlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: 'Analysis server URL',
                    hintText: 'http://10.0.2.2:8000',
                    controller: _serverController,
                  ),
                  const SizedBox(height: 14),
                  GlowButton(
                    label: 'Save Server Endpoint',
                    height: 42,
                    style: GlowButtonStyle.primary,
                    onPressed: () {
                      showAppToast(context, 'Saved endpoint: ${_serverController.text}');
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
                    icon: CupertinoIcons.bell,
                    title: 'Notification Settings',
                    onTap: () => context.push('/notifications'),
                  ),
                  const Divider(height: 16),
                  _SettingsListTile(
                    icon: CupertinoIcons.star,
                    title: 'GlowAI Premium',
                    onTap: () => context.push('/premium'),
                  ),
                  const Divider(height: 16),
                  _SettingsListTile(
                    icon: CupertinoIcons.trash,
                    title: 'Delete My Data',
                    textColor: AppColors.danger,
                    onTap: _confirmDeleteData,
                  ),
                  const Divider(height: 16),
                  _SettingsListTile(
                    icon: CupertinoIcons.square_arrow_right,
                    title: 'Logout',
                    textColor: AppColors.danger,
                    onTap: _confirmLogout,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Center(
              child: Text(
                'GlowAI Prototype v1.0.0',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ),
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
    return Tappable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const Spacer(),
            const Icon(CupertinoIcons.chevron_right, size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
