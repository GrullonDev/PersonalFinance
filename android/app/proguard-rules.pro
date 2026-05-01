-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keepnames class com.google.android.gms.** { *; }
-keep class com.google.android.gms.auth.api.identity.GetSignInIntentRequest { *; }
-keepnames class com.google.android.gms.auth.api.identity.GetSignInIntentRequest { *; }

# Firebase plugins used by the release build.
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class io.flutter.plugins.firebase.analytics.** { *; }
-keep class io.flutter.plugins.firebase.auth.** { *; }
-keep class io.flutter.plugins.firebase.core.** { *; }
-keep class io.flutter.plugins.firebase.crashlytics.** { *; }
-keep class io.flutter.plugins.firebase.firestore.** { *; }
-keep class io.flutter.plugins.firebase.storage.** { *; }

# Flutter plugin registrant and native plugins used by secure storage / file access.
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class io.flutter.plugins.urllauncher.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Hive is pure Dart, so it does not need Android-side keep rules beyond its path plugins.
