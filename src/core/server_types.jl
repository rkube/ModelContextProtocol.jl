"""
Server state tracking
"""
mutable struct ServerState
    initialized::Bool
    running::Bool
    last_request_id::Int
    pending_requests::Dict{RequestId, String}  # method name for each pending request
    
    ServerState() = new(false, false, 0, Dict())
end

"""
MCP Server errors
"""
struct ServerError <: Exception
    message::String
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
end

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
