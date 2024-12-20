# src/types.jl

import Base: merge

"""
Base type for all MCP protocol capabilities.
Implementations should include configuration for specific protocol features.
"""
abstract type Capability end

# Add capability merging function
function merge_capabilities(base::Vector{Capability}, override::Vector{Capability})::Vector{Capability}
    result = copy(base)
    
    for cap in override
        # Find matching capability type in result
        idx = findfirst(x -> typeof(x) == typeof(cap), result)
        if !isnothing(idx)
            # Replace existing capability
            result[idx] = cap
        else
            # Add new capability type
            push!(result, cap)
        end
    end
    
    return result
end

"""
Base type for all MCP tools.
Tools represent operations that can be invoked by clients.
"""
abstract type Tool end

"""
Base type for all MCP resources.
Resources represent data that can be read by clients.
"""
abstract type Resource end

"""
Represents a role in the MCP protocol (user or assistant)
"""
@enum Role user assistant

"""
Base type for content that can be sent or received
"""
abstract type Content end

"""
Text content with required type field and optional annotations
"""
Base.@kwdef struct TextContent <: Content
    type::String = "text"  # Schema requires this to be const "text"
    text::String
    annotations::Dict{String,Any} = Dict{String,Any}()

    function TextContent(type::String, text::String, annotations::Dict{String,Any} = Dict{String,Any}())
        if type != "text"
            throw(ArgumentError("TextContent type must be 'text'"))
        end
        new(type, text, annotations)
    end
end

"""
Image content with required type and MIME type fields
"""
Base.@kwdef struct ImageContent <: Content
    type::String = "image"  # Schema requires this to be const "image"
    data::Vector{UInt8}
    mime_type::String
    annotations::Dict{String,Any} = Dict{String,Any}()

    function ImageContent(type::String, data::Vector{UInt8}, mime_type::String, annotations::Dict{String,Any} = Dict{String,Any}())
        if type != "image"
            throw(ArgumentError("ImageContent type must be 'image'"))
        end
        new(type, data, mime_type, annotations)
    end
end

"""
Base type for resource contents
"""
abstract type ResourceContents end

"""
Text-based resource contents
"""
Base.@kwdef struct TextResourceContents <: ResourceContents
    uri::String
    text::String
    mime_type::Union{String,Nothing} = nothing
end

"""
Binary resource contents
"""
Base.@kwdef struct BlobResourceContents <: ResourceContents
    uri::String
    blob::Vector{UInt8}
    mime_type::Union{String,Nothing} = nothing
end

"""
Embedded resource content as defined in schema
"""
Base.@kwdef struct EmbeddedResource <: Content
    type::String = "resource"  # Schema requires this to be const "resource"
    resource::Union{TextResourceContents, BlobResourceContents}
    annotations::Dict{String,Any} = Dict{String,Any}()

    function EmbeddedResource(type::String, resource::Union{TextResourceContents, BlobResourceContents}, annotations::Dict{String,Any} = Dict{String,Any}())
        if type != "resource"
            throw(ArgumentError("EmbeddedResource type must be 'resource'"))
        end
        new(type, resource, annotations)
    end
end

"""
Configuration for an MCP server
"""
Base.@kwdef struct ServerConfig
    name::String
    version::String = "1.0.0"
    description::String = ""
    capabilities::Vector{Capability} = Capability[]
    instructions::String = ""

    # Inner constructor to ensure capabilities are properly initialized
    function ServerConfig(name::String, version::String="1.0.0", 
                        description::String="", capabilities::Vector{Capability}=Capability[],
                        instructions::String="")
        # Always ensure we have the basic capabilities
        base_capabilities = [
            ResourceCapability(list_changed=true, subscribe=true),
            ToolCapability(list_changed=true),
            PromptCapability(list_changed=true),
            LoggingCapability()
        ]
        
        # Merge with provided capabilities, allowing overrides
        final_capabilities = merge_capabilities(base_capabilities, capabilities)
        
        new(name, version, description, final_capabilities, instructions)
    end
end

"""
Structure holding metadata about a tool parameter
"""
Base.@kwdef struct ToolParameter
    name::String
    type::String
    description::String = ""
    required::Bool = false
    constraints::Dict{String,Any} = Dict{String,Any}()
end

"""
Structure defining a tool implementation
"""
Base.@kwdef struct MCPTool <: Tool
    name::String
    description::String
    parameters::Vector{ToolParameter}
    handler::Function
    return_type::Type = Any
end

"""
Structure defining a resource implementation
"""
Base.@kwdef struct MCPResource <: Resource
    uri::URI
    name::String
    description::String = ""
    mime_type::String = "application/json"
    data_provider::Function
    annotations::Dict{String,Any} = Dict{String,Any}()  # Added annotations field with default empty Dict
end

function MCPResource(; uri::String,  # Changed to keyword arg
                     name::String = "", 
                     description::String = "", 
                     mime_type::String = "application/json", 
                     data_provider::Function,
                     annotations::Dict{String,Any} = Dict{String,Any}())
    MCPResource(URI(uri), name, description, mime_type, data_provider, annotations)
end

"""
Resource template as defined in schema
"""
Base.@kwdef struct ResourceTemplate
    name::String
    uri_template::String
    mime_type::Union{String,Nothing} = nothing
    description::String = ""
end

"""
Represents subscriptions to resource updates
"""
Base.@kwdef struct Subscription
    uri::String
    callback::Function
    created_at::DateTime = now()
end

"""
Progress tracking for long-running operations
"""
Base.@kwdef struct Progress
    token::Union{String,Int}
    current::Float64
    total::Union{Float64,Nothing} = nothing
    message::Union{String,Nothing} = nothing
end

"""
Represents a running MCP server instance
"""
mutable struct Server
    config::ServerConfig
    resources::Vector{Resource}
    tools::Vector{Tool}
    resource_templates::Vector{ResourceTemplate}
    subscriptions::DefaultDict{String,Vector{Subscription}}
    progress_trackers::Dict{Union{String,Int}, Progress}
    active::Bool
    
    function Server(config::ServerConfig)
        new(
            config,
            Resource[],
            Tool[],
            ResourceTemplate[],
            DefaultDict{String,Vector{Subscription}}(() -> Subscription[]),
            Dict{Union{String,Int}, Progress}(),
            false
        )
    end
end

# Helper constructors for content types
function text_content(text::String, annotations::Dict{String,Any} = Dict{String,Any}())
    TextContent(type="text", text=text, annotations=annotations)
end

function image_content(data::Vector{UInt8}, mime_type::String, annotations::Dict{String,Any} = Dict{String,Any}())
    ImageContent(type="image", data=data, mime_type=mime_type, annotations=annotations)
end

function embedded_resource(resource::Union{TextResourceContents, BlobResourceContents}, annotations::Dict{String,Any} = Dict{String,Any}())
    EmbeddedResource(type="resource", resource=resource, annotations=annotations)
end

# Pretty printing
Base.show(io::IO, config::ServerConfig) = print(io, "ServerConfig($(config.name) v$(config.version))")
Base.show(io::IO, server::Server) = print(io, "MCP Server($(server.config.name), $(server.active ? "active" : "inactive"))")