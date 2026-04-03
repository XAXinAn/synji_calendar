# ML Kit Text Recognition
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**

# device_calendar 插件混淆规则
-keep class com.builttoroam.devicecalendar.** { *; }

# permission_handler 插件混淆规则
-keep class com.baseflow.permissionhandler.** { *; }

# Flutter 基础混淆规则
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# 忽略 Google Play Core 相关类的缺失告警 (解决 R8 报错)
-dontwarn com.google.android.play.core.**
