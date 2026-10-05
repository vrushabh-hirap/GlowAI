import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors_extension.dart';
import 'glow_logo.dart';
import 'tappable.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBottomBorder;
  final bool isHomeHeader;
  final bool showLogo;
  final VoidCallback? onNotificationTap;
  final bool hasUnreadNotification;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.showBottomBorder = false,
    this.isHomeHeader = false,
    this.showLogo = false,
    this.onNotificationTap,
    this.hasUnreadNotification = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(isHomeHeader ? 74 : (subtitle != null ? 68 : 56));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final firstName = user.name.trim().isEmpty ? 'there' : user.name.trim().split(' ').first;
    final colors = context.appColors;
    return SafeArea(
      bottom: false,
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: colors.background,
          border: showBottomBorder
              ? Border(
                  bottom: BorderSide(color: colors.border, width: 1),
                )
              : null,
        ),
        child: isHomeHeader
            ? Row(
                children: [
                  const GlowLogo(
                    size: 42,
                    variant: GlowLogoVariant.onGradient,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hello, $firstName 👋',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: colors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'How is your skin feeling today?',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tappable(
                    onTap: onNotificationTap,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            color: colors.textPrimary,
                            size: 22,
                          ),
                          if (hasUnreadNotification)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 12),
                  ] else if (showLogo) ...[
                    const GlowLogo(
                      size: 36,
                      variant: GlowLogoVariant.onGradient,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: colors.textPrimary,
                            fontSize: subtitle != null ? 18 : 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
      ),
    );
  }
}
