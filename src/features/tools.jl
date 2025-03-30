# src/features/tools.jl

"""
    ToolParameter(; name::String, description::String, type::String, required::Bool=false)

Define a parameter for an MCP tool.

# Fields
- `name::String`: The parameter name (used as the key in the params dictionary)
- `description::String`: Human-readable description of the parameter
- `type::String`: Type of the parameter as specified in the MCP schema (e.g., "string", "number", "boolean")
- `required::Bool`: Whether the parameter is required for tool invocation
"""
Base.@kwdef struct ToolParameter
    name::String
    description::String
    type::String 
    required::Bool = false
end

"""
    MCPTool(; name::String, description::String, parameters::Vector{ToolParameter},
          handler::Function, return_type::Type{<:Content}=TextContent) <: Tool

Implement a tool that can be invoked by clients in the MCP protocol.

# Fields
- `name::String`: Unique identifier for the tool
- `description::String`: Human-readable description of the tool's purpose
- `parameters::Vector{ToolParameter}`: Parameters that the tool accepts
- `handler::Function`: Function that implements the tool's functionality
- `return_type::Type{<:Content}`: Expected return type of the handler

# Handler Return Types
The tool handler can return various types which are automatically converted:
- An instance of the specified Content type (TextContent, ImageContent, etc.)
- A Dict (automatically converted to JSON and wrapped in TextContent)
- A String (automatically wrapped in TextContent)
- A Tuple{Vector{UInt8}, String} (automatically wrapped in ImageContent)
"""
Base.@kwdef struct MCPTool <: Tool
    name::String
    description::String
    parameters::Vector{ToolParameter}
    handler::Function
    return_type::Type{<:Content} = TextContent  # Use existing Content types
end