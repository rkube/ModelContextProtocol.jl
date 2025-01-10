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

Create and configure an MCP server with the given components.
"""
function mcp_server(;
    name::String,
    version::String = "1.0.0", 
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