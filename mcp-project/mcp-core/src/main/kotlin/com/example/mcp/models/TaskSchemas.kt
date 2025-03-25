package com.example.mcp.models

/**
 * Task schema definitions for MCP Core.
 *
 * This file contains schema definitions for all task types supported by the MCP platform.
 * Each schema defines the required and optional properties for a specific task type.
 */

/**
 * Property schema for task parameters.
 *
 * @property type The data type of the property (string, number, boolean, etc.)
 * @property required Whether this property is required for the task
 * @property description Optional description of the property
 * @property enumValues Optional list of allowed values for this property
 */
data class PropertySchema(
    val type: String,
    val required: Boolean = false,
    val description: String? = null,
    val enumValues: List<String>? = null
)

/**
 * Task schema defining the structure and validation rules for a task type.
 *
 * @property type The task type identifier
 * @property properties Map of property names to their schemas
 * @property description Optional description of the task type
 */
data class TaskSchema(
    val type: String,
    val properties: Map<String, PropertySchema>,
    val description: String? = null
)

/**
 * Collection of task schemas supported by the MCP platform.
 */
object TaskSchemas {

    /**
     * UVC Camera task schema for camera control operations.
     */
    val UvcCameraTaskSchema = TaskSchema(
        type = "uvc-camera",
        properties = mapOf(
            "operation" to PropertySchema(type = "string", required = true),
            "deviceId" to PropertySchema(type = "string", required = true),
            "parameters" to PropertySchema(type = "object", required = false)
        ),
        description = "Task for controlling UVC cameras"
    )

    /**
     * Data analysis task schema for processing captured data.
     */
    val DataAnalysisTaskSchema = TaskSchema(
        type = "data-analysis",
        properties = mapOf(
            "dataSource" to PropertySchema(type = "string", required = true),
            "analysisType" to PropertySchema(type = "string", required = true),
            "parameters" to PropertySchema(type = "object", required = false)
        ),
        description = "Task for analyzing captured data"
    )

    /**
     * Code generation task schema for AI-powered code generation.
     */
    val CodeGenerationTaskSchema = TaskSchema(
        type = "code-generation",
        properties = mapOf(
            "requirements" to PropertySchema(type = "string", required = true),
            "targetPackage" to PropertySchema(type = "string", required = true),
            "cameraType" to PropertySchema(type = "string", required = true)
        ),
        description = "Task for generating camera integration code"
    )

    /**
     * Documentation generation task schema for AI-powered documentation generation.
     */
    val DocumentationGenerationTaskSchema = TaskSchema(
        type = "documentation-generation",
        properties = mapOf(
            "code" to PropertySchema(type = "string", required = true),
            "targetFormat" to PropertySchema(type = "string", required = true),
            "docType" to PropertySchema(type = "string", required = true)
        ),
        description = "Task for generating code documentation"
    )

    /**
     * Map of all supported task schemas by type.
     */
    val allSchemas = mapOf(
        "uvc-camera" to UvcCameraTaskSchema,
        "data-analysis" to DataAnalysisTaskSchema,
        "code-generation" to CodeGenerationTaskSchema,
        "documentation-generation" to DocumentationGenerationTaskSchema
    )

    /**
     * Validates a task against its schema.
     *
     * @param task The task to validate
     * @return List of validation errors, empty if task is valid
     */
    fun validateTask(task: Task): List<String> {
        val errors = mutableListOf<String>()
        val taskType = task.type
        val schema = allSchemas[taskType]

        if (schema == null) {
            errors.add("Unknown task type: $taskType")
            return errors
        }

        // Validate required properties
        schema.properties.forEach { (propName, propSchema) ->
            if (propSchema.required && !task.parameters.containsKey(propName)) {
                errors.add("Missing required property: $propName")
            }
        }

        // Validate property types and enum values
        task.parameters.forEach { (propName, propValue) ->
            val propSchema = schema.properties[propName]
            if (propSchema != null) {
                // Type validation would go here in a real implementation
                // This is simplified for example purposes

                // Enum validation
                propSchema.enumValues?.let { enumValues ->
                    if (propValue is String && !enumValues.contains(propValue)) {
                        errors.add("Invalid value for $propName: $propValue. Allowed values: ${enumValues.joinToString()}")
                    }
                }
            } else {
                // Unknown property, ignore for now
            }
        }

        return errors
    }
}