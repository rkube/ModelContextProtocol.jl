__precompile__(false)

module ModelContextProtocol

using JSON3
using URIs
using DataStructures
using Logging
using Dates
using StructTypes


# First include protocol types as they define fundamental types
include("protocol/messages.jl")

# Then include core types that might depend on protocol types
include("types.jl")

# Then include implementations
include("capabilities.jl")
include("protocol/jsonrpc.jl")
include("protocol/handlers.jl")
include("server.jl")

# Finally include utilities
include("utils/logging.jl")

# Export all public interfaces
export 
    # Main Server Call
    mcp_server,

    # Core types
    Server, ServerConfig,
    Tool, Resource, Capability,
    ToolParameter, MCPTool, MCPResource, 
    Content, TextContent, ImageContent,
    
    # Prompt types
    PromptArgument, MCPPrompt, PromptMessage,
    ListPromptsParams, GetPromptParams,
    ListPromptsResult, GetPromptResult,
    
    # Server operations
    start!, stop!, register!,
    
    # Capabilities
    ResourceCapability, ToolCapability, PromptCapability,
    
    # Server management
    subscribe!, unsubscribe!,
    
    # Protocol types
    MCPMessage, Request, Response, Notification,
    RequestParams, ResponseResult, ErrorInfo,
    RequestId,  # Make sure this is included in exports
    
    # Protocol functions
    parse_message, serialize_message,
    
    # Utils
    MCPLogger, init_logging,

    # Handlers
    HandlerResult, RequestContext,

    # Export JSONRPCError
    JSONRPCError

end # module