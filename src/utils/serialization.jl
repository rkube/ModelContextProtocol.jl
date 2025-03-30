# src/utils/serialization.jl

"""
    StructTypes definitions for MCP types

Define serialization behavior for ModelContextProtocol types via StructTypes.jl.
This module configures how various MCP types are serialized to and from JSON.
"""

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

"""
    StructTypes.omitempties(::Type{ClientCapabilities}) -> Tuple{Symbol,Symbol,Symbol}

Specify which fields should be omitted from JSON serialization when they are empty or null.

# Arguments
- `::Type{ClientCapabilities}`: The ClientCapabilities type

# Returns
- `Tuple{Symbol,Symbol,Symbol}`: Fields to omit when empty
"""
function StructTypes.omitempties(::Type{ClientCapabilities})
    (:experimental, :roots, :sampling)
end

"""
    StructTypes.omitempties(::Type{ListPromptsResult}) -> Tuple{Symbol}

Specify which fields should be omitted from JSON serialization when they are empty or null.

# Arguments
- `::Type{ListPromptsResult}`: The ListPromptsResult type

# Returns
- `Tuple{Symbol}`: Fields to omit when empty
"""
function StructTypes.omitempties(::Type{ListPromptsResult})
    (:nextCursor,)
end

