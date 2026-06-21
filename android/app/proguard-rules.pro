# TrustShield AI ProGuard Rules

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# TrustShield Notification Service
-keep class com.trustshield.trustshield_ai.TrustShieldNotificationService { *; }
-keep class com.trustshield.trustshield_ai.MainActivity { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# Gson / JSON
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# Prevent stripping of debug info
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
