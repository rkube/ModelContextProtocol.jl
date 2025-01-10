# src/core/types.jl

# 1. Core enums/aliases

"""
Represents a role in the MCP protocol (user or assistant)
"""
@enum Role user assistant

"""
JSON-RPC request ID - can be string or integer
"""
const RequestId = Union{String,Int}

"""
Progress token for tracking long-running operations
"""
const ProgressToken = Union{String,Int}

# 2. Core abstract types

"""
Base type for all MCP protocol messages
"""
abstract type MCPMessage end

"""
Base type for all MCP protocol requests
"""
abstract type Request <: MCPMessage end

"""
Base type for all MCP protocol responses
"""
abstract type Response <: MCPMessage end

"""
Base type for all MCP protocol notifications
"""
abstract type Notification <: MCPMessage end

"""
Base type for all request parameters
"""
abstract type RequestParams end

"""
Base type for all response results
"""
abstract type ResponseResult end

"""
Base type for content that can be sent or received
"""
abstract type Content end

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

"""
Base type for resource contents
"""
abstract type ResourceContents end


# 3. Core concrete types

"""
Text content with required type field and optional annotations
"""
Base.@kwdef struct TextContent <: Content
    type::String = "text"  # Schema requires this to be const "text"
    text::String
    annotations::Dict{String,Any} = Dict{String,Any}()
end

"""
Image content with required type and MIME type fields
"""
Base.@kwdef struct ImageContent <: Content
    type::String = "image"  # Schema requires this to be const "image"
    data::Vector{UInt8}
    mime_type::String
    annotations::Dict{String,Any} = Dict{String,Any}()
end

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
Represents subscriptions to resource updates
"""
Base.@kwdef struct Subscription
    uri::String
    callback::Function
    created_at::DateTime = now()
end
