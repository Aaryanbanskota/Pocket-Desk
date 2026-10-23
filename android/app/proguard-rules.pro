# Keep Generic Signatures & Annotations for reflection & Gson TypeToken
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Suppress missing class warnings for optional Play Core / deferred components
-dontwarn com.google.android.play.core.**
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**

# Gson Rules for Flutter Local Notifications
-dontwarn com.google.gson.**
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.TypeAdapter { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# Flutter Wrapper & Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler

# Keep SharedPreferences Pigeon & Kotlin Coroutines
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class * extends io.flutter.plugins.sharedpreferences.** { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.** { *; }
-keep class kotlinx.coroutines.** { *; }

# Keep Local Auth
-keep class io.flutter.plugins.localauth.** { *; }

# Keep Drift / SQLite / Isar
-keep class com.simon* { *; }
-keep class dev.isar.** { *; }
-keep class io.simondac.drift.** { *; }

# Don't obfuscate by default so method reflection and native JNI match 1:1
-dontobfuscate
