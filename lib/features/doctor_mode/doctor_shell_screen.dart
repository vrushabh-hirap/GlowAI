import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/apple_tab_bar.dart';

class DoctorShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const DoctorShellScreen({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  static const List<AppleTabItemData> _doctorNavItems = [
    AppleTabItemData(
      activeIcon: CupertinoIcons.square_grid_2x2_fill,
      inactiveIcon: CupertinoIcons.square_grid_2x2,
      label: 'Dashboard',
    ),
    AppleTabItemData(
      activeIcon: CupertinoIcons.calendar_badge_plus,
      inactiveIcon: CupertinoIcons.calendar,
      label: 'Appointments',
    ),
    AppleTabItemData(
      activeIcon: CupertinoIcons.person_2_fill,
      inactiveIcon: CupertinoIcons.person_2,
      label: 'Patients',
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
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppleTabBar(
              currentIndex: navigationShell.currentIndex,
              onTap: _onTap,
              items: _doctorNavItems,
            ),
          ),
        ],
      ),
    );
  }
}
