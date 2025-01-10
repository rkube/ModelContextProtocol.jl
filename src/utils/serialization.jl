# src/utils/serialization.jl


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

