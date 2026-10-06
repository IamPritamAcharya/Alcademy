import com.android.build.api.dsl.ApplicationExtension
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // Flutter plugin must be applied after the Android plugin
    id("dev.flutter.flutter-gradle-plugin")
}

// Flutter reads the namespace from an `android { ... }` block before building.
// Use a local function to retain that syntax with AGP's public DSL type.
fun android(configure: ApplicationExtension.() -> Unit) {
    extensions.configure<ApplicationExtension> {
        configure()
    }
}

android {
    namespace = "com.alcademy.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.alcademy.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Replace with your keystore details
            storeFile = file("../keystore.jks")
            storePassword = "mikumiku"
            keyAlias = "alcademy-key"
            keyPassword = "mikumiku"

        }
    }

    buildTypes {
        named("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true           // Enables R8/ProGuard code shrinking
            isShrinkResources = true         // Removes unused resources
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        named("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
