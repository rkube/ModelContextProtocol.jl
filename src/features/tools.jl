# src/features/tools.jl

"""
Structure defining a tool parameter
"""
Base.@kwdef struct ToolParameter
    name::String
    description::String
    type::String 
    required::Bool = false
end

"""
Structure defining a tool implementation

A tool handler can return various types:
- Return the expected Content type directly (TextContent, ImageContent, etc.)
- Return a Dict (automatically converted to JSON and wrapped in TextContent)
- Return a String (automatically wrapped in TextContent)
- Return a Tuple{Vector{UInt8}, String} (automatically wrapped in ImageContent)

The framework will automatically convert these common return types to the proper Content type.
"""
Base.@kwdef struct MCPTool <: Tool
    name::String
    description::String
    parameters::Vector{ToolParameter}
    handler::Function
    return_type::Type{<:Content} = TextContent  # Use existing Content types
end