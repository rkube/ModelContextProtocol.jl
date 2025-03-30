# src/features/resources.jl

"""
    convert(::Type{URI}, s::String) -> URI

Convert a string to a URI object.

# Arguments
- `s::String`: The string to convert

# Returns
- `URI`: The resulting URI object
"""
Base.convert(::Type{URI}, s::String) = URI(s)


"""
    MCPResource(; uri, name::String, description::String="",
              mime_type::String="application/json", data_provider::Function,
              annotations::Dict{String,Any}=Dict{String,Any}()) <: Resource

Implement a resource that clients can access in the MCP protocol.
Resources represent data that can be read by models and tools.

# Fields
- `uri::URI`: Unique identifier for the resource
- `name::String`: Human-readable name for the resource
- `description::String`: Detailed description of the resource
- `mime_type::String`: MIME type of the resource data
- `data_provider::Function`: Function that provides the resource data when called
- `annotations::Dict{String,Any}`: Additional metadata for the resource
"""
struct MCPResource <: Resource
    uri::URI
    name::String
    description::String
    mime_type::String
    data_provider::Function
    annotations::Dict{String,Any}
end

"""
    MCPResource(; uri, name, description="", mime_type="application/json", 
              data_provider, annotations=Dict{String,Any}()) -> MCPResource

Create a resource with automatic URI conversion from strings.

# Arguments
- `uri`: String or URI identifier for the resource
- `name`: Human-readable name for the resource
- `description`: Detailed description
- `mime_type`: MIME type of the resource
- `data_provider`: Function that returns the resource data when called
- `annotations`: Additional metadata for the resource

# Returns
- `MCPResource`: A new resource with the provided configuration
"""
function MCPResource(;
    uri,
    name,
    description = "",
    mime_type = "application/json",
    data_provider,
    annotations = Dict{String,Any}()
)
    uri_val = uri isa String ? URI(uri) : uri
    return MCPResource(uri_val, name, description, mime_type, data_provider, annotations)
end

# function MCPResource(; uri::String, 
#     name::String = "", 
#     description::String = "", 
#     mime_type::String = "application/json", 
#     data_provider::Function, 
#     annotations::Dict{String,Any} = Dict{String,Any}())
#     MCPResource(URI(uri), name, description, mime_type, data_provider, annotations)
# end

"""
    ResourceTemplate(; name::String, uri_template::String,
                   mime_type::Union{String,Nothing}=nothing, description::String="")

Define a template for dynamically generating resources with parameterized URIs.

# Fields
- `name::String`: Name of the resource template
- `uri_template::String`: Template string with placeholders for parameters
- `mime_type::Union{String,Nothing}`: MIME type of the generated resources
- `description::String`: Human-readable description of the template
"""
Base.@kwdef struct ResourceTemplate
    name::String
    uri_template::String
    mime_type::Union{String,Nothing} = nothing
    description::String = ""
end
