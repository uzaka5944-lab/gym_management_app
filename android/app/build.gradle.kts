import com.android.build.gradle.internal.cxx.configure.gradleLocalProperties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.gymmanagement.app"
    compileSdk = 34 // Use specific version instead of flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.gymmanagement.app"
        minSdk = 21 // Use specific version instead of flutter.minSdkVersion
        targetSdk = 34 // Use specific version instead of flutter.targetSdkVersion
        versionCode = 1 // Hardcode version code
        versionName = "1.0.0" // Hardcode version name
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.0") // Hardcoded Kotlin version
}
