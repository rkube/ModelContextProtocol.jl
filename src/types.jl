# src/types.jl

#= Base Abstract Types =#

"""
Base type for all MCP protocol capabilities.
Implementations should include configuration for specific protocol features.
"""
abstract type Capability end

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

#= Server Configuration Types =#

"""
Configuration for an MCP server
"""
Base.@kwdef struct ServerConfig
    name::String
    version::String = "1.0.0"
    description::String = ""
    capabilities::Vector{Capability} = Capability[]
    instructions::String = ""
end

#= Tool Implementation Types =#

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

#= Prompt Types =#

"""
Implementation of a prompt or prompt template as defined in the MCP schema.
"""
Base.@kwdef struct MCPPrompt
    name::String
    description::String = ""
    arguments::Vector{PromptArgument} = PromptArgument[]
end

#= Resource Implementation Types =#

"""
Structure defining a resource implementation
"""
Base.@kwdef struct MCPResource <: Resource
    uri::URI
    name::String
    description::String = ""
    mime_type::String = "application/json"
    data_provider::Function
    annotations::Dict{String,Any} = Dict{String,Any}()
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

#= Subscription and Progress Types =#

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

#= Server Implementation Types =#

"""
Represents a running MCP server instance
"""
mutable struct Server
    config::ServerConfig
    resources::Vector{Resource}
    tools::Vector{Tool}
    prompts::Vector{MCPPrompt}
    resource_templates::Vector{ResourceTemplate}
    subscriptions::DefaultDict{String,Vector{Subscription}}
    progress_trackers::Dict{Union{String,Int}, Progress}
    active::Bool
    
    function Server(config::ServerConfig)
        new(
            config,
            Resource[],
            Tool[],
            MCPPrompt[],
            ResourceTemplate[],
            DefaultDict{String,Vector{Subscription}}(() -> Subscription[]),
            Dict{Union{String,Int}, Progress}(),
            false
        )
    end
end

# Pretty printing
Base.show(io::IO, config::ServerConfig) = print(io, "ServerConfig($(config.name) v$(config.version))")
Base.show(io::IO, server::Server) = print(io, "MCP Server($(server.config.name), $(server.active ? "active" : "inactive"))")