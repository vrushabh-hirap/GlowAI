import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_colors_extension.dart';

class AppTheme {
  AppTheme._();

  // ──────────────── LIGHT THEME ────────────────
  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.primarySoft,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.primaryDark,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceMuted,
        outline: AppColors.border,
        outlineVariant: AppColors.borderStrong,
        error: AppColors.danger,
        surfaceTint: Colors.transparent,
      ),
      textTheme: _buildTextTheme(AppColors.textPrimary, AppColors.textSecondary, AppColors.textHint),
      appBarTheme: _buildAppBarTheme(AppColors.background, AppColors.textPrimary),
      cardTheme: _buildCardTheme(AppColors.surface, AppColors.border),
      chipTheme: _buildChipTheme(AppColors.surface, AppColors.primarySoft, AppColors.border, AppColors.textPrimary),
      elevatedButtonTheme: _buildElevatedButtonTheme(AppColors.primary, AppColors.primaryGradientEnd, AppColors.textOnPrimary),
      outlinedButtonTheme: _buildOutlinedButtonTheme(AppColors.primary, AppColors.border),
      textButtonTheme: _buildTextButtonTheme(AppColors.primary),
      inputDecorationTheme: _buildInputDecorationTheme(
        AppColors.surfaceMuted,
        AppColors.border,
        AppColors.textPrimary,
        AppColors.textHint,
      ),
      switchTheme: _buildSwitchTheme(AppColors.primary),
      checkboxTheme: _buildCheckboxTheme(AppColors.primary),
      sliderTheme: _buildSliderTheme(AppColors.primary),
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.poppins(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        modalBackgroundColor: AppColors.surface,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14),
        actionTextColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.poppins(color: AppColors.surface, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primarySoft,
        circularTrackColor: AppColors.primarySoft,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        indicator: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        
        elevation: 0,
        indicatorColor: AppColors.primarySoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12);
          }
          return GoogleFonts.poppins(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 12);
        }),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        
        headerBackgroundColor: AppColors.primarySoft,
        headerForegroundColor: AppColors.textPrimary,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.textOnPrimary;
          return AppColors.textPrimary;
        }),
        todayForegroundColor: WidgetStateProperty.all(AppColors.primary),
        todayBackgroundColor: WidgetStateProperty.all(AppColors.primarySoft),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surface,
        
        hourMinuteTextColor: AppColors.textPrimary,
        dayPeriodTextColor: AppColors.textSecondary,
        dialBackgroundColor: AppColors.primarySoft,
        dialHandColor: AppColors.primary,
        dialTextColor: AppColors.textOnPrimary,
        entryModeIconColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      extensions: [AppColorsExtension.light],
    );
  }

  // ──────────────── DARK THEME ────────────────
  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkTextOnPrimary,
        primaryContainer: AppColors.darkPrimarySoft,
        onPrimaryContainer: AppColors.darkPrimaryDark,
        secondary: AppColors.darkPrimaryDark,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerHighest: AppColors.darkSurfaceMuted,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkBorderStrong,
        error: AppColors.darkDanger,
        surfaceTint: Colors.transparent,
      ),
      textTheme: _buildTextTheme(AppColors.darkTextPrimary, AppColors.darkTextSecondary, AppColors.darkTextHint),
      appBarTheme: _buildAppBarTheme(AppColors.darkBackground, AppColors.darkTextPrimary),
      cardTheme: _buildCardTheme(AppColors.darkSurface, AppColors.darkBorder),
      chipTheme: _buildChipTheme(AppColors.darkSurface, AppColors.darkPrimarySoft, AppColors.darkBorder, AppColors.darkTextPrimary),
      elevatedButtonTheme: _buildElevatedButtonTheme(AppColors.darkPrimary, AppColors.darkPrimaryGradientEnd, AppColors.darkTextOnPrimary),
      outlinedButtonTheme: _buildOutlinedButtonTheme(AppColors.darkPrimary, AppColors.darkBorder),
      textButtonTheme: _buildTextButtonTheme(AppColors.darkPrimary),
      inputDecorationTheme: _buildInputDecorationTheme(
        AppColors.darkSurfaceMuted,
        AppColors.darkBorder,
        AppColors.darkTextPrimary,
        AppColors.darkTextHint,
      ),
      switchTheme: _buildSwitchTheme(AppColors.darkPrimary),
      checkboxTheme: _buildCheckboxTheme(AppColors.darkPrimary),
      sliderTheme: _buildSliderTheme(AppColors.darkPrimary),
      dividerTheme: DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.poppins(
          color: AppColors.darkTextSecondary,
          fontSize: 14,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        modalBackgroundColor: AppColors.darkSurface,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceHigh,
        contentTextStyle: GoogleFonts.poppins(color: AppColors.darkTextPrimary, fontSize: 14),
        actionTextColor: AppColors.darkPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkSurface,
        
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.poppins(color: AppColors.darkTextPrimary, fontSize: 14),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkTextPrimary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.poppins(color: AppColors.darkBackground, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.darkPrimary,
        linearTrackColor: AppColors.darkPrimarySoft,
        circularTrackColor: AppColors.darkPrimarySoft,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.darkTextPrimary,
        unselectedLabelColor: AppColors.darkTextSecondary,
        indicator: BoxDecoration(
          color: AppColors.darkPrimarySoft,
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        
        elevation: 0,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        
        elevation: 0,
        indicatorColor: AppColors.darkPrimarySoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(color: AppColors.darkPrimary, fontWeight: FontWeight.w600, fontSize: 12);
          }
          return GoogleFonts.poppins(color: AppColors.darkTextSecondary, fontWeight: FontWeight.w500, fontSize: 12);
        }),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.darkSurface,
        
        headerBackgroundColor: AppColors.darkPrimarySoft,
        headerForegroundColor: AppColors.darkTextPrimary,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.darkTextOnPrimary;
          return AppColors.darkTextPrimary;
        }),
        todayForegroundColor: WidgetStateProperty.all(AppColors.darkPrimary),
        todayBackgroundColor: WidgetStateProperty.all(AppColors.darkPrimarySoft),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.darkSurface,
        
        hourMinuteTextColor: AppColors.darkTextPrimary,
        dayPeriodTextColor: AppColors.darkTextSecondary,
        dialBackgroundColor: AppColors.darkPrimarySoft,
        dialHandColor: AppColors.darkPrimary,
        dialTextColor: AppColors.darkTextOnPrimary,
        entryModeIconColor: AppColors.darkPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      extensions: [AppColorsExtension.dark],
    );
  }

  // ──────────────── SHARED BUILDERS ────────────────
  static TextTheme _buildTextTheme(Color primary, Color secondary, Color hint) {
    final base = GoogleFonts.poppinsTextTheme();
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(color: primary, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.poppins().fontFamily),
      headlineMedium: base.headlineMedium?.copyWith(color: primary, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.poppins().fontFamily),
      headlineSmall: base.headlineSmall?.copyWith(color: primary, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.poppins().fontFamily),
      titleLarge: base.titleLarge?.copyWith(color: primary, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.poppins().fontFamily),
      titleMedium: base.titleMedium?.copyWith(color: primary, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.poppins().fontFamily),
      titleSmall: base.titleSmall?.copyWith(color: primary, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.poppins().fontFamily),
      bodyLarge: base.bodyLarge?.copyWith(color: primary, fontFamily: GoogleFonts.poppins().fontFamily),
      bodyMedium: base.bodyMedium?.copyWith(color: primary, fontFamily: GoogleFonts.poppins().fontFamily),
      bodySmall: base.bodySmall?.copyWith(color: secondary, fontFamily: GoogleFonts.poppins().fontFamily),
      labelLarge: base.labelLarge?.copyWith(color: primary, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.poppins().fontFamily),
      labelMedium: base.labelMedium?.copyWith(color: primary, fontFamily: GoogleFonts.poppins().fontFamily),
      labelSmall: base.labelSmall?.copyWith(color: hint, fontFamily: GoogleFonts.poppins().fontFamily),
    );
  }

  static AppBarTheme _buildAppBarTheme(Color bg, Color fg) {
    return AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: fg),
      titleTextStyle: GoogleFonts.poppins(color: fg, fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  static CardThemeData _buildCardTheme(Color surface, Color border) {
    return CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: border, width: 1),
      ),
      margin: EdgeInsets.zero,
    );
  }

  static ChipThemeData _buildChipTheme(Color surface, Color selectedColor, Color border, Color text) {
    return ChipThemeData(
      backgroundColor: surface,
      selectedColor: selectedColor,
      disabledColor: surface,
      side: BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: GoogleFonts.poppins(color: text, fontSize: 13),
      secondaryLabelStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      labelPadding: EdgeInsets.zero,
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(Color primary, Color gradientEnd, Color onPrimary) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: onPrimary),
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(Color primary, Color border) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: border, width: 1.5),
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: primary),
        foregroundColor: primary,
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(Color primary) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(
    Color fillColor,
    Color borderColor,
    Color textColor,
    Color hintColor,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.poppins(color: hintColor, fontSize: 14),
      labelStyle: GoogleFonts.poppins(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
      floatingLabelStyle: GoogleFonts.poppins(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.danger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.danger, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.border, width: 1),
      ),
      prefixIconColor: AppColors.textHint,
      suffixIconColor: AppColors.textHint,
    );
  }

  static SwitchThemeData _buildSwitchTheme(Color primary) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) return primary;
        return Colors.grey.shade300;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) return Colors.transparent;
        return Colors.grey.shade300;
      }),
      overlayColor: WidgetStateProperty.all(primary.withValues(alpha: 0.12)),
    );
  }

  static CheckboxThemeData _buildCheckboxTheme(Color primary) {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) return primary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: BorderSide(color: AppColors.border, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      overlayColor: WidgetStateProperty.all(primary.withValues(alpha: 0.12)),
    );
  }

  static SliderThemeData _buildSliderTheme(Color primary) {
    return SliderThemeData(
      activeTrackColor: primary,
      inactiveTrackColor: primary.withValues(alpha: 0.2),
      thumbColor: primary,
      overlayColor: primary.withValues(alpha: 0.12),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
      valueIndicatorTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
      activeTickMarkColor: primary,
      inactiveTickMarkColor: primary.withValues(alpha: 0.3),
    );
  }
}