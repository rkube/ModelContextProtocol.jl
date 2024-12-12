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
    register!(server::Server, component::Union{Tool,Resource})

Register a tool or resource with the server.
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


"""
Process an incoming message and generate appropriate response
"""
function process_message(server::Server, state::ServerState, message::String)::Union{String,Nothing}
    
    # Parse the incoming message
    parsed = try
        @debug "Parsing message"
        parse_message(message)
    catch e
        @debug "Parse error" exception=e
        return serialize_message(JSONRPCError(
            id = nothing,
            error = ErrorInfo(
                code = ErrorCodes.PARSE_ERROR,
                message = "Failed to parse message: $(e)"
            )
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
        
        return serialize_message(JSONRPCError(
            id = id,
            error = ErrorInfo(
                code = ErrorCodes.INTERNAL_ERROR,
                message = "Internal server error: $(e)"
            )
        ))
    end
end

"""
Main server loop - reads from stdin and writes to stdout
"""
function run_server_loop(server::Server, state::ServerState)
    state.running = true
    
    # Set up unbuffered IO
    flush(stdout)
    flush(stderr)
    
    while state.running
        try
            # Read next message
            message = readline()
            
            if isempty(message)
                continue
            end
            
            # Process message
            response = process_message(server, state, message)
    
            # Send response if any
            if !isnothing(response)
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
        throw(ServerError("Server already running"))
    end
    
    state = ServerState()
    
    # Set up logging
    logger = SimpleLogger(stderr)
    global_logger(logger)
    
    @info "Starting MCP server: $(server.config.name)"
    
    try
        run_server_loop(server, state)
    catch e
        server.active = false
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