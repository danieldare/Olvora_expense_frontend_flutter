import org.gradle.api.tasks.compile.JavaCompile

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
    
    // Fix for packages without namespace (e.g., isar_flutter_libs)
    afterEvaluate {
        // Set namespace for library projects that don't have one
        extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
            if (namespace == null) {
                // Try to read namespace from AndroidManifest.xml
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val manifestContent = manifestFile.readText()
                    val packageMatch = Regex("package=\"([^\"]+)\"").find(manifestContent)
                    if (packageMatch != null) {
                        namespace = packageMatch.groupValues[1]
                    }
                }
                // Fallback: set namespace based on project name
                if (namespace == null && project.name == "isar_flutter_libs") {
                    namespace = "dev.isar.isar_flutter_libs"
                }
            }
        }
        
        // Configure Java compilation
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }
        
        // Configure Kotlin compilation using new compilerOptions DSL
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
        
        // Configure Android compile options if Android plugin is applied
        extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
            compileSdkVersion(36)
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
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
