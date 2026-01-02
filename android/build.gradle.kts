
// Root build script for all subprojects

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    project.afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            
            // Force SDK Version to 35 (Android 15 stable)
            android.compileSdkVersion(35)
            
            if (android.defaultConfig.targetSdkVersion != null && android.defaultConfig.targetSdkVersion!!.apiLevel < 35) {
                android.defaultConfig.targetSdkVersion(35)
            }

            // Force browser 1.8.0 to avoid SDK 36 requirement
            project.configurations.all {
                resolutionStrategy {
                    force("androidx.browser:browser:1.8.0")
                    force("androidx.core:core:1.15.0")
                    force("androidx.core:core-ktx:1.15.0")
                }
            }
            
            // Fix: Inject missing namespace if not specified by reading from AndroidManifest.xml
            if (android.namespace == null) {
                try {
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val manifestXml = manifestFile.readText()
                        val packageMatch = Regex("package=\"([^\"]+)\"").find(manifestXml)
                        if (packageMatch != null) {
                            android.namespace = packageMatch.groupValues[1]
                        }
                    }
                } catch (ignored: Exception) {}
                
                if (android.namespace == null) {
                    android.namespace = "com.leo.remuh.${project.name.replace("-", "_").replace(".", "_")}"
                }
            }
            
            // Fix JVM Target
            android.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_21
                targetCompatibility = JavaVersion.VERSION_21
            }
        }
        
        // Fix Kotlin JVM Target
        project.tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
