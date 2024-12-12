# src/protocol/messages.jl

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
    experimental::Union{Dict{String,Any},Nothing} = nothing
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
Initialize request parameters
"""
Base.@kwdef struct InitializeParams <: RequestParams
    capabilities::ClientCapabilities = ClientCapabilities()
    clientInfo::Implementation = Implementation(name="default-client", version="1.0.0")
    protocolVersion::String = "2024-11-05"
end

"""
Initialize response result
"""
Base.@kwdef struct InitializeResult <: ResponseResult
    serverInfo::Dict{String,Any}  # Was server_info
    capabilities::Dict{String,Any}
    protocolVersion::String       # Was protocol_version  
    instructions::String = ""
end

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
    nextCursor::Union{String,Nothing} = nothing  # Changed from next_cursor to nextCursor
end

"""
List tools response result
"""
Base.@kwdef struct ListToolsResult <: ResponseResult
    tools::Vector{Dict{String,Any}}
    next_cursor::Union{String,Nothing} = nothing
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

"""
Call tool request parameters
"""
Base.@kwdef struct CallToolParams <: RequestParams
    name::String
    arguments::Dict{String,Any} = Dict{String,Any}()
end

"""
Call tool response result
"""
Base.@kwdef struct CallToolResult <: ResponseResult
    content::Vector{Dict{String,Any}}
    is_error::Bool = false
end

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

"""
JSON-RPC request message
"""
Base.@kwdef struct JSONRPCRequest <: Request
    id::RequestId
    method::String
    params::Union{RequestParams,Dict{String,Any}}
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

# Add StructTypes support for JSON serialization
StructTypes.StructType(::Type{ClientCapabilities}) = StructTypes.Struct()
StructTypes.StructType(::Type{Implementation}) = StructTypes.Struct()
StructTypes.StructType(::Type{InitializeParams}) = StructTypes.Struct()
StructTypes.StructType(::Type{RequestMeta}) = StructTypes.Struct()
StructTypes.StructType(::Type{ErrorInfo}) = StructTypes.Struct()
StructTypes.StructType(::Type{ListResourcesParams}) = StructTypes.Struct()
StructTypes.StructType(::Type{T}) where {T<:RequestParams} = StructTypes.Struct()
StructTypes.StructType(::Type{T}) where {T<:ResponseResult} = StructTypes.Struct()

# Add field omission for null values
function StructTypes.omitempties(::Type{ClientCapabilities})
    (:experimental, :roots, :sampling)
end

"""
JSON-RPC notification message (no response expected)
"""
Base.@kwdef struct JSONRPCNotification <: Notification
    method::String
    params::Union{RequestParams,Dict{String,Any}}
end

# Error codes as specified in the JSON-RPC spec
module ErrorCodes
    const PARSE_ERROR = -32700
    const INVALID_REQUEST = -32600
    const METHOD_NOT_FOUND = -32601
    const INVALID_PARAMS = -32602
    const INTERNAL_ERROR = -32603
    
    # MCP specific error codes
    const RESOURCE_NOT_FOUND = -32000
    const TOOL_NOT_FOUND = -32001
    const INVALID_URI = -32002
end
