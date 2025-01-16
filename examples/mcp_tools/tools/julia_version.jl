
# examples/mcp_tools/julia_version.jl
using JSON3

# Define a tool 
julia_version_tool = MCPTool(
    name = "julia_version",
    description = "Get the Julia version used to run this tool",
    parameters = [],
    handler = params -> TextContent(
        type = "text",
        text = JSON3.write(Dict("version" => string(VERSION)))
        )
)

