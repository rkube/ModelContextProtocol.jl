# src/features/prompts.jl


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
    role::Role = user  # Set default in the kwdef constructor
end

# Keep the positional constructor too
function PromptMessage(content::Union{TextContent, ImageContent, EmbeddedResource})
    PromptMessage(content = content)
end

"""
Implementation of a prompt or prompt template as defined in the MCP schema.
"""
Base.@kwdef struct MCPPrompt
    name::String
    description::String = ""
    arguments::Vector{PromptArgument} = PromptArgument[]
    messages::Vector{PromptMessage} = PromptMessage[]
end

function MCPPrompt(name::String, description::String, arguments::Vector{PromptArgument}, text::String)
    MCPPrompt(
        name = name,
        description = description,
        arguments = arguments,
        text = text
    )
end
