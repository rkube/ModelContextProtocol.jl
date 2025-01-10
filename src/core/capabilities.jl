# src/core/capabilities.jl

"""
Capability for resource-related features
"""
Base.@kwdef struct ResourceCapability <: Capability
    list_changed::Bool = false
    subscribe::Bool = false
end

"""
Capability for tool-related features
"""
Base.@kwdef struct ToolCapability <: Capability
    list_changed::Bool = false
end

"""
Capability for prompt-related features
"""
Base.@kwdef struct PromptCapability <: Capability
    list_changed::Bool = false
end

"""
Capability for logging features
"""
Base.@kwdef struct LoggingCapability <: Capability
    levels::Vector{String} = ["info", "warn", "error"]
end

"""
Converts capabilities to the format expected by the MCP protocol
"""
function to_protocol_format(cap::ResourceCapability)
    Dict{String,Any}(
        "listChanged" => cap.list_changed,
        "subscribe" => cap.subscribe
    )
end

function to_protocol_format(cap::ToolCapability)
    Dict{String,Any}(
        "listChanged" => cap.list_changed
    )
end

function to_protocol_format(cap::PromptCapability)
    Dict{String,Any}(
        "listChanged" => cap.list_changed
    )
end

function to_protocol_format(cap::LoggingCapability)
    Dict{String,Any}()  # Logging capability just needs to be present
end

"""
Response structure for capabilities including tool and resource listings
"""
Base.@kwdef struct CapabilityResponse
    listChanged::Bool = false
    subscribe::Union{Bool,Nothing} = nothing
    tools::Union{Dict{String,Any},Nothing} = nothing  # For tool definitions
    resources::Union{Vector{Dict{String,Any}},Nothing} = nothing  # For resource listings
end

"""
Convert server capabilities to initialization response format
"""
function capabilities_to_protocol(capabilities::Vector{Capability}, server::Server)::Dict{String,Any}
    result = Dict{String,Any}()
    
    # First add base capability flags
    for cap in capabilities
        if cap isa ResourceCapability
            result["resources"] = Dict{String,Any}(
                "listChanged" => cap.list_changed,
                "subscribe" => cap.subscribe
            )
        elseif cap isa ToolCapability
            result["tools"] = Dict{String,Any}(
                "listChanged" => cap.list_changed
            )
        elseif cap isa PromptCapability
            result["prompts"] = Dict{String,Any}(
                "listChanged" => cap.list_changed
            )
        elseif cap isa LoggingCapability
            result["logging"] = Dict{String,Any}()
        end
    end
    
    # Then add available tools under their names
    if haskey(result, "tools") && !isempty(server.tools)
        tools_dict = result["tools"]  # Get existing dict with listChanged
        result["tools"] = Dict{String,Any}(
            "listChanged" => tools_dict["listChanged"]  # Put listChanged first
        )
        # Then add tools
        for tool in server.tools
            result["tools"][tool.name] = Dict{String,Any}(
                "name" => tool.name,
                "description" => tool.description,
                "inputSchema" => Dict{String,Any}(
                    "type" => "object",
                    "properties" => Dict(
                        param.name => Dict{String,Any}(
                            "type" => param.type,
                            "description" => param.description
                        ) for param in tool.parameters
                    ),
                    "required" => [p.name for p in tool.parameters if p.required]
                )
            )
        end
    end

    # Add available resources array
    if haskey(result, "resources") && !isempty(server.resources)
        result["resources"]["resources"] = map(server.resources) do resource
            Dict{String,Any}(
                "uri" => string(resource.uri),
                "name" => resource.name,
                "mimeType" => resource.mime_type,
                "description" => resource.description
            )
        end
    end
    
    result
end

"""
Merge two sets of capabilities, with later ones taking precedence
"""
function merge_capabilities(base::Vector{Capability}, override::Vector{Capability})::Vector{Capability}
    result = copy(base)
    
    for cap in override
        # Find matching capability type
        idx = findfirst(x -> typeof(x) == typeof(cap), result)
        if isnothing(idx)
            push!(result, cap)
        else
            result[idx] = cap
        end
    end
    
    result
end

"""
Convert server capabilities to initialization response format
"""
function create_init_response(server::Server, protocol_version::String)::InitializeResult
    InitializeResult(
        serverInfo = Dict(
            "name" => server.config.name,
            "version" => server.config.version
        ),
        capabilities = capabilities_to_protocol(server.config.capabilities, server),
        protocolVersion = protocol_version,
        instructions = server.config.instructions
    )
end

