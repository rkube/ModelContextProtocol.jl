
# examples/mcp_tools/julia_version.jl

# Define a tool 
julia_version_tool = MCPTool(
    name = "julia_version",
    description = "Get the Julia version used to run this tool",
    parameters = [],
    handler = params -> Dict("version" => string(VERSION))
)

