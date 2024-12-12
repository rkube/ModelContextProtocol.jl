# src/capabilities.jl

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
Converts a vector of capabilities to protocol format
"""
function capabilities_to_protocol(capabilities::Vector{Capability})
    result = Dict{String,Any}()
    
    for cap in capabilities
        if cap isa ResourceCapability
            result["resources"] = to_protocol_format(cap)
        elseif cap isa ToolCapability
            result["tools"] = to_protocol_format(cap)
        elseif cap isa PromptCapability
            result["prompts"] = to_protocol_format(cap)
        elseif cap isa LoggingCapability
            result["logging"] = to_protocol_format(cap)
        end
    end
    
    result
end

