import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0, initialLocation: true);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            Expanded(child: navigationShell),
            AppleTabBar(
              currentIndex: navigationShell.currentIndex,
              onTap: _onTap,
              items: _patientNavItems,
            ),
          ],
        ),
      ),
    );
  }
}
