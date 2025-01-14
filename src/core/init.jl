# src/core/init.jl

"""
    normalize_path(path::String) -> String

Normalize a path to absolute form, handling both relative and absolute paths.
"""
function normalize_path(path::String)
    if isnothing(path)
        return nothing
    end
    
    # Convert to absolute path
    if !isabspath(path)
        # Relative paths should be relative to project root
        path = joinpath(dirname(dirname(@__DIR__)), path)
    end
    
    # Normalize the path (resolve .., ., and symlinks)
    return abspath(path)
end

"""
Scan directory for MCP components and return found definitions
"""
function scan_mcp_components(dir::String)
    components = Dict(
        :tools => MCPTool[],
        :resources => MCPResource[],
        :prompts => MCPPrompt[]
    )
    
    for (root, _, files) in walkdir(dir)
        for file in files
            endswith(file, ".jl") || continue
            
            path = joinpath(root, file)
            module_name = Symbol("TempModule_", hash(path))
            
            try
                # Create temporary module to evaluate file
                eval(Meta.parse("module $(module_name) using ModelContextProtocol; include(\"$path\") end"))
                
                # Extract components
                mod = getfield(Main, module_name)
                for name in names(mod, all=true)
                    obj = getfield(mod, name)
                    if obj isa MCPTool
                        push!(components[:tools], obj)
                    elseif obj isa MCPResource
                        push!(components[:resources], obj)
                    elseif obj isa MCPPrompt
                        push!(components[:prompts], obj)
                    end
                end
            catch e
                @warn "Error processing $path: $e"
            end
        end
    end
    return components
end

# src/core/server.jl

"""
    auto_register!(server::Server, dir::AbstractString)

Automatically register components found in the specified directory.
The directory structure should be:
- dir/tools/        # Contains tool definitions
- dir/resources/    # Contains resource definitions
- dir/prompts/      # Contains prompt definitions

Each subdirectory is optional. Files are expected to be .jl files that export
component definitions.
"""
# src/core/server.jl

function auto_register!(server::Server, dir::AbstractString)
    component_dirs = [
        ("tools", MCPTool),
        ("resources", MCPResource),
        ("prompts", MCPPrompt)
    ]
    
    for (subdir, type) in component_dirs
        component_dir = joinpath(dir, subdir)
        if isdir(component_dir)
            for file in readdir(component_dir, join=true)
                if endswith(file, ".jl")
                    try
                        # Create a new module with ModelContextProtocol already imported
                        mod = Module()
                        Core.eval(mod, :(using ModelContextProtocol))
                        
                        # Simply include the file in this module's namespace
                        Base.include(mod, file)
                        
                        # Look for ANY variables that are of our target type
                        # No need for exports!
                        for name in names(mod, all=true)
                            if isdefined(mod, name)
                                component = getfield(mod, name)
                                if component isa type
                                    register!(server, component)
                                    @info "Registered $type from $file: $name"
                                end
                            end
                        end
                    catch e
                        @warn "Error processing $file" exception=e stack=stacktrace(catch_backtrace())
                    end
                end
            end
        end
    end
    
    return server
end


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
    mcp_server(; name, version="1.0.0", tools=nothing, resources=nothing, prompts=nothing, description="", auto_register_dir=nothing) -> Server

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
- `auto_register_dir::Union{String, Nothing}=nothing`: Directory to auto-register components from

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
    ),
    auto_register_dir = "path/to/components"
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
    capabilities::Vector{Capability} = default_capabilities(),
    auto_register_dir::Union{String, Nothing} = nothing  # Added auto_register_dir parameter
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
    
    # Auto-register components if directory provided
    if !isnothing(auto_register_dir)
        normalized_path = normalize_path(auto_register_dir)
        @info "Auto-registering components from $normalized_path"
        auto_register!(server, normalized_path)
    end
    
    return server
end