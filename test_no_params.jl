#!/usr/bin/env julia

using ModelContextProtocol
using JSON3

# Create a tool with no parameters
no_params_tool = MCPTool(
    name = "get_time",
    description = "Get the current time",
    parameters = [],  # No parameters
    handler = (args) -> TextContent(text = "Current time: $(now())"),
    return_type = TextContent
)

# Create server
server = mcp_server(
    name = "test-no-params",
    version = "1.0.0",
    description = "Test server with no-params tool",
    tools = [no_params_tool]
)

# Simulate what handle_list_tools returns
ctx = ModelContextProtocol.RequestContext(
    server = server,
    request_id = 1
)

result = ModelContextProtocol.handle_list_tools(ctx, ModelContextProtocol.ListToolsParams())

println("Tool list response:")
println(JSON3.pretty(result.response.result))

# Check the actual inputSchema
tool_schema = result.response.result["tools"][1]["inputSchema"]
println("\nInput schema for no-params tool:")
println(JSON3.pretty(tool_schema))

println("\nProperties: ", tool_schema["properties"])
println("Required: ", tool_schema["required"])
println("Is properties empty? ", isempty(tool_schema["properties"]))
println("Is required empty? ", isempty(tool_schema["required"]))