# src/protocol/handlers.jl

"""
Base type for all request handlers
"""
abstract type RequestHandler end

"""
Stores the current request context
"""
Base.@kwdef mutable struct RequestContext
    server::Server
    request_id::Union{RequestId,Nothing} = nothing
    progress_token::Union{ProgressToken,Nothing} = nothing
end

"""
Result of handling a request
"""
Base.@kwdef struct HandlerResult
    response::Union{Response,Nothing} = nothing
    error::Union{ErrorInfo,Nothing} = nothing
end

"""
Handle initialization requests with standardized capability broadcasting
"""
function handle_initialize(ctx::RequestContext, params::InitializeParams)::HandlerResult
    # Get full capabilities including available tools and resources
    current_capabilities = capabilities_to_protocol(
        ctx.server.config.capabilities,
        ctx.server
    )
    
    # Create initialization result
    result = InitializeResult(
        serverInfo = Dict(
            "name" => ctx.server.config.name,
            "version" => ctx.server.config.version
        ),
        capabilities = current_capabilities,
        protocolVersion = params.protocolVersion,
        instructions = ctx.server.config.instructions
    )

    HandlerResult(
        response = JSONRPCResponse(
            id = ctx.request_id,
            result = result
        )
    )
end

"""
Handles resource listing requests
"""
function handle_list_resources(ctx::RequestContext, params::ListResourcesParams)::HandlerResult
    try
        resources = map(ctx.server.resources) do resource::MCPResource
            Dict{String,Any}(
                "uri" => string(resource.uri),  # We know it's URI, just need to convert to string
                "name" => resource.name,        # Already String
                "mimeType" => resource.mime_type,
                "description" => resource.description,
                "annotations" => Dict{String,Any}(
                    "audience" => get(resource.annotations, "audience", ["assistant"]),
                    "priority" => get(resource.annotations, "priority", 0.0)
                )
            )
        end

        # Create the result dictionary explicitly
        result_dict = Dict{String,Any}(
            "resources" => resources
        )

        # Only add nextCursor if it's provided and not null
        if !isnothing(params.cursor) && params.cursor != ""
            result_dict["nextCursor"] = params.cursor
        end

        HandlerResult(
            response = JSONRPCResponse(
                id = ctx.request_id,
                result = result_dict  # Use the explicitly created dictionary
            )
        )
    catch e
        HandlerResult(
            error = ErrorInfo(
                code = ErrorCodes.INTERNAL_ERROR,
                message = "Failed to list resources: $e"
            )
        )
    end
end

# Update the ListResourcesResult struct to match schema requirements
Base.@kwdef struct ListResourcesResult <: ResponseResult
    resources::Vector{Dict{String,Any}}
    nextCursor::Union{String,Nothing} = nothing
end

# Add JSON serialization method that omits null nextCursor
function JSON3.write(io::IO, result::ListResourcesResult)
    dict = Dict{String,Any}("resources" => result.resources)
    if !isnothing(result.nextCursor)
        dict["nextCursor"] = result.nextCursor
    end
    JSON3.write(io, dict)
end

"""
Handles resource reading requests
"""
function handle_read_resource(ctx::RequestContext, params::ReadResourceParams)::HandlerResult
    # Convert the requested URI string to a URI object for comparison
    request_uri = try
        URI(params.uri)
    catch e
        return HandlerResult(
            error = ErrorInfo(
                code = ErrorCodes.INVALID_URI,
                message = "Invalid URI format: $(params.uri)"
            )
        )
    end

    # Find the resource with matching URI
    resource = nothing
    for r in ctx.server.resources
        if string(r.uri) == string(request_uri)
            resource = r
            break
        end
    end
    
    if isnothing(resource)
        return HandlerResult(
            error = ErrorInfo(
                code = ErrorCodes.RESOURCE_NOT_FOUND,
                message = "Resource not found: $(params.uri)"
            )
        )
    end

    try
        # Call the data provider
        data = resource.data_provider()
        
        # Create text resource contents
        contents = [Dict{String,Any}(
            "uri" => string(resource.uri),
            "text" => JSON3.write(data),
            "mimeType" => resource.mime_type
        )]

        return HandlerResult(
            response = JSONRPCResponse(
                id = ctx.request_id,
                result = ReadResourceResult(contents = contents)
            )
        )
    catch e
        return HandlerResult(
            error = ErrorInfo(
                code = ErrorCodes.INTERNAL_ERROR,
                message = "Error reading resource: $(e)"
            )
        )
    end
end

"""
Handles tool calls
"""
function handle_call_tool(ctx::RequestContext, params::CallToolParams)::HandlerResult
    # Find the tool by name directly from params.name
    tool_idx = findfirst(t -> t.name == params.name, ctx.server.tools)
    
    if isnothing(tool_idx)
        return HandlerResult(
            error = ErrorInfo(
                code = ErrorCodes.TOOL_NOT_FOUND,
                message = "Tool not found: $(params.name)"
            )
        )
    end

    tool = ctx.server.tools[tool_idx]

    try
        # Call the tool handler with the arguments from params
        result = tool.handler(params.arguments)

        # Create content array with tool result
        content = [Dict{String,Any}(
            "type" => "text",  # Required by schema
            "text" => JSON3.write(result),
            "annotations" => Dict{String,Any}()
        )]

        HandlerResult(
            response = JSONRPCResponse(
                id = ctx.request_id,
                result = CallToolResult(
                    content = content,
                    is_error = false
                )
            )
        )
    catch e
        HandlerResult(
            error = ErrorInfo(
                code = ErrorCodes.INTERNAL_ERROR,
                message = "Tool execution failed: $(e)"
            )
        )
    end
end

"""
Handles tool listing requests
"""
function handle_list_tools(ctx::RequestContext, params::ListToolsParams)::HandlerResult
    try
        tools = map(ctx.server.tools) do tool
            Dict{String,Any}(
                "name" => tool.name,
                "description" => tool.description,  # Move description before inputSchema
                "inputSchema" => Dict{String,Any}(
                    "type" => "object",
                    "properties" => Dict(
                        param.name => Dict{String,Any}(
                            "type" => param.type,
                            "description" => param.description
                        ) for param in tool.parameters
                    ),
                    "required" => [p.name for p in tool.parameters if p.required]
                )
            )
        end

        result = Dict{String,Any}(
            "tools" => tools  # Remove nextCursor
        )

        HandlerResult(
            response = JSONRPCResponse(
                id = ctx.request_id,
                result = result
            )
        )
    catch e
        HandlerResult(
            error = ErrorInfo(
                code = ErrorCodes.INTERNAL_ERROR,
                message = "Failed to list tools: $e"
            )
        )
    end
end

"""
Handle notifications
"""
function handle_notification(ctx::RequestContext, notification::JSONRPCNotification)::Nothing
    method = notification.method
    
    if method == "notifications/initialized"
        ctx.server.active = true
    elseif method == "notifications/cancelled"
        # Handle cancellation
    elseif method == "notifications/progress"
        # Handle progress updates
    end
    
    return nothing
end

function handle_request(server::Server, request::Request)::Response
    ctx = RequestContext(
        server = server,
        request_id = request.id,
        progress_token = request.meta.progress_token
    )

    try
        # Handle request with already typed parameters
        result = 
        if request.method == "initialize"
            handle_initialize(ctx, request.params::InitializeParams)
        elseif request.method == "resources/list"
            handle_list_resources(ctx, request.params::ListResourcesParams)
        elseif request.method == "resources/read"
            handle_read_resource(ctx, request.params::ReadResourceParams)
        elseif request.method == "tools/call"
            handle_call_tool(ctx, request.params::CallToolParams)
        elseif request.method == "tools/list"
            handle_list_tools(ctx, request.params::ListToolsParams)
        else
            HandlerResult(
                error = ErrorInfo(
                    code = ErrorCodes.METHOD_NOT_FOUND,
                    message = "Unknown method: $(request.method)"
                )
            )
        end

        # Return response or error
        if !isnothing(result.error)
            JSONRPCError(id = ctx.request_id, error = result.error)
        else
            result.response
        end
    catch e
        @error "Request handler error" exception=e
        JSONRPCError(
            id = ctx.request_id,
            error = ErrorInfo(
                code = ErrorCodes.INTERNAL_ERROR,
                message = "Internal error: $(e)" 
            )
        )
    end
end

# Handle empty params case
function handle_resources_list(server::Server, ::Nothing)
    # Default implementation for empty params
    return list_resources(server)
end

# Handle params case
function handle_resources_list(server::Server, params::ListResourcesParams)
    return list_resources(server, params.cursor)
end
