plugins {
    kotlin("jvm") version "1.8.10"
    kotlin("plugin.serialization") version "1.8.10"
    application
}

repositories {
    mavenCentral()
}

dependencies {
    // Kotlin standard library and coroutines
    implementation(kotlin("stdlib"))
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4")
    
    // NATS messaging
    implementation("io.nats:jnats:2.16.8")
    
    // Tinder StateMachine for FSM
    implementation("com.tinder.statemachine:statemachine:0.2.0")
    
    // Kotlin serialization
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.5.0")
    
    // Logging
    implementation("org.slf4j:slf4j-api:1.7.36")
    implementation("ch.qos.logback:logback-classic:1.2.11")
    
    // Testing
    testImplementation("org.jetbrains.kotlin:kotlin-test:1.8.10")
    testImplementation("io.mockk:mockk:1.13.4")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.6.4")
    testImplementation("org.junit.jupiter:junit-jupiter:5.9.2")
}

application {
    mainClass.set("com.example.mcp.MainKt")
}

tasks.withType<Test> {
    useJUnitPlatform()
}