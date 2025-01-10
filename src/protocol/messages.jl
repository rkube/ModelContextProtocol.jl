# src/protocol/messages.jl

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

