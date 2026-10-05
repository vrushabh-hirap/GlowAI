import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/hive_storage_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../core/theme/theme_provider.dart';
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
  @override
  void dispose() {
    super.dispose();
  }

  void _editName() {
    final controller = TextEditingController(text: ref.read(authProvider).name);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 110),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit Name',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: context.appColors.textPrimary)),
            SizedBox(height: 16),
            AppTextField(
              label: 'Full Name',
              hintText: 'Enter your name',
              controller: controller,
            ),
            SizedBox(height: 20),
            GlowButton(
              label: 'Save',
              width: double.infinity,
              style: GlowButtonStyle.primary,
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                ref.read(authProvider.notifier).updateName(controller.text.trim());
                Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoSheet(String title, String body) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: context.appColors.textPrimary)),
            SizedBox(height: 12),
            Text(body,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, height: 1.6, color: context.appColors.textSecondary)),
            SizedBox(height: 20),
            GlowButton(
              label: 'Close',
              width: double.infinity,
              style: GlowButtonStyle.secondary,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Color(0xFFFDE8E8),
                  shape: BoxShape.circle,
                ),
                child: Icon(CupertinoIcons.square_arrow_right_fill, size: 26, color: context.appColors.danger),
              ),
              SizedBox(height: 14),
              Text(
                'Confirm Logout',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Are you sure you want to log out of GlowAI?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: context.appColors.textSecondary,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GlowButton(
                      label: 'Cancel',
                      style: GlowButtonStyle.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(width: 12),
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
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Color(0xFFFDE8E8),
                  shape: BoxShape.circle,
                ),
                child: Icon(CupertinoIcons.trash_fill, size: 26, color: context.appColors.danger),
              ),
              SizedBox(height: 14),
              Text(
                'Delete All Data?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'This will permanently erase your local face scan history, appointments, and prescriptions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: context.appColors.textSecondary,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GlowButton(
                      label: 'Cancel',
                      style: GlowButtonStyle.secondary,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GlowButton(
                      label: 'Delete Data',
                      style: GlowButtonStyle.primary,
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        await NotificationService().cancelAll();
                        await HiveStorageService.clearAllUserData();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        // Use the ConsumerState's mounted / context, not the sheet's.
                        if (!mounted) return;
                        showAppToast(context, 'All local data cleared');
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: context.appColors.background,
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
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [context.appColors.primary, Color(0xFFE29BB4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user.name.isNotEmpty ? user.name.substring(0, 2).toUpperCase() : 'SM',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: context.appColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.appColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user.role == UserRole.doctor ? 'DOCTOR MODE' : 'PATIENT MODE',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: context.appColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Navigation Links List
            GlowCard(
              child: Column(
                children: [
                  _SettingsListTile(
                    icon: CupertinoIcons.bell,
                    title: 'Notification Settings',
                    onTap: () => context.push('/notifications'),
                  ),
                  Divider(height: 16),
                  _SettingsListTile(
                    icon: CupertinoIcons.star,
                    title: 'GlowAI Premium',
                    onTap: () => context.push('/premium'),
                  ),
                  Divider(height: 16),
                  _SettingsListTile(
                    icon: CupertinoIcons.pencil,
                    title: 'Edit Name',
                    onTap: _editName,
                  ),
                  Divider(height: 16),
                  _ThemeToggleTile(),
                  Divider(height: 16),
                  _SettingsListTile(
                    icon: CupertinoIcons.shield_lefthalf_fill,
                    title: 'Privacy Policy',
                    onTap: () => _showInfoSheet(
                      'Privacy Policy',
                      'GlowAI processes your face scans and personal details only to provide skin analysis and dermatology services. Your data is stored securely and never shared with third parties without your consent. You can delete your data at any time from this screen.',
                    ),
                  ),
                  Divider(height: 16),
                  _SettingsListTile(
                    icon: CupertinoIcons.doc_text,
                    title: 'Terms & Conditions',
                    onTap: () => _showInfoSheet(
                      'Terms & Conditions',
                      'GlowAI provides informational screening only and is not a medical diagnosis. Consultations should be used to confirm conditions shown by the scan. By using GlowAI you agree to use it responsibly. We may update these terms from time to time.',
                    ),
                  ),
                  Divider(height: 16),
                  _SettingsListTile(
                    icon: CupertinoIcons.trash,
                    title: 'Delete My Data',
                    textColor: context.appColors.danger,
                    onTap: _confirmDeleteData,
                  ),
                  Divider(height: 16),
                  _SettingsListTile(
                    icon: CupertinoIcons.square_arrow_right,
                    title: 'Logout',
                    textColor: context.appColors.danger,
                    onTap: _confirmLogout,
                  ),
                ],
              ),
            ),
            SizedBox(height: 28),

            Center(
              child: Text(
                'GlowAI Prototype v1.0.0',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: context.appColors.textHint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggleTile extends ConsumerWidget {
  const _ThemeToggleTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeModeOption.dark ||
        (themeMode == ThemeModeOption.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return ListTile(
      leading: Icon(
        isDark ? CupertinoIcons.moon_stars_fill : CupertinoIcons.sun_max_fill,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        'Appearance',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        themeMode == ThemeModeOption.system ? 'System' : isDark ? 'Dark' : 'Light',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          color: context.appColors.textSecondary,
        ),
      ),
      trailing: Switch(
        value: isDark,
        onChanged: (value) {
          ref.read(themeModeProvider.notifier).setThemeMode(value ? ThemeModeOption.dark : ThemeModeOption.light);
        },
        activeThumbColor: Colors.white,
        activeTrackColor: Theme.of(context).colorScheme.primary,
      ),
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(
            isDark ? ThemeModeOption.light : ThemeModeOption.dark);
      },
    );
  }
}

class _SettingsListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? textColor;
  final VoidCallback onTap;

  const _SettingsListTile({
    required this.icon,
    required this.title,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final effectiveTextColor = textColor ?? colors.textPrimary;
    return Tappable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: effectiveTextColor, size: 18),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: effectiveTextColor,
              ),
            ),
            const Spacer(),
            Icon(CupertinoIcons.chevron_right, size: 14, color: colors.textHint),
          ],
        ),
      ),
    );
  }
}
