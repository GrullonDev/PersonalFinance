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
    namespace = "com.grullondev.personal_finance"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.grullondev.personal_finance"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    // 3) Define el signingConfig de “release”
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
            // 4) Aplica tu signingConfig de “release”
            if (keystoreProperties["keyAlias"] != null) {
                signingConfig = signingConfigs.getByName("release")
            }

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

dependencies {
    implementation("com.facebook.android:facebook-android-sdk:18.0.3")
}

flutter {
    source = "../.."
}
