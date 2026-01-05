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
        
        // Genera un versionCode incremental automáticamente basado en el tiempo (minutos)
        // Esto evita errores de "versionCode ya utilizado" en Google Play Console.
        val timestampVersionCode = (System.currentTimeMillis() / 60000).toInt() - 29000000
        versionCode = timestampVersionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
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
            if (keystoreProperties["keyAlias"] != null) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    implementation("com.facebook.android:facebook-android-sdk:18.0.3")
    implementation("com.google.android.gms:play-services-auth:21.0.0")
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}
