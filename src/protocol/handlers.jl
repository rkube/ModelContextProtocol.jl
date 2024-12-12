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

Base.@kwdef struct ListToolsParams
    cursor::Union{String,Nothing} = nothing
end

"""
Handles initialization requests
"""
function handle_initialize(ctx::RequestContext, params::InitializeParams)::HandlerResult
    
    client_capabilities = params.capabilities
    protocol_version = params.protocolVersion

    # Convert our capabilities to protocol format
    server_capabilities = capabilities_to_protocol(ctx.server.config.capabilities)

    result = InitializeResult(
        serverInfo = Dict(
            "name" => ctx.server.config.name,
            "version" => ctx.server.config.version
        ),
        capabilities = server_capabilities,
        protocolVersion = protocol_version,
        instructions = ctx.server.config.description  # Optional instructions from config
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
        resources = map(ctx.server.resources) do resource
            Dict{String,Any}(
                "uri" => string(resource.uri),
                "name" => resource.name,
                "mimeType" => resource.mime_type,
                "description" => resource.description,  # Keep only one description field
                "annotations" => Dict{String,Any}(
                    "audience" => get(resource.annotations, "audience", ["assistant"]),
                    "priority" => get(resource.annotations, "priority", 0.0)
                )
            )
        end

        # Build result with pagination support
        result = ListResourcesResult(
            resources = resources,
            nextCursor = params.cursor  # Changed from next_cursor to nextCursor
        )

        return HandlerResult(
            response = JSONRPCResponse(
                id = ctx.request_id,
                result = result
            )
        )

    catch e
        return HandlerResult(
            error = ErrorInfo(
                code = ErrorCodes.INTERNAL_ERROR,
                message = "Failed to list resources: $e"
            )
        )
    end
end

"""
Handles resource reading requests
"""
function handle_read_resource(ctx::RequestContext, params::ReadResourceParams)::HandlerResult
    # Find the resource
    resource = findfirst(r -> string(r.uri) == params.uri, ctx.server.resources)

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

        result = ReadResourceResult(
            contents = [Dict{String,Any}(
                "uri" => string(resource.uri),
                "mimeType" => resource.mime_type,
                "text" => JSON3.write(data)
            )]
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
                message = "Failed to read resource: $(e)"
            )
        )
    end
end

"""
Handles tool calls
"""
function handle_call_tool(ctx::RequestContext, params::CallToolParams)::HandlerResult
    # Find the tool's index then get the tool
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
        # Call the tool handler
        result = tool.handler(params.arguments)

        # Convert result to appropriate format for JSON-RPC response
        # Create a TextContent with the result converted to JSON
        content = [Dict{String,Any}(
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
                "description" => tool.description,
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

        result = ListToolsResult(tools = tools)

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
    
    nothing
end

function handle_request(server::Server, request::Request)::Response
    ctx = RequestContext(
        server = server,
        request_id = request.id,
        progress_token = request.meta.progress_token
    )

    try
        # Convert params to appropriate type based on method
        typed_params = if request.method == "initialize"
            params_dict = request.params isa Dict ? request.params : Dict{String,Any}()
            capabilities_dict = get(params_dict, "capabilities", Dict{String,Any}())
            client_info_dict = get(params_dict, "clientInfo", Dict{String,Any}())

            InitializeParams(
                capabilities = ClientCapabilities(;capabilities_dict...),
                clientInfo = Implementation(;client_info_dict...),
                protocolVersion = get(params_dict, "protocolVersion", "1.0")
            )
        elseif request.method == "resources/list"
            params_dict = request.params isa Dict ? request.params : Dict{String,Any}()
            ListResourcesParams(
                cursor = get(params_dict, "cursor", nothing)
            )
        elseif request.method == "resources/read"
            params_dict = request.params isa Dict ? request.params : Dict{String,Any}()
            ReadResourceParams(
                uri = params_dict["uri"]
            )
        elseif request.method == "tools/call"
            params_dict = request.params isa Dict ? request.params : Dict{String,Any}()
            CallToolParams(
                name = params_dict["name"],
                arguments = get(params_dict, "arguments", Dict{String,Any}())
            )
        elseif request.method == "tools/list"
            params_dict = request.params isa Dict ? request.params : Dict{String,Any}()
            ListToolsParams(
                cursor = get(params_dict, "cursor", nothing)
            )
        else
            error("Invalid or missing params for method: $(request.method)")
        end

        # Handle request with typed parameters
        result = if request.method == "initialize"
            handle_initialize(ctx, typed_params::InitializeParams)
        elseif request.method == "resources/list"
            handle_list_resources(ctx, typed_params::ListResourcesParams)
        elseif request.method == "resources/read"
            handle_read_resource(ctx, typed_params::ReadResourceParams)
        elseif request.method == "tools/call"
            handle_call_tool(ctx, typed_params::CallToolParams)
        elseif request.method == "tools/list"
            handle_list_tools(ctx, typed_params::ListToolsParams)
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
            JSONRPCError(
                id = ctx.request_id,
                error = result.error
            )
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

