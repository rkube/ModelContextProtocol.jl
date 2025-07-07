module ModelContextProtocol

using JSON3, URIs, DataStructures, OrderedCollections, Logging, Dates, StructTypes, MacroTools, Base64

# 1. Foundation
include("core/types.jl")

# 2. Features
include("features/tools.jl")
include("features/resources.jl") 
include("features/prompts.jl")

# 3. Protocol Types
include("protocol/messages.jl")

# 4. Server Types
include("core/server_types.jl")  

# 5. Utils
include("utils/errors.jl")
include("utils/logging.jl")

# 6. Implementation
include("protocol/jsonrpc.jl")
include("core/capabilities.jl")
include("core/server.jl")
include("core/init.jl")
include("protocol/handlers.jl")

# 7. Serialization (needs all types)
include("utils/serialization.jl")

# Export all public interfaces
export 

    # Primary interface function 
    mcp_server,
    
    # Core types & enums
    Role, RequestId, ProgressToken,
    MCPMessage, Request, Response, Notification,
    RequestParams, ResponseResult,
    Content, ResourceContents,
    TextContent, ImageContent, TextResourceContents, BlobResourceContents,
    EmbeddedResource,

    # Server types
    Server, ServerConfig,
    Tool, Resource, Capability,
    
    # Feature types
    ToolParameter, MCPTool, MCPResource, 
    ResourceTemplate,
    
    # Prompt types
    PromptArgument, MCPPrompt, PromptMessage,
    
    # Server operations
    start!, stop!, register!,
    
    # Capabilities
    ResourceCapability, ToolCapability, PromptCapability,
    
    # Server management
    subscribe!, unsubscribe!,
    
    # Protocol message types
    RequestMeta, ClientCapabilities, Implementation,
    InitializeParams, InitializeResult,
    ListResourcesParams, ListResourcesResult,
    ReadResourceParams, ReadResourceResult,
    ListToolsParams, ListToolsResult,
    CallToolParams, CallToolResult,
    ListPromptsParams, ListPromptsResult,
    GetPromptParams, GetPromptResult,
    ProgressParams, ErrorInfo,
    JSONRPCRequest, JSONRPCResponse, JSONRPCError, JSONRPCNotification,
    
    # Protocol functions
    parse_message, serialize_message,
    
    # Utils
    MCPLogger, init_logging,
    ErrorCodes,  # Export error codes module
    content2dict,  # Export content serialization function

    # Handlers
    HandlerResult, RequestContext

end # module