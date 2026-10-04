import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'tappable.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showBackButton;
  final VoidCallback? onBack;

  const AppScaffold({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showBackButton = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final shouldShowBack = showBackButton && canPop;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: (title != null || titleWidget != null || shouldShowBack)
          ? AppBar(
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              leading: shouldShowBack
                  ? Tappable(
                      onTap: onBack ?? () => Navigator.of(context).maybePop(),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.arrow_left,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    )
                  : null,
              title: titleWidget ??
                  (title != null
                      ? Text(
                          title!,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null),
              actions: actions,
            )
          : null,
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
