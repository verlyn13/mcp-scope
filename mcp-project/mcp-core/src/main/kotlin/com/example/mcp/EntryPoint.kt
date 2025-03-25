package com.example.mcp

import com.example.mcp.server.ServerMain

/**
 * New entry point for the MCP application.
 * 
 * This provides a more modern server implementation with enhanced
 * features over the original Main class. This implementation uses
 * the McpServer and associated components for a more modular design.
 * 
 * For backward compatibility, the original Main class is still available.
 */
object EntryPoint {
    
    /**
     * Main entry point that delegates to the ServerMain implementation.
     */
    @JvmStatic
    fun main(args: Array<String>) {
        // Delegate to the server main implementation
        ServerMain.main(args)
    }
}