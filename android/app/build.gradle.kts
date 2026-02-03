plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.frontend_flutter_main"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.olvora.expense"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Enable vector drawable support for older devices
        vectorDrawables.useSupportLibrary = true
    }

    // Split APKs by ABI for smaller downloads
    // Note: Disable when building AAB (App Bundle handles this automatically)
    splits {
        abi {
            // Enable only for APK builds, not App Bundle
            isEnable = project.hasProperty("splitApks") || gradle.startParameter.taskNames.any { it.contains("assemble") }
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            isUniversalApk = true // Also generate a universal APK
        }
    }

    buildTypes {
        debug {
            // Debug settings
            isMinifyEnabled = false
            isShrinkResources = false
        }
        
        release {
            // Enable R8 code shrinking
            isMinifyEnabled = true
            
            // Enable resource shrinking (removes unused resources)
            isShrinkResources = true
            
            // Use ProGuard rules
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Strip debug symbols for smaller APK
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
            
            // Signing config (replace with your release keystore)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    
    // Optimize packaging
    packaging {
        resources {
            excludes += listOf(
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE.txt",
                "META-INF/*.kotlin_module",
                "META-INF/AL2.0",
                "META-INF/LGPL2.1",
                "DebugProbesKt.bin"
            )
        }
        
        // Strip debug symbols from native libraries
        jniLibs {
            useLegacyPackaging = false
        }
    }
    
    // Lint options
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
