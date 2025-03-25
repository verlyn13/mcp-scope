# MCP Common Build Errors and Resolution Guide

## Overview

This document catalogs common errors encountered when building and running the Multi-Agent Control Platform (MCP), along with specific resolution steps. Use this guide in conjunction with the [Build Process Reliability Guide](./build-process-reliability-guide.md) and the verification scripts in the `scripts` directory.

## NATS Server Errors

### Error: NATS Connection Refused
```
nats: connection refused
```

**Cause:** NATS server is not running or the connection URL is incorrect.

**Resolution:**
1. Verify NATS server is running: `ps aux | grep nats-server`
2. Start NATS if needed: `nats-server -c /home/verlyn13/Projects/mcp-scope/mcp-project/nats/nats-server.conf`
3. Check the NATS URL environment variable: `echo $NATS_URL`
4. For containerized environments, ensure the NATS service name is correct in `podman-compose.yml`

### Error: NATS Authorization Error
```
nats: authorization violation
```

**Cause:** Missing or incorrect credentials when connecting to a secure NATS server.

**Resolution:**
1. Check NATS server configuration for authentication settings
2. Verify credentials are provided in component environment variables
3. Update `.env` files with correct credentials
4. For containerized environments, update environment variables in `podman-compose.yml`

## Gradle Build Errors

### Error: Gradle Wrapper Not Found
```
-bash: ./gradlew: No such file or directory
```

**Cause:** Gradle wrapper files are missing.

**Resolution:**
1. Navigate to the project directory: `cd /home/verlyn13/Projects/mcp-scope/mcp-project/mcp-core`
2. Generate the Gradle wrapper: `gradle wrapper --gradle-version 8.3`
3. Make the wrapper executable: `chmod +x ./gradlew`

### Error: Kotlin Compilation Error
```
e: /home/verlyn13/Projects/mcp-scope/mcp-project/mcp-core/src/main/kotlin/com/example/mcp/Main.kt: (12, 43): Unresolved reference: NatsConnection
```

**Cause:** Missing import or dependency.

**Resolution:**
1. Check for missing imports in the file
2. Verify the dependency is included in `build.gradle.kts`
3. Run `./gradlew --refresh-dependencies` to update dependencies
4. Check for typos in class or package names

### Error: Multiple Kotlin Versions
```
w: Runtime JAR files in the classpath have the same version (1.8.10) as the Kotlin compiler, but differ in build number
```

**Cause:** Inconsistent Kotlin versions between compiler and runtime.

**Resolution:**
1. Align Kotlin versions in all `build.gradle.kts` files:
   ```kotlin
   plugins {
       kotlin("jvm") version "1.8.10"
   }
   ```
2. Check the root project's `build.gradle.kts` for version declarations
3. Run `./gradlew clean` before rebuilding

## JVM Runtime Errors

### Error: ClassNotFoundException
```
Exception in thread "main" java.lang.ClassNotFoundException: com.example.mcp.MainKt
```

**Cause:** Class not found in the classpath or main class incorrectly specified.

**Resolution:**
1. Verify the main class name in `build.gradle.kts`:
   ```kotlin
   application {
       mainClass.set("com.example.mcp.MainKt")
   }
   ```
2. Check package structure matches the expected path
3. Try cleaning and rebuilding: `./gradlew clean build`

### Error: UnsatisfiedLinkError
```
Exception in thread "main" java.lang.UnsatisfiedLinkError: no usb4java-1.3.0 in java.library.path
```

**Cause:** Native library not found for JNI components (especially in Camera Agent).

**Resolution:**
1. Install required native libraries: `sudo apt-get install libusb-1.0-0 libusb-1.0-0-dev`
2. Verify library path is set correctly:
   ```bash
   export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
   ```
3. For containerized environments, make sure necessary libraries are included in the Dockerfile

### Error: OutOfMemoryError
```
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
```

**Cause:** Insufficient memory allocated to the JVM.

**Resolution:**
1. Increase JVM heap size:
   ```bash
   export JAVA_OPTS="-Xmx2g -Xms512m"
   ```
2. In `build.gradle.kts`, add:
   ```kotlin
   application {
       applicationDefaultJvmArgs = listOf("-Xmx2g", "-Xms512m")
   }
   ```
3. For containers, increase memory limits in `podman-compose.yml`

## Python Environment Errors

### Error: ModuleNotFoundError
```
ModuleNotFoundError: No module named 'nats'
```

**Cause:** Missing Python dependency.

**Resolution:**
1. Ensure virtual environment is activated: `source venv/bin/activate`
2. Install the missing package: `pip install nats-py`
3. Update requirements.txt: `pip freeze > requirements.txt`
4. Reinstall all dependencies: `pip install -r requirements.txt`

### Error: SyntaxError
```
SyntaxError: invalid syntax
```

**Cause:** Python syntax error or incompatible Python version.

**Resolution:**
1. Check Python version: `python --version`
2. Ensure Python 3.11+ is used (per project requirements)
3. Fix syntax errors in the identified file
4. If using virtual environment, recreate it with the correct Python version:
   ```bash
   rm -rf venv
   python3.11 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

### Error: RuntimeError with asyncio
```
RuntimeError: This event loop is already running
```

**Cause:** Incorrect asyncio usage in Python agent.

**Resolution:**
1. Check for nested event loops
2. Ensure correct usage of `asyncio.run()` (should be called only once)
3. Use `await` instead of blocking calls inside async functions
4. Structure code with proper coroutine patterns

## Container Errors

### Error: Container Failed to Start
```
Error: error creating container storage: the container name "mcp-core" is already in use
```

**Cause:** Container name conflict.

**Resolution:**
1. Remove existing container: `podman rm mcp-core`
2. If container is running: `podman stop mcp-core && podman rm mcp-core`
3. Clean up all containers: `podman-compose down`
4. Remove orphaned containers: `podman ps -a | grep "Exited" | awk '{print $1}' | xargs podman rm`

### Error: Container Build Failure
```
error building at STEP "RUN apt-get update": error while running runtime: exit status 100
```

**Cause:** Network or repository issues during container build.

**Resolution:**
1. Check network connectivity
2. Try with an alternative mirror: `RUN echo "deb mirror://mirrors.ubuntu.com/mirrors.txt focal main restricted universe multiverse" > /etc/apt/sources.list`
3. Add retry logic to Dockerfile:
   ```Dockerfile
   RUN apt-get update || (sleep 5 && apt-get update)
   ```
4. Build with no-cache to refresh packages: `podman-compose build --no-cache`

### Error: Volume Mount Issues
```
Error: error mounting "/home/user/Projects/mcp-project/mcp-core" on "/app"
```

**Cause:** Permission issues with mounted volumes.

**Resolution:**
1. Check file permissions: `ls -la /home/verlyn13/Projects/mcp-scope/mcp-project/mcp-core`
2. Fix permissions: `sudo chown -R $(id -u):$(id -g) /home/verlyn13/Projects/mcp-scope/mcp-project/mcp-core`
3. Try running with privileged mode (for debugging): `podman run --privileged`
4. Check SELinux context if using a system with SELinux enabled

## USB Device Errors

### Error: Device Access Permission Denied
```
libusb: error [_get_usbfs_fd] libusb couldn't open USB device /dev/bus/usb/001/003: Permission denied
```

**Cause:** Insufficient permissions to access USB devices.

**Resolution:**
1. Add your user to the plugdev group: `sudo usermod -aG plugdev $USER`
2. Create a udev rule for the device:
   ```bash
   echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="0123", ATTRS{idProduct}=="4567", MODE="0666"' | sudo tee /etc/udev/rules.d/99-camera.rules
   ```
3. Reload udev rules: `sudo udevadm control --reload-rules && sudo udevadm trigger`
4. For containerized environments, ensure proper device mounting in `podman-compose.yml`:
   ```yaml
   devices:
     - /dev/bus/usb:/dev/bus/usb
   ```

### Error: USB Device Not Found
```
UsbException: USB device not found
```

**Cause:** USB device not connected or not detected.

**Resolution:**
1. Check if device is connected: `lsusb`
2. Try different USB port
3. Enable mock mode for testing: `export MOCK_USB=true`
4. For containerized environments, check if USB devices are properly passed through:
   ```bash
   podman exec -it camera-agent lsusb
   ```

## Integration Errors

### Error: Component Communication Failure
```
Exception: Failed to deliver message: No response received within timeout
```

**Cause:** Components unable to communicate through NATS.

**Resolution:**
1. Ensure all components are running
2. Verify NATS is accessible to all components
3. Check for consistent subject naming conventions
4. Test NATS messaging manually:
   ```bash
   nats pub test.subject "Hello" --server=nats://localhost:4222
   nats sub test.subject --server=nats://localhost:4222
   ```

### Error: Inconsistent Environment Variables
```
Exception: NATS connection failed with URI [nats://localhost:4222]
```

**Cause:** Inconsistent environment variables between components.

**Resolution:**
1. Check `.env` files in each component directory
2. Ensure consistent NATS_URL across all components
3. For containerized environments, check environment variables in `podman-compose.yml`
4. Create a shared environment file for local development

## Logging and Monitoring Errors

### Error: Logback Configuration
```
no appenders could be found for logger
```

**Cause:** Missing or incorrect logback.xml configuration.

**Resolution:**
1. Verify `logback.xml` exists in resources directory
2. Check for syntax errors in `logback.xml`
3. Set default log level:
   ```xml
   <root level="INFO">
       <appender-ref ref="STDOUT" />
   </root>
   ```
4. Ensure SLF4J binding is in the classpath:
   ```kotlin
   implementation("ch.qos.logback:logback-classic:1.4.11")
   ```

### Error: Invalid Log Level
```
log4j:ERROR Could not parse level value: "TRACE"
```

**Cause:** Invalid log level configuration.

**Resolution:**
1. Check environment variable: `echo $LOG_LEVEL`
2. Use valid log levels: TRACE, DEBUG, INFO, WARN, ERROR
3. Update configuration to handle invalid levels:
   ```kotlin
   val level = try {
       Level.valueOf(System.getenv("LOG_LEVEL") ?: "INFO")
   } catch (e: Exception) {
       Level.INFO
   }
   ```

## Build Script Errors

### Error: Verification Script Permission Denied
```
bash: ./scripts/verify-nats.sh: Permission denied
```

**Cause:** Script files not executable.

**Resolution:**
1. Make scripts executable: `chmod +x ./scripts/*.sh`
2. Use the setup script: `./scripts/setup-verification-tools.sh`

### Error: Script Path Error
```
./scripts/verify-nats.sh: line 12: /home/verlyn13/Projects/mcp-scope/mcp-project/nats/nats-server.conf: No such file or directory
```

**Cause:** Incorrect paths in scripts.

**Resolution:**
1. Verify the script is being run from the project root directory
2. Update paths in scripts to use relative paths when possible
3. Use environment variables for flexible path configuration

## Common Error Resolution Workflow

For any error encountered during the build process:

1. **Identify the error category** from this guide
2. **Check component logs** for specific error messages
3. **Verify prerequisites** are installed and properly configured
4. **Run the appropriate verification script** for the component
5. **Apply the specific resolution** from this guide
6. **Re-run verification** to confirm the issue is resolved

## Preventative Measures

To avoid common build errors:

1. **Use the verification scripts** before committing changes
2. **Standardize environment variables** across all components
3. **Document any system dependencies** in the project README
4. **Maintain consistent versions** of key dependencies (Kotlin, JDK, etc.)
5. **Run integration tests** before deploying changes
6. **Use containerized environment** for consistent builds

## References

- [Build Process Reliability Guide](./build-process-reliability-guide.md)
- [Environment Setup Guide](../environment-setup.md)
- [Local Development Guide](../local-development-guide.md)
- [Containerized Development Guide](../containerized-development-guide.md)