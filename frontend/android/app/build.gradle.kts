android {
    namespace = "com.example.transact_point"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.transact_point"
        minSdk = 21
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = "transact_point_key"
            keyPassword = "Skubunch65@&"
            storeFile = file("transact_point.keystore")
            storePassword = "Skubunch65@&"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false

            // ✅ Split only for release builds
            // splits {
            //     abi {
            //         isEnable = true
            //         reset()
            //         include("armeabi-v7a", "arm64-v8a", "x86", "x86_64")
            //         isUniversalApk = false
            //     }
            // }
        }

        debug {
            signingConfig = signingConfigs.getByName("debug")

            // ✅ Ensure debug produces one universal APK
            splits {
                abi {
                    isEnable = false
                }
            }
        }
    }

    packagingOptions {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/NOTICE",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE.txt"
            )
        }
    }
}
