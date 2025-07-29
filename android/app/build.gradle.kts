// 1) Importa estas clases al principio del archivo:
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// 2) Carga tu key.properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

android {
    namespace = "com.GrullonDev.personal_finance"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.GrullonDev.personal_finance"
        minSdk = 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }

    // 3) Define el signingConfig de “release”
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            // 4) Aplica tu signingConfig de “release”
            signingConfig = signingConfigs.getByName("release")

            // Opcional: minify/proguard
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
        // Nota: no toques el buildType debug si no quieres cambiarlo
    }
}

dependencies {
    implementation("com.facebook.android:facebook-android-sdk:18.0.3")
}

flutter {
    source = "../.."
}
