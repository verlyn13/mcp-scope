plugins {
    base
    kotlin("jvm") version "1.8.10" apply false
}

allprojects {
    group = "com.example"
    version = "0.1.0"
    
    repositories {
        mavenCentral()
    }
}