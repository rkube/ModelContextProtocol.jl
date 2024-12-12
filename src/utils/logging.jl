# src/utils/logging.jl

"""
Custom logger for MCP server that formats messages according to protocol requirements
"""
struct MCPLogger <: AbstractLogger
    stream::IO
    min_level::LogLevel
    message_limits::Dict{Any,Int}
end

function MCPLogger(stream::IO=stderr, level::LogLevel=Info)
    MCPLogger(stream, level, Dict{Any,Int}())
end

Logging.shouldlog(logger::MCPLogger, level, _module, group, id) = level >= logger.min_level

Logging.min_enabled_level(logger::MCPLogger) = logger.min_level

Logging.catch_exceptions(logger::MCPLogger) = false

function Logging.handle_message(logger::MCPLogger, level, message, _module, group, id,
                              filepath, line; kwargs...)
    # Convert log level to MCP protocol level
    mcp_level = if level >= Error
        "error"
    elseif level >= Warn 
        "warning"
    else
        "info"
    end
    
    # Create JSON-RPC formatted log message
    buf = IOBuffer()
    log_message = Dict{String,Any}(
        "jsonrpc" => "2.0",
        "method" => "notifications/message",
        "params" => Dict{String,Any}(
            "level" => mcp_level,
            "data" => Dict{String,Any}(
                "message" => string(message),
                "timestamp" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS"),
                "metadata" => Dict{String,Any}(
                    "module" => string(_module),
                    "file" => string(filepath),
                    "line" => line
                )
            )
        )
    )
    
    # Add any additional context from kwargs
    if !isempty(kwargs)
        log_message["params"]["data"]["metadata"]["context"] = Dict(string(k) => string(v) for (k,v) in kwargs)
    end
    
    # Write to buffer
    JSON3.write(buf, log_message)
    
    # Write to output stream
    println(logger.stream, String(take!(buf)))
    flush(logger.stream)
end

"""
Initialize logging for the MCP server
"""
function init_logging(level::LogLevel=Info)
    logger = MCPLogger(stderr, level)
    global_logger(logger)
end
