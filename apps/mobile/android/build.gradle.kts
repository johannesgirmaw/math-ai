allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Kotlin 2.3 rejects the languageVersion 1.6 still set by sentry_flutter 8,
// and that plugin still compiles against Android 34.
subprojects {
    plugins.withId("kotlin-android") {
        tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
            compilerOptions {
                languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
                apiVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
            }
        }
    }
    val bumpSdk = {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.compileSdkVersion(36)
    }
    if (state.executed) {
        bumpSdk()
    } else {
        afterEvaluate { bumpSdk() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
