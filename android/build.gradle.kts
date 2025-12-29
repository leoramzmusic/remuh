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
            
            // Fix Namespace
            if (android.namespace == null) {
                android.namespace = "com.lucasjosino.on_audio_query"
            }
            
            // Fix SDK Version (Safely update if needed)
            if (android.compileSdkVersion != null && android.compileSdkVersion!!.contains("35").not()) {
                // Only upgrade if it's lower? Actually, let's just let plugins use what they define
                // unless it's known to be too low.
                // For now, let's REMOVE the force to resolve the BAKLAVA error.
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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
