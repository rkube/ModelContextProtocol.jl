#!/usr/bin/env julia

using Pkg
Pkg.activate(@__DIR__)

# Ensure required packages are installed
let required_packages = ["JSON3", "URIs", "DataStructures"]
    installed = Pkg.project().dependencies |> keys |> collect
    missing = setdiff(required_packages, installed)
    if !isempty(missing)
        @info "Installing required packages: $(join(missing, ", "))"
        Pkg.add(missing)
    end
end

# For development, use the local package
pkg_path = normpath(joinpath(@__DIR__, ".."))
Pkg.develop(PackageSpec(path=pkg_path))

# Now import all needed packages
using ModelContextProtocol
using Dates
using URIs
using Logging

# Create a resource that provides the current time
current_time_resource = MCPResource(
    uri = URI("time://current"),
    name = "Current Time",
    description = "Returns the current time",
    mime_type = "application/json",
    data_provider = () -> Dict(
        "timestamp" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS"),
        "timezone" => string(timezone(now())),
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

# Create and configure server
function create_time_server()
    config = ServerConfig(
        name = "time-server",
        version = "1.0.0",
        description = "Provides current time and date formatting utilities",
        capabilities = [
            ResourceCapability(list_changed = true, subscribe = true),
            ToolCapability(list_changed = true)
        ]
    )
    
    server = Server(config)
    
    # Register our resource and tool
    register!(server, current_time_resource)
    register!(server, format_date_tool)
    
    return server
end

# Main entry point
function main()
    # Create server instance
    server = create_time_server()
    
    # Initialize logging
    logger = SimpleLogger(stderr, Logging.Info)
    global_logger(logger)
    
    # Start server
    @info "Starting Time Server..."
    start!(server)
end

# Only run if this is the main script
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end