import 'package:flutter/material.dart';

class AppConfig {
  // 后端服务地址
  static const String baseUrl = 'https://synjicalendar.xin/v1';
}

class AppColors {
  // 主色调
  static const Color primary = Color(0xFF2F54EB);
  static const Color primaryLight = Color(0xFFD6E4FF);
  
  // 辅助色
  static const Color success = Color(0xFF52C41A);
  static const Color warning = Color(0xFFFAAD14);
  static const Color error = Color(0xFFFF4D4F);
  
  // 背景色
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardBackground = Colors.white;
  
  // 文字颜色
  static const Color textMain = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF595959);
  static const Color textGrey = Color(0xFF8C8C8C);
  static const Color textLightGrey = Color(0xFFBFBFBF);
  
  // 装饰色
  static const Color divider = Color(0xFFF0F0F0);
  static const Color shadow = Color(0x0A000000);
}

class AppSpacings {
  static const double pagePadding = 16.0;
  static const double cardRadius = 12.0;
  static const double innerPadding = 16.0;
  static const double elementGap = 12.0;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.background,
        surfaceContainer: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      // 统一所有弹窗的背景颜色
      dialogBackgroundColor: AppColors.background,
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent, // 禁用 Material 3 默认的紫色调叠加
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacings.cardRadius),
        ),
      ),
      // 统一底部弹窗背景颜色
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background, // 统一标题栏背景
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textMain, size: 24),
        titleTextStyle: TextStyle(
          color: AppColors.textMain,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacings.cardRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent,
        border: InputBorder.none,
        hintStyle: const TextStyle(color: AppColors.textLightGrey, fontSize: 15),
      ),
    );
  }
}
