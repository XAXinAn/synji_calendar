import 'package:flutter/material.dart';

class UIUtils {
  /// 显示与图片一致的底部全宽 SnackBar
  static void showToast(BuildContext context, String message, {Color? backgroundColor, Duration? duration}) {
    // 移除当前提示，确保即时响应
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        // 使用深色背景
        backgroundColor: backgroundColor ?? const Color(0xFF323232),
        // 使用 fixed 行为使其全宽且贴合底部/导航栏
        behavior: SnackBarBehavior.fixed,
        duration: duration ?? const Duration(seconds: 2),
        // 移除圆角
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        // 适当调整内部边距，使文字高度看起来与图片一致
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }
}
