package com.example.mcp.models

/**
 * Task schemas for AI operations provided by the Python Bridge Agent.
 * These schemas define the structure and validation rules for tasks
 * that will be routed to the Python Bridge Agent.
 */
object PythonBridgeTaskSchemas {
    
    /**
     * Task schema for AI-assisted code generation.
     * This task type is used to generate UVC camera integration code
     * based on specified requirements.
     */
    val CodeGenerationTaskSchema = TaskSchema(
        type = "code-generation",
        properties = mapOf(
            "requirements" to PropertySchema(
                type = "string",
                required = true,
                description = "Detailed requirements for the code to be generated"
            ),
            "targetPackage" to PropertySchema(
                type = "string", 
                required = true,
                description = "Package name for the generated code"
            ),
            "cameraType" to PropertySchema(
                type = "string",
                required = true,
                description = "Type of camera (e.g., 'UVC', 'IP', 'RTSP')"
            ),
            "resolution" to PropertySchema(
                type = "string",
                required = false,
                description = "Desired resolution (e.g., '640x480')",
                defaultValue = "640x480"
            ),
            "format" to PropertySchema(
                type = "string",
                required = false,
                description = "Video format (e.g., 'MJPEG', 'YUY2')",
                defaultValue = "MJPEG"
            ),
            "additionalFeatures" to PropertySchema(
                type = "string",
                required = false,
                description = "Additional features to include in the generated code"
            )
        )
    )
    
    /**
     * Task schema for AI-assisted documentation generation.
     * This task type is used to generate technical documentation
     * for provided code or components.
     */
    val DocumentationGenerationTaskSchema = TaskSchema(
        type = "documentation-generation",
        properties = mapOf(
            "code" to PropertySchema(
                type = "string",
                required = true,
                description = "Code to be documented"
            ),
            "targetFormat" to PropertySchema(
                type = "string",
                required = true,
                description = "Format of the generated documentation (e.g., 'markdown', 'javadoc')"
            ),
            "docType" to PropertySchema(
                type = "string",
                required = true,
                description = "Type of documentation (e.g., 'api', 'usage', 'overview')"
            ),
            "includedSections" to PropertySchema(
                type = "string",
                required = false,
                description = "Comma-separated list of sections to include (e.g., 'parameters,examples,return')"
            ),
            "audienceLevel" to PropertySchema(
                type = "string",
                required = false,
                description = "Target audience technical level (e.g., 'beginner', 'advanced')",
                defaultValue = "intermediate"
            )
        )
    )
    
    /**
     * Task schema for UVC camera analysis.
     * This task type is used to analyze UVC camera specifications
     * and provide insights or recommendations.
     */
    val UvcAnalysisTaskSchema = TaskSchema(
        type = "uvc-analysis",
        properties = mapOf(
            "deviceInfo" to PropertySchema(
                type = "string",
                required = true,
                description = "UVC device information to analyze"
            ),
            "analysisType" to PropertySchema(
                type = "string",
                required = true,
                description = "Type of analysis to perform (e.g., 'compatibility', 'performance', 'features')"
            ),
            "targetFramework" to PropertySchema(
                type = "string",
                required = false,
                description = "Target framework for recommendations (e.g., 'android', 'libuvc')",
                defaultValue = "android"
            ),
            "includeCodeExamples" to PropertySchema(
                type = "boolean",
                required = false,
                description = "Whether to include code examples in the analysis",
                defaultValue = "false"
            )
        )
    )
    
    /**
     * Register all Python Bridge task schemas with the main TaskSchemaRegistry.
     * This method should be called during application initialization.
     */
    fun registerSchemas(registry: TaskSchemaRegistry) {
        registry.registerSchema(CodeGenerationTaskSchema)
        registry.registerSchema(DocumentationGenerationTaskSchema)
        registry.registerSchema(UvcAnalysisTaskSchema)
    }
}