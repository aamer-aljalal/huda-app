# Protect Tarteel Alarm engine and Flutter channels from R8/ProGuard minification in release APK mode
-keep class com.tarteel.app.** { *; }
-keepclassmembers class com.tarteel.app.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Prevent R8 errors for missing optional Google Play Core features and Flutter embedding dependencies
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.**
-dontwarn io.flutter.**
-dontwarn com.tarteel.app.**

# Keep Raw resources from being stripped
-keepclassmembers class **.R$raw { *; }
-keep class **.R$raw { *; }
