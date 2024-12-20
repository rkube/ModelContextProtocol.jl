# example_server.jl

using Pkg
Pkg.activate(@__DIR__)


using ModelContextProtocol
using Dates

# Define a tool
format_tool = MCPTool(
    name = "current_time",
    description = "Get Current Date and Time",
    parameters = [],
    handler = params -> Dict("time" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS"))
)

# Define a resource using string URI
time_resource = MCPResource(
    uri = "time://current",  
    name = "Current Time",
    description = "Returns current time",
    data_provider = () -> Dict("time" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS"))
)

# Start server with single tool and resource
mcp_server(
    name = "time-server",
    description = "Time formatting service",
    tools = format_tool,
    resources = time_resource
) |> start!