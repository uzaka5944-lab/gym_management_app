import com.android.build.gradle.internal.cxx.configure.gradleLocalProperties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.gymmanagement.app"
    compileSdk = 34 // Use specific compileSdk version

    defaultConfig {
        applicationId = "com.gymmanagement.app"
        minSdk = 21 // Use specific minSdk version
        targetSdk = 34 // Use specific targetSdk version
        versionCode = 1 // Hardcoded version code
        versionName = "1.0.0" // Hardcoded version name
    }

    buildTypes {
        release {
            isMinifyEnabled = true          // Enable code shrinking (required for resource shrinking)
            isShrinkResources = true        // Enable resource shrinking
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
