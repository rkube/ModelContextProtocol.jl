# src/types.jl

#= Base Abstract Types =#

"""
    Capability

Define base type for all MCP protocol capabilities.
Implementations should include configuration for specific protocol features.
"""
abstract type Capability end

"""
    Tool

Define base type for all MCP tools.
Tools represent operations that can be invoked by clients.
"""
abstract type Tool end

"""
    Resource

Define base type for all MCP resources.
Resources represent data that can be read by clients.
"""
abstract type Resource end

#= Server Configuration Types =#

"""
    ServerConfig(; name::String, version::String="1.0.0", description::String="", 
                capabilities::Vector{Capability}=Capability[], instructions::String="")

Define configuration settings for an MCP server instance.

# Fields
- `name::String`: The server name shown to clients
- `version::String`: Server version string
- `description::String`: Human-readable server description
- `capabilities::Vector{Capability}`: Protocol capabilities supported by the server
- `instructions::String`: Usage instructions for clients
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
    ToolParameter(; name::String, type::String, description::String="", 
                 required::Bool=false, constraints::Dict{String,Any}=Dict{String,Any}())

Define a parameter for an MCP tool.

# Fields
- `name::String`: The parameter name (used as the key in the params dictionary)
- `type::String`: Type of the parameter as specified in the MCP schema
- `description::String`: Human-readable description of the parameter
- `required::Bool`: Whether the parameter is required for tool invocation
- `constraints::Dict{String,Any}`: Optional constraints on parameter values
"""
Base.@kwdef struct ToolParameter
    name::String
    type::String
    description::String = ""
    required::Bool = false
    constraints::Dict{String,Any} = Dict{String,Any}()
end

"""
    MCPTool(; name::String, description::String, parameters::Vector{ToolParameter},
           handler::Function, return_type::Type=Any) <: Tool

Implement a tool that can be invoked by clients in the MCP protocol.

# Fields
- `name::String`: Unique identifier for the tool
- `description::String`: Human-readable description of the tool's purpose
- `parameters::Vector{ToolParameter}`: Parameters that the tool accepts
- `handler::Function`: Function that implements the tool's functionality
- `return_type::Type`: Expected return type of the handler
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
    MCPPrompt(; name::String, description::String="", 
            arguments::Vector{PromptArgument}=PromptArgument[],
            messages::Vector{PromptMessage}=PromptMessage[])

Implement a prompt or prompt template as defined in the MCP schema.
Prompts can include variables that are replaced with arguments when retrieved.

# Fields
- `name::String`: Unique identifier for the prompt
- `description::String`: Human-readable description of the prompt's purpose
- `arguments::Vector{PromptArgument}`: Arguments that this prompt accepts
- `messages::Vector{PromptMessage}`: The sequence of messages in the prompt
"""
Base.@kwdef struct MCPPrompt
    name::String
    description::String = ""
    arguments::Vector{PromptArgument} = PromptArgument[]
    messages::Vector{PromptMessage} = PromptMessage[]
end



"""
    MCPPrompt(name::String, description::String, arguments::Vector{PromptArgument}, text::String) -> MCPPrompt

Create a prompt with a single text message.

# Arguments
- `name::String`: Unique identifier for the prompt
- `description::String`: Human-readable description
- `arguments::Vector{PromptArgument}`: Arguments the prompt accepts
- `text::String`: Text content for the prompt message

# Returns
- `MCPPrompt`: A new prompt with a single user message containing the text
"""
function MCPPrompt(name::String, description::String, arguments::Vector{PromptArgument}, text::String)
    MCPPrompt(
        name = name,
        description = description,
        arguments = arguments,
        text = text
    )
end


#= Resource Implementation Types =#

"""
    MCPResource(; uri::URI, name::String, description::String="",
              mime_type::String="application/json", data_provider::Function,
              annotations::Dict{String,Any}=Dict{String,Any}()) <: Resource

Implement a resource that clients can access in the MCP protocol.
Resources represent data that can be read by models and tools.

# Fields
- `uri::URI`: Unique identifier for the resource
- `name::String`: Human-readable name for the resource
- `description::String`: Detailed description of the resource
- `mime_type::String`: MIME type of the resource data
- `data_provider::Function`: Function that provides the resource data when called
- `annotations::Dict{String,Any}`: Additional metadata for the resource
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
    MCPResource(; uri::String, name::String="", description::String="",
              mime_type::String="application/json", data_provider::Function,
              annotations::Dict{String,Any}=Dict{String,Any}()) -> MCPResource

Create a resource with automatic URI conversion from strings.

# Arguments
- `uri::String`: String identifier for the resource
- `name::String`: Human-readable name for the resource
- `description::String`: Detailed description
- `mime_type::String`: MIME type of the resource
- `data_provider::Function`: Function that returns the resource data when called
- `annotations::Dict{String,Any}`: Additional metadata for the resource

# Returns
- `MCPResource`: A new resource with the provided configuration
"""
function MCPResource(; uri::String, 
    name::String = "", 
    description::String = "", 
    mime_type::String = "application/json", 
    data_provider::Function, 
    annotations::Dict{String,Any} = Dict{String,Any}())
    MCPResource(URI(uri), name, description, mime_type, data_provider, annotations)
end


"""
    ResourceTemplate(; name::String, uri_template::String,
                   mime_type::Union{String,Nothing}=nothing, description::String="")

Define a template for dynamically generating resources with parameterized URIs.

# Fields
- `name::String`: Name of the resource template
- `uri_template::String`: Template string with placeholders for parameters
- `mime_type::Union{String,Nothing}`: MIME type of the generated resources
- `description::String`: Human-readable description of the template
"""
Base.@kwdef struct ResourceTemplate
    name::String
    uri_template::String
    mime_type::Union{String,Nothing} = nothing
    description::String = ""
end

#= Subscription and Progress Types =#

"""
    Subscription(; uri::String, callback::Function, created_at::DateTime=now())

Define a subscription to resource updates in the MCP protocol.

# Fields
- `uri::String`: The URI of the subscribed resource
- `callback::Function`: Function to call when the resource is updated
- `created_at::DateTime`: When the subscription was created
"""
Base.@kwdef struct Subscription
    uri::String
    callback::Function
    created_at::DateTime = now()
end

"""
    Progress(; token::Union{String,Int}, current::Float64, 
            total::Union{Float64,Nothing}=nothing, message::Union{String,Nothing}=nothing)

Track progress of long-running operations in the MCP protocol.

# Fields
- `token::Union{String,Int}`: Unique identifier for the progress tracker
- `current::Float64`: Current progress value
- `total::Union{Float64,Nothing}`: Optional total expected value
- `message::Union{String,Nothing}`: Optional status message
"""
Base.@kwdef struct Progress
    token::Union{String,Int}
    current::Float64
    total::Union{Float64,Nothing} = nothing
    message::Union{String,Nothing} = nothing
end

#= Server Implementation Types =#

"""
    Server(config::ServerConfig)

Represent a running MCP server instance that manages resources, tools, and prompts.

# Fields
- `config::ServerConfig`: Server configuration settings
- `resources::Vector{Resource}`: Available resources
- `tools::Vector{Tool}`: Available tools
- `prompts::Vector{MCPPrompt}`: Available prompts
- `resource_templates::Vector{ResourceTemplate}`: Available resource templates
- `subscriptions::DefaultDict{String,Vector{Subscription}}`: Resource subscription registry
- `progress_trackers::Dict{Union{String,Int},Progress}`: Progress tracking for operations
- `active::Bool`: Whether the server is currently active
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