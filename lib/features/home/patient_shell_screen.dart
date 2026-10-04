import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/apple_tab_bar.dart';

class PatientShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const PatientShellScreen({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  static const List<AppleTabItemData> _patientNavItems = [
    AppleTabItemData(
      activeIcon: CupertinoIcons.house_fill,
      inactiveIcon: CupertinoIcons.house,
      label: 'Home',
    ),
    AppleTabItemData(
      activeIcon: CupertinoIcons.sparkles,
      inactiveIcon: CupertinoIcons.sparkles,
      label: 'Scan',
    ),
    AppleTabItemData(
      activeIcon: CupertinoIcons.heart_fill,
      inactiveIcon: CupertinoIcons.heart,
      label: 'Consult',
    ),
    AppleTabItemData(
      activeIcon: CupertinoIcons.leaf_arrow_circlepath,
      inactiveIcon: CupertinoIcons.leaf_arrow_circlepath,
      label: 'Care',
    ),
    AppleTabItemData(
      activeIcon: CupertinoIcons.person_crop_circle_fill,
      inactiveIcon: CupertinoIcons.person_crop_circle,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // No bottomNavigationBar — the tab bar floats via Stack
      body: Stack(
        children: [
          // Full-screen content — extended behind the floating bar
          Positioned.fill(child: navigationShell),
          // Floating tab bar pinned to the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppleTabBar(
              currentIndex: navigationShell.currentIndex,
              onTap: _onTap,
              items: _patientNavItems,
            ),
          ),
        ],
      ),
    );
  }
}
