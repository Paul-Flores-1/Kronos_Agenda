buildscript {
    extra.set("kotlin_version", "2.1.0")
    repositories {
        google()
        mavenCentral()
        // Agregar repositorio de Huawei
        maven("https://developer.huawei.com/repo/")
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.11.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
        classpath("com.google.gms:google-services:4.4.2")
        // Agregar el SDK de Huawei (Versión moderna para Gradle 8+)
        classpath("com.huawei.agconnect:agcp:1.9.1.301")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        // Agregar repositorio de Huawei
        maven("https://developer.huawei.com/repo/")
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}