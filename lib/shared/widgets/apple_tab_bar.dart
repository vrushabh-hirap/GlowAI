import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class AppleTabItemData {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final String? badgeText;

  const AppleTabItemData({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    this.badgeText,
  });
}

/// A floating, glassmorphic pill-style tab bar inspired by iOS 18.
/// Place it inside a Stack as the last child so it truly floats over content.
class AppleTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppleTabItemData> items;

  const AppleTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: bottomPadding > 0 ? bottomPadding + 8 : 20,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.7),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                return _TabItem(
                  item: items[index],
                  isSelected: index == currentIndex,
                  onTap: () {
                    if (index != currentIndex) {
                      HapticFeedback.selectionClick();
                      onTap(index);
                    }
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatefulWidget {
  final AppleTabItemData item;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _pillAnim;
  late Animation<Color?> _colorAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _pillAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _colorAnim = ColorTween(
      begin: AppColors.textSecondary,
      end: AppColors.primary,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isSelected) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_TabItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final color = _colorAnim.value ?? AppColors.textSecondary;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with animated pill background
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft.withValues(alpha: _pillAnim.value),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ScaleTransition(
                    scale: widget.isSelected
                        ? _scaleAnim
                        : const AlwaysStoppedAnimation(1.0),
                    child: Icon(
                      widget.isSelected
                          ? widget.item.activeIcon
                          : widget.item.inactiveIcon,
                      size: 22,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                // Label
                Text(
                  widget.item.label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: color,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
