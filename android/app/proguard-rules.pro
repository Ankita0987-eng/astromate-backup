-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Hive
-keep class com.hive.** { *; }
-keep class io.hive.** { *; }
-keepclassmembers class * extends com.hive.HiveObject { *; }

# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
