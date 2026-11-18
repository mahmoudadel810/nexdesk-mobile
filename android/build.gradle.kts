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

// Release builds run lint on every module. Lint crashes while reading the Java sources of some Flutter plugins
// (image_picker_android, firebase_core: "Unexpected failure during lint analysis"), a bug in lint, not in
// this app. Plugins are not our code to fix, so their release lint is skipped; the app module keeps it.
subprojects {
    if (name != "app" && name != "gradle") {
        tasks.matching { it.name.startsWith("lintVital") }.configureEach { enabled = false }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
