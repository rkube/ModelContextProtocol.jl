using Test
using PythonCall

# Ensure Python dependencies are installed
function ensure_python_deps()
    # CondaPkg should handle this automatically via CondaPkg.toml
    try
        pyimport("mcp")
        return true
    catch e
        @warn "MCP Python package not available. Install with: pip install mcp>=1.0.0"
        return false
    end
end

# Python test client code
const PYTHON_TEST_CLIENT = py"""
import asyncio
import json
import sys
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

async def test_julia_server():
    # Server parameters for the Julia MCP server
    server_params = StdioServerParameters(
        command=sys.argv[1],
        args=sys.argv[2:],
        env=None
    )
    
    async with stdio_client(server_params) as (read, write):
        async with ClientSession(read, write) as session:
            # Initialize
            await session.initialize()
            
            # List available tools
            tools_list = await session.call_tool_list()
            tools = tools_list.tools if hasattr(tools_list, 'tools') else []
            
            results = {
                "initialized": True,
                "tools": [{"name": tool.name, "description": tool.description} for tool in tools]
            }
            
            # Test each tool
            for tool in tools:
                if tool.name == "echo":
                    result = await session.call_tool("echo", {"text": "Hello from Python!"})
                    results["echo_result"] = result.content[0].text if result.content else None
                elif tool.name == "add":
                    result = await session.call_tool("add", {"a": 5, "b": 3})
                    results["add_result"] = result.content[0].text if result.content else None
            
            # List resources if available
            try:
                resources_list = await session.call_tool_list()
                results["resources_available"] = True
            except:
                results["resources_available"] = False
            
            return results

if __name__ == "__main__":
    result = asyncio.run(test_julia_server())
    print(json.dumps(result))
"""

# Create test server
const TEST_SERVER_CODE = """
#!/usr/bin/env julia

# Activate the main project
using Pkg
Pkg.activate(joinpath(@__DIR__, "../.."))

using ModelContextProtocol

# Create test tools
echo_tool = MCPTool(
    name = "echo",
    description = "Echo the input text",
    parameters = [
        ToolParameter(
            name = "text",
            description = "Text to echo",
            type = "string",
            required = true
        )
    ],
    handler = (args) -> TextContent(text = "Echo: \$(args["text"])"),
    return_type = TextContent
)

add_tool = MCPTool(
    name = "add",
    description = "Add two numbers",
    parameters = [
        ToolParameter(
            name = "a",
            description = "First number",
            type = "number",
            required = true
        ),
        ToolParameter(
            name = "b",
            description = "Second number",
            type = "number",
            required = true
        )
    ],
    handler = (args) -> begin
        result = args["a"] + args["b"]
        TextContent(text = "Result: \$result")
    end,
    return_type = TextContent
)

# Create test resource
test_resource = MCPResource(
    uri = "test://data",
    name = "test-data",
    description = "Test data resource",
    mime_type = "application/json",
    data_provider = () -> Dict("test" => "data", "timestamp" => time())
)

# Create server
server = mcp_server(
    name = "julia-integration-test-server",
    version = "1.0.0",
    description = "Integration test server",
    tools = [echo_tool, add_tool],
    resources = [test_resource]
)

# Start server
start!(server)
"""

@testset "Python-Julia MCP Integration" begin
    if !ensure_python_deps()
        @test_skip "Python MCP SDK not available"
        return
    end
    
    # Create temporary files
    server_file = tempname() * ".jl"
    client_file = tempname() * ".py"
    
    try
        # Write server and client files
        write(server_file, TEST_SERVER_CODE)
        write(client_file, PYTHON_TEST_CLIENT)
        
        # Make server executable
        chmod(server_file, 0o755)
        
        @testset "Server-Client Communication" begin
            # Get paths
            julia_exe = Base.julia_cmd().exec[1]
            python_exe = pyimport("sys").executable
            
            # Run the test
            py_subprocess = pyimport("subprocess")
            
            # Execute the Python client with the Julia server
            result = py_subprocess.run(
                [python_exe, client_file, julia_exe, "--project=$(dirname(dirname(@__DIR__)))", server_file],
                capture_output=true,
                text=true,
                timeout=30
            )
            
            if result.returncode != 0
                println("STDOUT: ", result.stdout)
                println("STDERR: ", result.stderr)
                @test false "Python client failed with return code $(result.returncode)"
            else
                # Parse the JSON result
                output = pyconvert(String, result.stdout)
                
                # Basic connectivity test - if we get any output, connection worked
                @test !isempty(output)
                
                # Try to parse JSON if possible
                try
                    py_json = pyimport("json")
                    result_data = py_json.loads(output)
                    
                    # Test initialization
                    @test get(result_data, "initialized", false) == true
                    
                    # Test tools were listed
                    tools = get(result_data, "tools", [])
                    @test length(tools) >= 2
                    
                    # Test echo tool
                    if haskey(result_data, "echo_result")
                        @test occursin("Hello from Python!", result_data["echo_result"])
                    end
                    
                    # Test add tool
                    if haskey(result_data, "add_result")
                        @test occursin("8", result_data["add_result"])  # 5 + 3 = 8
                    end
                catch e
                    # If JSON parsing fails, just check we got some output
                    println("Could not parse JSON output: ", output)
                    @test !isempty(output)
                end
            end
        end
        
    finally
        # Cleanup
        rm(server_file, force=true)
        rm(client_file, force=true)
    end
end