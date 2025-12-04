plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ✅ Moved here
}

android {
    namespace = "com.example.aether"
    compileSdk = 36 // ✅ Explicitly set compileSdkVersion
    ndkVersion = "27.0.12077973"  // ✅ Fix NDK version mismatch

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.aether"
        minSdkVersion(26)  // ✅ Ensure this is 23
        targetSdkVersion(35) // ✅ Explicitly set target SDK
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
