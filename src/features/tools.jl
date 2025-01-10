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
"""
Base.@kwdef struct MCPTool <: Tool
    name::String
    description::String
    parameters::Vector{ToolParameter}
    handler::Function
    return_type::Type = Any
end



