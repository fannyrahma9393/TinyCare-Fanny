allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Firebase Google Services Gradle plugin (for generating Firebase config from
// google-services.json). Applied conditionally so the build still works before
// the file is provided from the Firebase Console. Once you drop google-services.json
// into android/app/, this plugin activates automatically — no code change needed.
buildscript {
    dependencies {
        if (file("app/google-services.json").exists()) {
            classpath("com.google.gms:google-services:4.4.2")
        }
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
