# ============================================================
# proguard-rules.pro — Reglas de ofuscación para release build
# ============================================================

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google ML Kit — Text Recognition (todas las variantes de idioma)
-keep class com.google.mlkit.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Evitar que R8 elimine clases referenciadas dinámicamente
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# Mantener anotaciones necesarias para la reflexión
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod

# Google Play Core — Deferred Components (Flutter los referencia pero no son necesarios en APK normal)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
