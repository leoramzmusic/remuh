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

    // Workaround for "Namespace not specified" error in some Flutter plugins
    project.afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            
            // Fix SDK Version (Safely update if needed)
            
            // Fix SDK Version (Safely update if needed)
            if (android.compileSdkVersion != null && android.compileSdkVersion!!.contains("35").not()) {
                // Only upgrade if it's lower? Actually, let's just let plugins use what they define
                // unless it's known to be too low.
                // For now, let's REMOVE the force to resolve the BAKLAVA error.
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
                } catch (ignored: Exception) {
                }
                
                // Fallback if still null or if reading failed
                if (android.namespace == null) {
                    android.namespace = "com.leo.remuh.${project.name.replace("-", "_").replace(".", "_")}"
                }
            }
            
            // Fix JVM Target (Force Java 17)
            android.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
        
        // Fix Kotlin JVM Target
        project.tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
