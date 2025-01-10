# src/features/resources.jl

Base.convert(::Type{URI}, s::String) = URI(s)


struct MCPResource <: Resource
    uri::URI
    name::String
    description::String
    mime_type::String
    data_provider::Function
    annotations::Dict{String,Any}
end

# Constructor that handles keywords and URI conversion
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
Resource template as defined in schema
"""
Base.@kwdef struct ResourceTemplate
    name::String
    uri_template::String
    mime_type::Union{String,Nothing} = nothing
    description::String = ""
end
