import com.android.build.api.variant.LibraryAndroidComponentsExtension

plugins {
    id("com.android.application") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    val needsJava17 = name in setOf(
        "flutter_inappwebview_android",
        "flutter_local_notifications"
    )

    // Apply defaults without reading AGP's not-yet-finalized Java properties.
    plugins.withId("com.android.library") {
        extensions.configure<LibraryAndroidComponentsExtension> {
            finalizeDsl { android ->
                // Native dependencies require Android API 36. Align older
                // library defaults without changing their minSdk or targetSdk.
                android.compileSdk = 36
                if (needsJava17) {
                    android.compileOptions.sourceCompatibility = JavaVersion.VERSION_17
                    android.compileOptions.targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
