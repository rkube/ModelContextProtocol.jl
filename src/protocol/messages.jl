# src/protocol/messages.jl

#= Core Protocol Types =#

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

export RequestId, ProgressToken

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

#= Common Protocol Structures =#

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
end

"""
Request metadata including progress tracking
"""
Base.@kwdef struct RequestMeta
    progress_token::Union{ProgressToken,Nothing} = nothing
end

"""
Client capabilities struct
"""
Base.@kwdef struct ClientCapabilities
    experimental::Union{Dict{String,Dict{String,Any}},Nothing} = nothing
    roots::Union{Dict{String,Bool},Nothing} = nothing
    sampling::Union{Dict{String,Any},Nothing} = nothing
end

"""
Implementation info struct
"""
Base.@kwdef struct Implementation
    name::String = "default-client"
    version::String = "1.0.0"
end

"""
Describes an argument that a prompt can accept.
"""
Base.@kwdef struct PromptArgument
    name::String
    description::String = ""
    required::Bool = false
end

"""
Represents a message returned as part of a prompt
"""
Base.@kwdef struct PromptMessage
    content::Union{TextContent, ImageContent, EmbeddedResource}
    role::Role
end

#= Initialize Protocol Messages =#

"""
Initialize request parameters
"""
Base.@kwdef struct InitializeParams <: RequestParams
    capabilities::ClientCapabilities = ClientCapabilities()
    clientInfo::Implementation = Implementation()
    protocolVersion::String
end

"""
Initialize response result
"""
Base.@kwdef struct InitializeResult <: ResponseResult
    serverInfo::Dict{String,Any}
    capabilities::Dict{String,Any}
    protocolVersion::String
    instructions::String = ""
end

#= Resource-Related Messages =#

"""
List resources request parameters
"""
Base.@kwdef struct ListResourcesParams <: RequestParams
    cursor::Union{String,Nothing} = nothing
end

"""
List resources response result
"""
Base.@kwdef struct ListResourcesResult <: ResponseResult
    resources::Vector{Dict{String,Any}}
    nextCursor::Union{String,Nothing} = nothing
end

"""
Read resource request parameters
"""
Base.@kwdef struct ReadResourceParams <: RequestParams
    uri::String
end

"""
Read resource response result
"""
Base.@kwdef struct ReadResourceResult <: ResponseResult
    contents::Vector{Dict{String,Any}}
end

#= Tool-Related Messages =#

"""
List tools request parameters
"""
Base.@kwdef struct ListToolsParams <: RequestParams 
    cursor::Union{String,Nothing} = nothing
end

"""
List tools response result
"""
Base.@kwdef struct ListToolsResult <: ResponseResult
    tools::Vector{Dict{String,Any}}
    nextCursor::Union{String,Nothing} = nothing
end

"""
Call tool request parameters
"""
Base.@kwdef struct CallToolParams <: RequestParams
    name::String
    arguments::Union{Dict{String,Any},Nothing} = nothing
end

"""
Call tool response result
"""
Base.@kwdef struct CallToolResult <: ResponseResult
    content::Vector{Dict{String,Any}}
    is_error::Bool = false
end

#= Prompt-Related Messages =#

"""
List prompts request parameters
"""
Base.@kwdef struct ListPromptsParams <: RequestParams
    cursor::Union{String,Nothing} = nothing
end

"""
List prompts response result
"""
Base.@kwdef struct ListPromptsResult <: ResponseResult
    prompts::Vector{Dict{String,Any}}
    nextCursor::Union{String,Nothing} = nothing
end

"""
Get prompt request parameters
"""
Base.@kwdef struct GetPromptParams <: RequestParams
    name::String
    arguments::Union{Dict{String,String},Nothing} = nothing
end

"""
Get prompt response result
"""
Base.@kwdef struct GetPromptResult <: ResponseResult
    description::String
    messages::Vector{PromptMessage}
end

#= Progress and Error Messages =#

"""
Progress notification parameters
"""
Base.@kwdef struct ProgressParams <: RequestParams
    progress_token::ProgressToken
    progress::Float64
    total::Union{Float64,Nothing} = nothing
end

"""
Error information for JSON-RPC error responses
"""
Base.@kwdef struct ErrorInfo
    code::Int
    message::String
    data::Union{Dict{String,Any},Nothing} = nothing
end

#= JSON-RPC Message Types =#

"""
JSON-RPC request message
"""
Base.@kwdef struct JSONRPCRequest <: Request
    id::RequestId
    method::String
    params::Union{RequestParams, Nothing}
    meta::RequestMeta = RequestMeta()
end

"""
JSON-RPC response message
"""
Base.@kwdef struct JSONRPCResponse <: Response
    id::RequestId
    result::Union{ResponseResult,Dict{String,Any}}
end

"""
JSON-RPC error response message
"""
Base.@kwdef struct JSONRPCError <: Response
    id::Union{RequestId,Nothing} 
    error::ErrorInfo
end

"""
JSON-RPC notification message (no response expected)
"""
Base.@kwdef struct JSONRPCNotification <: Notification
    method::String
    params::Union{RequestParams,Dict{String,Any}}
end

#= Type System Configuration =#

# Add StructTypes support for JSON serialization
StructTypes.StructType(::Type{TextContent}) = StructTypes.Struct()
StructTypes.StructType(::Type{ImageContent}) = StructTypes.Struct()
StructTypes.StructType(::Type{TextResourceContents}) = StructTypes.Struct()
StructTypes.StructType(::Type{BlobResourceContents}) = StructTypes.Struct()
StructTypes.StructType(::Type{EmbeddedResource}) = StructTypes.Struct()
StructTypes.StructType(::Type{ClientCapabilities}) = StructTypes.Struct()
StructTypes.StructType(::Type{Implementation}) = StructTypes.Struct()
StructTypes.StructType(::Type{InitializeParams}) = StructTypes.Struct()
StructTypes.StructType(::Type{RequestMeta}) = StructTypes.Struct()
StructTypes.StructType(::Type{ErrorInfo}) = StructTypes.Struct()
StructTypes.StructType(::Type{ListResourcesParams}) = StructTypes.Struct()
StructTypes.StructType(::Type{ListPromptsParams}) = StructTypes.Struct()
StructTypes.StructType(::Type{GetPromptParams}) = StructTypes.Struct()
StructTypes.StructType(::Type{PromptMessage}) = StructTypes.Struct()
StructTypes.StructType(::Type{T}) where {T<:RequestParams} = StructTypes.Struct()
StructTypes.StructType(::Type{T}) where {T<:ResponseResult} = StructTypes.Struct()

# Add field omission for null values
function StructTypes.omitempties(::Type{ClientCapabilities})
    (:experimental, :roots, :sampling)
end

function StructTypes.omitempties(::Type{ListPromptsResult})
    (:nextCursor,)
end

#= Error Codes =#

"""
Error codes as specified in JSON-RPC and MCP
"""
module ErrorCodes
    # JSON-RPC standard error codes
    const PARSE_ERROR = -32700
    const INVALID_REQUEST = -32600
    const METHOD_NOT_FOUND = -32601
    const INVALID_PARAMS = -32602
    const INTERNAL_ERROR = -32603
    
    # MCP specific error codes
    const RESOURCE_NOT_FOUND = -32000
    const TOOL_NOT_FOUND = -32001
    const INVALID_URI = -32002
    const PROMPT_NOT_FOUND = -32003
end