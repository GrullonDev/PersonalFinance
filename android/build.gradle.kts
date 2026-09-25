buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Aquí sí puedes declarar classpath
        classpath("com.google.gms:google-services:4.4.2")
    }
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
}

subprojects {
    afterEvaluate {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val namespace = getNamespace.invoke(android) as? String
                if (namespace.isNullOrEmpty()) {
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    val fallbackNamespace = project.group.toString().ifEmpty { "com.example.${project.name.replace("-", ".")}" }
                    setNamespace.invoke(android, fallbackNamespace)
                }
            } catch (e: Exception) {
                // Ignore any namespace reflection errors
            }

            try {
                val buildFeatures = android.javaClass.getMethod("getBuildFeatures").invoke(android)
                val setBuildConfigMethod = buildFeatures.javaClass.methods.firstOrNull { it.name == "setBuildConfig" }
                setBuildConfigMethod?.invoke(buildFeatures, true)
            } catch (e: Exception) {
                // Ignore any buildConfig reflection errors
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    tasks.withType(JavaCompile::class.java).configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }

    tasks.configureEach {
        if (this.javaClass.name.contains("KotlinCompile")) {
            try {
                val kotlinOptions = this.javaClass.getMethod("getKotlinOptions").invoke(this)
                val setJvmTarget = kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java)
                setJvmTarget.invoke(kotlinOptions, "17")
            } catch (e: Exception) {
                // Ignore reflection error
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
