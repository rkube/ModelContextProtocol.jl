#!/usr/bin/env julia

using Pkg
Pkg.activate(@__DIR__)

# Now import all needed packages
using ModelContextProtocol
using Dates
using URIs
using Logging

# Configure more verbose logging
logger = MCPLogger(stderr, Logging.Debug)  # Change from Info to Debug
global_logger(logger)

# Create a resource that provides the current time
current_time_resource = MCPResource(
    uri = URI("time://current"),
    name = "Current Time",
    description = "Returns the current time. Use for any time requests.",
    mime_type = "application/json",
    data_provider = () -> Dict(
        "timestamp" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS"),
        "utc_offset" => Dates.value(Dates.Hour(Dates.value(now() - now(UTC)))),
        "unix_timestamp" => Int(floor(datetime2unix(now())))
    )
)

# Create a tool for formatting dates
format_date_tool = MCPTool(
    name = "format_date",
    description = "Format a date using a specified format string",
    parameters = [
        ToolParameter(
            name = "format",
            type = "string",
            description = "Date format string (e.g., 'yyyy-mm-dd')",
            required = true
        ),
        ToolParameter(
            name = "timestamp",
            type = "string",
            description = "Optional timestamp to format. Defaults to current time.",
            required = false
        )
    ],
    handler = function(params)
        format_str = params["format"]
        timestamp = get(params, "timestamp", nothing)
        
        date = if isnothing(timestamp)
            now()
        else
            # Try to parse the provided timestamp
            try
                DateTime(timestamp)
            catch e
                return Dict(
                    "error" => "Invalid timestamp format. Expected ISO format (e.g., 2024-03-21T14:30:00)"
                )
            end
        end
        
        Dict(
            "formatted" => Dates.format(date, format_str),
            "input_timestamp" => timestamp,
            "format_string" => format_str
        )
    end,
    return_type = Dict{String,Any}
)

# Create a tool that return the current time and date 
current_time_tool = MCPTool(
    name = "current_time",
    description = "Get the current time and date",
    parameters = [],
    handler = function(params)
        Dict(
            "current_time" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS")
        )
    end,
    return_type = Dict{String,Any}
)


# Create and configure server
function create_time_server()
    # Create server config with custom capabilities
    config = ServerConfig(
        name = "time-server",
        version = "1.0.0",
        description = "Provides current time and date formatting utilities. 
            Client should query server for resources and tools.",
        capabilities = [
            ResourceCapability(list_changed = true, subscribe = true),
            ToolCapability(list_changed = true)
        ]
    )
    
    # The server will automatically have all base capabilities, merged with your custom ones
    server = Server(config)
    
    # Log tool registration
    @debug "Registering tools for time server"
    register!(server, current_time_resource)
    @debug "Registered current_time_resource"
    register!(server, format_date_tool)
    @debug "Registered format_date_tool"
    register!(server, current_time_tool)
    @debug "Registered current_time_tool"
    
    return server
end

# Add logging to message handling
function handle_message(server::Server, message::AbstractString)
    @debug "Received message" message
    result = process_message(server, ServerState(), message)
    @debug "Sending response" response=result
    return result
end

# Main entry point
function main()
    # Create server instance
    server = create_time_server()
    
    # Initialize logging
    logger = MCPLogger(stderr, Logging.Info)
    global_logger(logger)
    
    # Start server
    @info "Starting Time Server..."
    start!(server)
end

# Only run if this is the main script
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end