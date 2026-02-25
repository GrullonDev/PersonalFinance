-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keepnames class com.google.android.gms.** { *; }

# Keep generic Parcelable creators (common cause of unmarshalling errors)
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Explicitly keep Identity suite for Google Sign In
-keep class com.google.android.gms.auth.api.identity.** { *; }
-keepnames class com.google.android.gms.auth.api.identity.** { *; }

# Keep the specific class mentioned in the crash log
-keep class com.google.android.gms.auth.api.identity.GetSignInIntentRequest { *; }
-keepnames class com.google.android.gms.auth.api.identity.GetSignInIntentRequest { *; }
