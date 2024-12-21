# src/server.jl

"""
Server state tracking
"""
mutable struct ServerState
    initialized::Bool
    running::Bool
    last_request_id::Int
    pending_requests::Dict{RequestId, String}  # method name for each pending request
    
    ServerState() = new(false, false, 0, Dict())
end

"""
MCP Server errors
"""
struct ServerError <: Exception
    message::String
end

"""
    register!(server::Server, component::Union{Tool,Resource,MCPPrompt})

Register a tool, resource, or prompt with the server.
"""
function register! end

function register!(server::Server, tool::Tool)
    push!(server.tools, tool)
    server
end

function register!(server::Server, resource::Resource)
    push!(server.resources, resource)
    server
end

function register!(server::Server, prompt::MCPPrompt)
    push!(server.prompts, prompt)
    server
end

"""
Process an incoming message and generate appropriate response
"""
function process_message(server::Server, state::ServerState, message::String)::Union{String,Nothing}
    # Parse the incoming message
    parsed = try
        @debug "Parsing message"
        parse_message(message)
    catch e
        error_info = ErrorInfo(
            code = ErrorCodes.PARSE_ERROR,
            message = "Failed to parse message: $(e)"
        )
        # Log the error
        @error "JSON-RPC error" error_code=ErrorCodes.PARSE_ERROR error_message=error_info.message

        # Return JSON-RPC error response
        return serialize_message(JSONRPCError(
            id = nothing,
            error = error_info
        ))
    end
  
    if parsed isa JSONRPCError
        return serialize_message(parsed)
    end
    
    try
        if parsed isa JSONRPCRequest
            # Handle request
            response = handle_request(server, parsed)
            return serialize_message(response) # Make sure to serialize the response
        elseif parsed isa JSONRPCNotification 
            handle_notification(RequestContext(server=server), parsed)
            return nothing
        end
    catch e
        id = if parsed isa JSONRPCRequest
            parsed.id
        else
            nothing
        end

        error_info = ErrorInfo(
            code = ErrorCodes.INTERNAL_ERROR,
            message = "Internal server error: $(e)"
        )
        # Log the error
        @error "JSON-RPC error" error_code=ErrorCodes.INTERNAL_ERROR error_message=error_info.message request=parsed

        # Return JSON-RPC error response
        return serialize_message(JSONRPCError(
            id = id,
            error = error_info
        ))
    end
end

"""
Main server loop - reads from stdin and writes to stdout
"""
function run_server_loop(server::Server, state::ServerState)
    state.running = true
    
    @debug "Server loop starting"
    flush(stdout)
    flush(stderr)
    
    while state.running
        try
            message = readline()
            @debug "Processing message" raw=message
            response = process_message(server, state, message)
            
            if !isnothing(response)
                @debug "Sending response" response=response
                println(response)
                flush(stdout)
            end
        catch e
            if e isa InterruptException
                @info "Server shutting down..."
                break
            end
            
            @error "Error processing message" exception=e
            
            # Try to send error response
            try
                error_response = serialize_message(JSONRPCError(
                    id = nothing,
                    error = ErrorInfo(
                        code = ErrorCodes.INTERNAL_ERROR,
                        message = "Internal server error: $(e)"
                    )
                ))
                println(error_response)
                flush(stdout)
            catch response_error
                @error "Failed to send error response" exception=response_error
            end
        end
    end
end

"""
Start the server
"""
function start!(server::Server)::Nothing
    if server.active
        # Use MCPLogger format for errors
        @error "Server already running"
        throw(ServerError("Server already running"))
    end
    
    state = ServerState()
    
    # Set up MCP-compliant logging
    logger = MCPLogger(stderr, Logging.Info)
    global_logger(logger)
    
    @info "Starting MCP server: $(server.config.name)"
    
    try
        run_server_loop(server, state)
    catch e
        server.active = false
        @error "Server error" exception=e
        rethrow(e)
    finally
        server.active = false
        @info "Server stopped"
    end
    
    nothing
end

"""
Stop the server
"""
function stop!(server::Server)
    if !server.active
        throw(ServerError("Server not running"))
    end
    
    server.active = false
    nothing
end

"""
Subscribe to updates for a specific resource URI
"""
function subscribe!(server::Server, uri::String, callback::Function)
    subscription = Subscription(uri, callback, now())
    push!(server.subscriptions[uri], subscription)
    server
end

"""
Remove a subscription for a specific resource URI and callback
"""
function unsubscribe!(server::Server, uri::String, callback::Function)
    filter!(s -> s.callback !== callback, server.subscriptions[uri])
    server
end

"""
    default_capabilities() -> Vector{Capability}

Return the default set of server capabilities.
"""
function default_capabilities()
    [
        ResourceCapability(list_changed=true, subscribe=true),
        ToolCapability(list_changed=true),
        PromptCapability(list_changed=true)  # Added prompt capability
    ]
end

"""
    mcp_server(; name, version="1.0.0", tools=nothing, resources=nothing, prompts=nothing, description="") -> Server

Create and configure an MCP server with the given components.
"""
function mcp_server(;
    name::String,
    version::String = "1.0.0", 
    tools::Union{Vector{MCPTool}, MCPTool, Nothing} = nothing,
    resources::Union{Vector{MCPResource}, MCPResource, Nothing} = nothing,
    prompts::Union{Vector{MCPPrompt}, MCPPrompt, Nothing} = nothing,  # Added prompts parameter
    description::String = "",
    capabilities::Vector{Capability} = default_capabilities()
)
    # Create server config
    config = ServerConfig(
        name = name,
        version = version,
        description = description,
        capabilities = capabilities
    )
    
    # Create server
    server = Server(config)
    
    # Register tools if provided
    if !isnothing(tools)
        foreach(t -> register!(server, t), tools isa Vector ? tools : [tools])
    end
    
    # Register resources if provided
    if !isnothing(resources)
        foreach(r -> register!(server, r), resources isa Vector ? resources : [resources])
    end
    
    # Register prompts if provided
    if !isnothing(prompts)
        foreach(p -> register!(server, p), prompts isa Vector ? prompts : [prompts])
    end
    
    return server
end