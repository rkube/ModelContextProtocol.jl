using Test
using PythonCall
using JSON3

# Test basic stdio communication without full MCP SDK
const PYTHON_STDIO_TEST = """
import json
import sys
import subprocess

def test_stdio_communication(julia_exe, server_script):
    \"\"\"Test basic stdio communication with Julia MCP server\"\"\"
    
    # Start the Julia server as a subprocess
    proc = subprocess.Popen(
        [julia_exe, "--project", server_script],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    try:
        # Send a basic JSON-RPC initialize request
        init_request = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "capabilities": {},
                "clientInfo": {"name": "test-client", "version": "1.0"},
                "protocolVersion": "1.0"
            }
        }
        
        # Write request to stdin
        proc.stdin.write(json.dumps(init_request) + '\\n')
        proc.stdin.flush()
        
        # Read response from stdout
        response_line = proc.stdout.readline()
        
        if response_line:
            response = json.loads(response_line)
            return {
                "success": True,
                "response": response,
                "has_result": "result" in response,
                "has_error": "error" in response
            }
        else:
            stderr_output = proc.stderr.read()
            return {
                "success": False,
                "error": "No response received",
                "stderr": stderr_output
            }
            
    finally:
        proc.terminate()
        proc.wait()

# Return the function for Julia to use
test_stdio_communication
"""

# Simple Julia server for testing
const SIMPLE_TEST_SERVER = """
using Pkg
Pkg.activate(joinpath(@__DIR__, "../.."))

using ModelContextProtocol
using JSON3

# Create a minimal server
server = mcp_server(
    name = "stdio-test-server",
    version = "1.0.0",
    description = "Test server for stdio protocol"
)

# Handle JSON-RPC messages from stdin
function handle_stdin_message(server::Server)
    while !eof(stdin)
        line = readline(stdin)
        isempty(line) && continue
        
        try
            # Parse and handle the message
            message = ModelContextProtocol.parse_message(line)
            
            if message isa ModelContextProtocol.JSONRPCRequest
                response = ModelContextProtocol.handle_request(server, message)
                output = ModelContextProtocol.serialize_message(response)
                println(stdout, output)
                flush(stdout)
            end
        catch e
            # Log error to stderr
            println(stderr, "Error handling message: ", e)
            flush(stderr)
        end
    end
end

# Start handling messages
handle_stdin_message(server)
"""

@testset "Stdio Protocol Communication" begin
    # Create test server file
    server_file = tempname() * ".jl"
    
    try
        write(server_file, SIMPLE_TEST_SERVER)
        chmod(server_file, 0o755)
        
        # Get test function from Python
        py_globals = pydict()
        pyexec(PYTHON_STDIO_TEST, py_globals)
        test_func = py_globals["test_stdio_communication"]
        
        # Get Julia executable
        julia_exe = Base.julia_cmd().exec[1]
        
        @testset "Basic JSON-RPC Communication" begin
            # Run the test
            result = test_func(julia_exe, server_file)
            result_dict = pyconvert(Dict, result)
            
            # Check basic communication worked
            @test result_dict["success"] == true
            @test result_dict["has_result"] == true
            @test result_dict["has_error"] == false
            
            # If we got a response, check it has expected structure
            if haskey(result_dict, "response") && result_dict["response"] isa Dict
                response = result_dict["response"]
                @test haskey(response, "jsonrpc")
                @test response["jsonrpc"] == "2.0"
                @test haskey(response, "id")
                @test response["id"] == 1
            end
        end
        
    finally
        rm(server_file, force=true)
    end
end