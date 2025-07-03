# test_calltoolresult_return.jl

using Test
using ModelContextProtocol
using ModelContextProtocol: handle_call_tool, RequestContext, CallToolParams, CallToolResult
using JSON3
using Base64: base64encode

@testset "CallToolResult return type" begin
    # Create a server with tools that return CallToolResult directly
    config = ServerConfig(
        name = "test-server",
        version = "1.0.0"
    )
    server = Server(config)
    
    # Register tools
    tools = [
            # Tool that returns success CallToolResult
            MCPTool(
                name = "success_tool",
                description = "Returns a successful CallToolResult",
                parameters = [
                    ToolParameter(
                        name = "message",
                        description = "Message to return",
                        type = "string"
                    )
                ],
                handler = function(params)
                    msg = get(params, "message", "Success!")
                    CallToolResult(
                        content = [Dict{String,Any}(
                            "type" => "text",
                            "text" => msg
                        )],
                        is_error = false
                    )
                end
            ),
            
            # Tool that returns error CallToolResult
            MCPTool(
                name = "error_tool",
                description = "Returns an error CallToolResult",
                parameters = [],
                handler = function(params)
                    CallToolResult(
                        content = [Dict{String,Any}(
                            "type" => "text",
                            "text" => "An error occurred"
                        )],
                        is_error = true
                    )
                end
            ),
            
            # Tool that returns CallToolResult with multiple content items
            MCPTool(
                name = "multi_content_tool",
                description = "Returns CallToolResult with multiple content items",
                parameters = [],
                handler = function(params)
                    CallToolResult(
                        content = [
                            Dict{String,Any}(
                                "type" => "text",
                                "text" => "First item"
                            ),
                            Dict{String,Any}(
                                "type" => "text",
                                "text" => "Second item"
                            ),
                            Dict{String,Any}(
                                "type" => "image",
                                "data" => base64encode([0x89, 0x50, 0x4E, 0x47]),
                                "mimeType" => "image/png"
                            )
                        ],
                        is_error = false
                    )
                end
            )
        ]
    
    # Register all tools
    for tool in tools
        register!(server, tool)
    end
    
    @testset "Success CallToolResult" begin
        ctx = RequestContext(
            server = server,
            request_id = 1
        )
        
        params = CallToolParams(
            name = "success_tool",
            arguments = Dict{String,Any}("message" => "Hello from test!")
        )
        
        result = handle_call_tool(ctx, params)
        
        @test !isnothing(result.response)
        @test isnothing(result.error)
        @test result.response.result isa CallToolResult
        @test result.response.result.is_error == false
        @test length(result.response.result.content) == 1
        @test result.response.result.content[1]["type"] == "text"
        @test result.response.result.content[1]["text"] == "Hello from test!"
    end
    
    @testset "Error CallToolResult" begin
        ctx = RequestContext(
            server = server,
            request_id = 2
        )
        
        params = CallToolParams(
            name = "error_tool",
            arguments = nothing
        )
        
        result = handle_call_tool(ctx, params)
        
        @test !isnothing(result.response)
        @test isnothing(result.error)
        @test result.response.result isa CallToolResult
        @test result.response.result.is_error == true
        @test length(result.response.result.content) == 1
        @test result.response.result.content[1]["type"] == "text"
        @test result.response.result.content[1]["text"] == "An error occurred"
    end
    
    @testset "Multi-content CallToolResult" begin
        ctx = RequestContext(
            server = server,
            request_id = 3
        )
        
        params = CallToolParams(
            name = "multi_content_tool",
            arguments = nothing
        )
        
        result = handle_call_tool(ctx, params)
        
        @test !isnothing(result.response)
        @test isnothing(result.error)
        @test result.response.result isa CallToolResult
        @test result.response.result.is_error == false
        @test length(result.response.result.content) == 3
        @test result.response.result.content[1]["type"] == "text"
        @test result.response.result.content[1]["text"] == "First item"
        @test result.response.result.content[2]["type"] == "text"
        @test result.response.result.content[2]["text"] == "Second item"
        @test result.response.result.content[3]["type"] == "image"
        @test result.response.result.content[3]["mimeType"] == "image/png"
    end
end