import 'package:flutter/material.dart';

/// Design System & Global Theme Constants for Mastitis Detection System (MDS)
class AppColors {
  AppColors._();

  // Primary Theme (Forest Green)
  static const Color primaryTheme = Color(0xFF215433);

  // Background Surface
  static const Color backgroundSurface = Color(0xFFF9FBF9);

  // Neutral Text & Borders
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF7A7A7A);
  static const Color borderNeutral = Color(0xFFE0E5E0);
  static const Color cardSurface = Colors.white;

  // Semantic Status Badges
  // Healthy / Absent / Read
  static const Color badgeHealthyBg = Color(0xFFE2F1E5);
  static const Color badgeHealthyText = Color(0xFF3A7D4E);

  // At Risk / Present / Unread
  static const Color badgeAtRiskBg = Color(0xFFFCE4E4);
  static const Color badgeAtRiskText = Color(0xFFC54E4E);

  // Pending
  static const Color badgePendingBg = Color(0xFFF5EBD6);
  static const Color badgePendingText = Color(0xFF8C6D33);
}

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Roboto';

  // Screen Titles (H1): 24px, Font Weight 600 (Semi-bold), Color #215433
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryTheme,
    letterSpacing: -0.3,
  );

  // Section Headers & Cards (H2): 16px to 18px, Font Weight 600
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2Small = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Header Title for AppHeader: 16px, Semi-bold, White
  static const TextStyle appHeaderTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // List Row Titles: 14px, Font Weight 500 (Medium)
  static const TextStyle listRowTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // Body Text (Labels & Tabular Data): 14px, Font Weight 400 (Regular)
  static const TextStyle bodyRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodyRegularDark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  // Button Text: 15px, Font Weight 600, White
  static const TextStyle buttonText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Status Badge Text: 12px to 13px, Font Weight 600
  static const TextStyle badgeText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
}

class AppRadii {
  AppRadii._();

  // Container Radii: 12px for standard cards and input fields
  static const double container = 12.0;
  static const Radius containerRadius = Radius.circular(container);
  static const BorderRadius containerBorderRadius = BorderRadius.all(containerRadius);

  // Button Radii: 8px for Primary action buttons
  static const double button = 8.0;
  static const BorderRadius buttonBorderRadius = BorderRadius.all(Radius.circular(button));

  // Bottom NavBar items: 12px
  static const double navBarItem = 12.0;
  static const BorderRadius navBarBorderRadius = BorderRadius.all(Radius.circular(navBarItem));

  // Status Badges: 16px (pill shape)
  static const double badge = 16.0;
  static const BorderRadius badgeBorderRadius = BorderRadius.all(Radius.circular(badge));
}

class AppSpacing {
  AppSpacing._();

  // Global Padding: 16px to 24px horizontal margin for screen edges
  static const double horizontalScreenMargin = 20.0;
  static const double verticalScreenMargin = 16.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundSurface,
      fontFamily: AppTypography.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryTheme,
        primary: AppColors.primaryTheme,
        surface: AppColors.backgroundSurface,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderNeutral,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.containerBorderRadius,
          borderSide: BorderSide(color: AppColors.borderNeutral, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.containerBorderRadius,
          borderSide: BorderSide(color: AppColors.borderNeutral, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.containerBorderRadius,
          borderSide: BorderSide(color: AppColors.primaryTheme, width: 1.5),
        ),
      ),
    );
  }
}
