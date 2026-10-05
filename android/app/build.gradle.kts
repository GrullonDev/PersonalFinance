// 1) Importa estas clases al principio del archivo:
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// 2) Datos de firma: se leen de `.env` en la raíz del proyecto (o de
//    android/key.properties). Ninguno de los dos se sube a git.
//    Claves: storePassword, keyPassword, keyAlias, storeFile.
val keystoreProperties = Properties().apply {
    listOf(rootProject.file("../.env"), rootProject.file("key.properties"))
        .filter { it.exists() }
        .forEach { file -> FileInputStream(file).use { load(it) } }
}

android {
    namespace = "com.grullondev.personal_finance"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    defaultConfig {
        applicationId = "com.grullondev.personal_finance"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        
        // versionCode = 1.000.000 + número de build del pubspec (el "+N").
        // Antes se usaba la hora (≈ 850.000 en 2026); la base de 1.000.000
        // garantiza que los nuevos sigan siendo mayores en Google Play y que
        // suban de uno en uno con scripts/release.sh.
        versionCode = 1_000_000 + flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        create("release") {
            val keyAliasProp = keystoreProperties["keyAlias"] as? String
            val keyPasswordProp = keystoreProperties["keyPassword"] as? String
            val storeFileProp = keystoreProperties["storeFile"] as? String
            val storePasswordProp = keystoreProperties["storePassword"] as? String

            if (keyAliasProp != null && keyPasswordProp != null && storeFileProp != null && storePasswordProp != null) {
                keyAlias = keyAliasProp
                keyPassword = keyPasswordProp
                storeFile = file(storeFileProp)
                storePassword = storePasswordProp
            }
        }
    }

    buildTypes {
        getByName("release") {
            // Use production keystore when available; fall back to debug for local APK testing.
            signingConfig = if (keystoreProperties["keyAlias"] != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.android.gms:play-services-auth:21.3.0")
    implementation("androidx.credentials:credentials:1.3.0")
    implementation("androidx.credentials:credentials-play-services-auth:1.3.0")
    implementation("com.google.android.libraries.identity.googleid:googleid:1.1.1")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("androidx.core:core-splashscreen:1.0.1")
}

flutter {
    source = "../.."
}
