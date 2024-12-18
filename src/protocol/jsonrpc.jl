# src/protocol/jsonrpc.jl

const REQUEST_PARAMS_MAP = Dict{String,Type}(
    "initialize" => InitializeParams,
    "resources/list" => ListResourcesParams,
    "resources/read" => ReadResourceParams,
    "tools/call" => CallToolParams,
    "tools/list" => ListToolsParams,  # Add this line
    "notifications/progress" => ProgressParams
)

"""
Get the parameter type for a given method
"""
function get_params_type(method::String)::Union{Type,Nothing}
    get(REQUEST_PARAMS_MAP, method, nothing)
end

"""
Get the expected result type for a request ID (needs to be implemented based on request tracking)
"""
function get_result_type(id::RequestId)::Union{Type{<:ResponseResult},Nothing}
    # This would need to track request types to know what response type to expect
    nothing
end

"""
Parse a JSON-RPC message string into appropriate message type
"""
function parse_message(json::String)::MCPMessage
    raw = try
        JSON3.read(json)
    catch e
        return JSONRPCError(
            id = nothing,
            error = ErrorInfo(
                code = ErrorCodes.PARSE_ERROR,
                message = "Invalid JSON: $(e)"
            )
        )
    end
    
    # Validate basic JSON-RPC structure
    if !haskey(raw, :jsonrpc) || raw.jsonrpc != "2.0"
        return JSONRPCError(
            id = get(raw, :id, nothing),
            error = ErrorInfo(
                code = ErrorCodes.INVALID_REQUEST,
                message = "Invalid JSON-RPC: missing or invalid jsonrpc version"
            )
        )
    end
    
    # Parse based on message type
    try
        if haskey(raw, :method)
            # Request or notification
            if haskey(raw, :id)
                parse_request(raw)
            else
                parse_notification(raw)
            end
        elseif haskey(raw, :result)
            parse_success_response(raw)
        elseif haskey(raw, :error)
            parse_error_response(raw)
        else
            JSONRPCError(
                id = get(raw, :id, nothing),
                error = ErrorInfo(
                    code = ErrorCodes.INVALID_REQUEST,
                    message = "Invalid JSON-RPC message structure"
                )
            )
        end
    catch e
        JSONRPCError(
            id = get(raw, :id, nothing),
            error = ErrorInfo(
                code = ErrorCodes.INTERNAL_ERROR,
                message = "Error parsing message: $(e)"
            )
        )
    end
end

"""
Parse a JSON-RPC request
"""
function parse_request(raw::JSON3.Object)::Request
    method = raw.method
    params_type = get_params_type(method)
    
    typed_params = if !isnothing(params_type) && haskey(raw, :params)
        if isempty(raw.params)
            params_type()  # Construct default instance instead of nothing
        else
            JSON3.read(JSON3.write(raw.params), params_type)
        end
    else
        nothing
    end
    
    JSONRPCRequest(
        id = raw.id,
        method = method,
        params = typed_params
    )
end

"""
Parse a JSON-RPC notification
"""
function parse_notification(raw::JSON3.Object)::Notification
    method = raw.method
    params = if haskey(raw, :params)
        # Handle empty params object case
        isempty(raw.params) ? Dict{String,Any}() : raw.params
    else
        Dict{String,Any}() 
    end
    
    # Parse method-specific parameters
    typed_params = try
        params_type = get_params_type(method)
        if params_type === nothing || isempty(params)
            params
        else
            JSON3.read(JSON3.write(params), params_type)
        end
    catch e
        # Notifications can't return errors, so just use raw params
        params
    end
    
    JSONRPCNotification(
        method = method,
        params = typed_params
    )
end

"""
Parse a successful JSON-RPC response
"""
function parse_success_response(raw::JSON3.Object)::Response
    result_type = get_result_type(raw.id)
    
    typed_result = if result_type !== nothing
        try
            JSON3.read(JSON3.write(raw.result), result_type)
        catch e
            return JSONRPCError(
                id = raw.id,
                error = ErrorInfo(
                    code = ErrorCodes.INTERNAL_ERROR,
                    message = "Failed to parse result: $(e)"
                )
            )
        end
    else
        raw.result
    end
    
    JSONRPCResponse(
        id = raw.id,
        result = typed_result
    )
end

"""
Parse a JSON-RPC error response
"""
function parse_error_response(raw::JSON3.Object)::Response
    JSONRPCError(
        id = raw.id,
        error = JSON3.read(JSON3.write(raw.error), ErrorInfo)
    )
end

"""
Serialize an MCP message to JSON string
"""
function serialize_message(msg::MCPMessage)::String
    if msg isa JSONRPCRequest
        dict = Dict{String,Any}(
            "jsonrpc" => "2.0",
            "id" => msg.id,
            "method" => msg.method
        )
        
        # Add params if present
        if !isnothing(msg.params)
            dict["params"] = msg.params
        end
        
        # Add metadata if present
        if !isnothing(msg.meta.progress_token)
            if !haskey(dict, "params")
                dict["params"] = Dict{String,Any}()
            end
            if dict["params"] isa Dict
                dict["params"]["_meta"] = Dict{String,Any}(
                    "progressToken" => msg.meta.progress_token
                )
            end
        end
        
        return JSON3.write(dict)
        
    elseif msg isa JSONRPCResponse
        return JSON3.write(Dict{String,Any}(
            "jsonrpc" => "2.0",
            "id" => msg.id,
            "result" => msg.result
        ))
        
    elseif msg isa JSONRPCError
        return JSON3.write(Dict{String,Any}(
            "jsonrpc" => "2.0",
            "id" => msg.id,
            "error" => msg.error
        ))
        
    elseif msg isa JSONRPCNotification
        dict = Dict{String,Any}(
            "jsonrpc" => "2.0",
            "method" => msg.method
        )
        
        if !isnothing(msg.params)
            dict["params"] = msg.params
        end
        
        return JSON3.write(dict)
    else
        throw(ArgumentError("Unknown message type: $(typeof(msg))"))
    end
end
