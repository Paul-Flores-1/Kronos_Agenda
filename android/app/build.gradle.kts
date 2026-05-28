import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

// --- DIAGNÓSTICO DE ARCHIVO ---
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

// Imprimimos en la consola dónde lo está buscando
println("BUSCANDO key.properties EN: ${keystorePropertiesFile.absolutePath}")

if (keystorePropertiesFile.exists()) {
    println("ARCHIVO ENCONTRADO. Cargando datos...")
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    println("ERROR FATAL: No se encontró key.properties. Verifica el nombre y la ubicación.")
}

android {
    namespace = "com.agnda.kronos"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.agnda.kronos"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            // Usamos "as? String" y el operador "?:" para evitar el error rojo si falla la carga.
            // Si no encuentra el archivo, usará valores vacíos y fallará con un mensaje más claro después.
            keyAlias = (keystoreProperties["keyAlias"] as? String) ?: "MISSING_ALIAS"
            keyPassword = (keystoreProperties["keyPassword"] as? String) ?: "MISSING_PASS"
            
            val storeFileName = (keystoreProperties["storeFile"] as? String) ?: "upload-keystore.jks"
            storeFile = file(storeFileName)
            
            storePassword = (keystoreProperties["storePassword"] as? String) ?: "MISSING_STORE_PASS"
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}