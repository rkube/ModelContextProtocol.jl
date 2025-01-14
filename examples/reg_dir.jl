# examples/reg_dir.jl

using Pkg
Pkg.activate(@__DIR__)

using Revise
using ModelContextProtocol

# Tool dependencies
using Dates

# Create and start server with all components
server = mcp_server(
    name = "mcp_tools_directory",
    description = "example mcp tools",
    auto_register_dir="examples\\mcp_tools"
)

# Start the server
start!(server)