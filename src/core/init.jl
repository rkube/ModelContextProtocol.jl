# src/core/init.jl

"""
    default_capabilities() -> Vector{Capability}

Return the default set of server capabilities.
"""
function default_capabilities()
    [
        ResourceCapability(list_changed=true, subscribe=true),
        ToolCapability(list_changed=true),
        PromptCapability(list_changed=true)  # Added prompt capability
    ]
end

"""
    mcp_server(; name, version="1.0.0", tools=nothing, resources=nothing, prompts=nothing, description="") -> Server

Primary entry point for creating and configuring a Model Context Protocol (MCP) server. The server acts as a host for tools, 
resources, and prompts that can be accessed by MCP-compatible language models like Claude.

# Arguments
- `name::String`: Unique identifier for the server instance 
- `version::String="2024-11-05"`: Server implementation version
- `tools::Union{Vector{MCPTool}, MCPTool, Nothing}=nothing`: Tools to expose to the model
- `resources::Union{Vector{MCPResource}, MCPResource, Nothing}=nothing`: Resources available to the model
- `prompts::Union{Vector{MCPPrompt}, MCPPrompt, Nothing}=nothing`: Predefined prompts for the model
- `description::String=""`: Optional server description
- `capabilities::Vector{Capability}=default_capabilities()`: Server capability configuration

# Example
```julia
server = mcp_server(
    name = "my-server",
    description = "Demo server with time tool",
    tools = MCPTool(
        name = "get_time",
        description = "Get current time. Uses MCP server computer clock",
        parameters = [],
        handler = args -> Dates.format(now(), args["format"])
    )
)
start!(server)
```

Returns a configured `Server` instance ready to handle MCP client connections.

See also: [`MCPTool`](@ref), [`MCPResource`](@ref), [`MCPPrompt`](@ref)
"""
function mcp_server(;
    name::String,
    version::String = "2024-11-05", 
    tools::Union{Vector{MCPTool}, MCPTool, Nothing} = nothing,
    resources::Union{Vector{MCPResource}, MCPResource, Nothing} = nothing,
    prompts::Union{Vector{MCPPrompt}, MCPPrompt, Nothing} = nothing,  # Added prompts parameter
    description::String = "",
    capabilities::Vector{Capability} = default_capabilities()
)
    # Create server config
    config = ServerConfig(
        name = name,
        version = version,
        description = description,
        capabilities = capabilities
    )
    
    # Create server
    server = Server(config)
    
    # Register tools if provided
    if !isnothing(tools)
        foreach(t -> register!(server, t), tools isa Vector ? tools : [tools])
    end
    
    # Register resources if provided
    if !isnothing(resources)
        foreach(r -> register!(server, r), resources isa Vector ? resources : [resources])
    end
    
    # Register prompts if provided
    if !isnothing(prompts)
        foreach(p -> register!(server, p), prompts isa Vector ? prompts : [prompts])
    end
    
    return server
end