import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file(
    System.getenv("TRUEDOCK_ANDROID_KEY_PROPERTIES")
        ?.trim()
        ?.takeIf(String::isNotEmpty)
        ?: "key.properties",
)
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.isFile) {
        keystorePropertiesFile.inputStream().use(::load)
    }
}

val releaseBuildRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

fun signingProperty(name: String): String? =
    keystoreProperties.getProperty(name)?.trim()?.takeIf(String::isNotEmpty)

fun resolveStoreFile(path: String): File {
    val expandedPath = when {
        path == "~" -> System.getProperty("user.home")
        path.startsWith("~/") -> System.getProperty("user.home") + path.removePrefix("~")
        else -> path
    }
    return file(expandedPath)
}

if (releaseBuildRequested) {
    if (!keystorePropertiesFile.isFile) {
        throw GradleException(
            "Missing Android signing properties: $keystorePropertiesFile",
        )
    }
    val missingProperties = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        .filter { signingProperty(it) == null }
    if (missingProperties.isNotEmpty()) {
        throw GradleException(
            "Incomplete android/key.properties. Missing: ${missingProperties.joinToString()}",
        )
    }
    val configuredStoreFile = resolveStoreFile(signingProperty("storeFile")!!)
    if (!configuredStoreFile.isFile) {
        throw GradleException("Android signing keystore was not found: $configuredStoreFile")
    }
}

android {
    namespace = "me.aroxu.truedock"
    // flutter_secure_storage 11 requires API 37 at compile time. This does not
    // change targetSdk or the minimum Android version supported by TrueDock.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "me.aroxu.truedock"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            signingProperty("storeFile")?.let { storeFile = resolveStoreFile(it) }
            storePassword = signingProperty("storePassword")
            keyAlias = signingProperty("keyAlias")
            keyPassword = signingProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
