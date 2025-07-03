using Test
using ModelContextProtocol
using JSON3

@testset "Multi-Content Tool Tests" begin
    # Test tool that returns a single content item but expects it wrapped in a vector
    single_tool = MCPTool(
        name = "single_content",
        description = "Returns single content",
        parameters = [],
        handler = (args) -> TextContent(text = "Single response"),
        return_type = Vector{Content}  # Explicitly expect vector
    )
    
    # Test tool that returns multiple content items
    multi_tool = MCPTool(
        name = "multi_content", 
        description = "Returns multiple content items",
        parameters = [],
        handler = (args) -> [
            TextContent(text = "First item"),
            ImageContent(data = Vector{UInt8}([0x00]), mime_type = "image/png"),
            TextContent(text = "Third item")
        ],
        return_type = Vector{Content}  # Explicitly expect vector
    )
    
    # Test tool with mixed return types
    mixed_tool = MCPTool(
        name = "mixed_content",
        description = "Can return single or multiple items",
        parameters = [
            ToolParameter(name = "count", description = "Number of items to return", type = "number", required = true)
        ],
        handler = function(params)
            count = params["count"]
            if count == 1
                return TextContent(text = "Single item")
            else
                return [TextContent(text = "Item $i") for i in 1:count]
            end
        end,
        return_type = Union{TextContent, Vector{Content}}  # Explicitly handle both types
    )
    
    # Create a test server
    server = mcp_server(
        name = "test-server",
        version = "1.0.0",
        description = "Test server for multi-content tools",
        tools = [single_tool, multi_tool, mixed_tool]
    )
    
    # Create request context
    ctx = ModelContextProtocol.RequestContext(
        server = server,
        request_id = "test-1"
    )
    
    @testset "Single content return" begin
        params = ModelContextProtocol.CallToolParams(
            name = "single_content",
            arguments = nothing
        )
        
        result = ModelContextProtocol.handle_call_tool(ctx, params)
        @test !isnothing(result.response)
        @test isnothing(result.error)
        
        content = result.response.result.content
        @test length(content) == 1
        @test content[1]["type"] == "text"
        @test content[1]["text"] == "Single response"
    end
    
    @testset "Multiple content return" begin
        params = ModelContextProtocol.CallToolParams(
            name = "multi_content",
            arguments = nothing
        )
        
        result = ModelContextProtocol.handle_call_tool(ctx, params)
        @test !isnothing(result.response)
        @test isnothing(result.error)
        
        content = result.response.result.content
        @test length(content) == 3
        @test content[1]["type"] == "text"
        @test content[1]["text"] == "First item"
        @test content[2]["type"] == "image"
        @test content[2]["mimeType"] == "image/png"
        @test content[3]["type"] == "text"
        @test content[3]["text"] == "Third item"

        @test contains(JSON3.write(result.response.result), "Third item")
        @test contains(JSON3.write(result.response.result), "image/png")
    end
    
    @testset "Mixed return types" begin
        # Test single return
        params = ModelContextProtocol.CallToolParams(
            name = "mixed_content",
            arguments = Dict("count" => 1)
        )
        
        result = ModelContextProtocol.handle_call_tool(ctx, params)
        @test !isnothing(result.response)
        content = result.response.result.content
        @test length(content) == 1
        @test content[1]["text"] == "Single item"
        
        # Test multiple return
        params = ModelContextProtocol.CallToolParams(
            name = "mixed_content",
            arguments = Dict("count" => 3)
        )
        
        result = ModelContextProtocol.handle_call_tool(ctx, params)
        @test !isnothing(result.response)
        content = result.response.result.content
        @test length(content) == 3
        @test all(c["type"] == "text" for c in content)
        @test content[2]["text"] == "Item 2"
    end
    
    @testset "Content with embedded resources" begin
        resource_tool = MCPTool(
            name = "resource_content",
            description = "Returns content with embedded resource",
            parameters = [],
            handler = (args) -> [
                TextContent(text = "Here's a resource:"),
                EmbeddedResource(
                    resource = TextResourceContents(
                        uri = "test://resource",
                        text = "Resource data",
                        mime_type = "text/plain"
                    ),
                    annotations = Dict("priority" => "high")
                )
            ],
            return_type = Vector{Content}
        )
        
        server.tools = push!(server.tools, resource_tool)
        
        params = ModelContextProtocol.CallToolParams(
            name = "resource_content",
            arguments = nothing
        )
        
        result = ModelContextProtocol.handle_call_tool(ctx, params)
        @test !isnothing(result.response)
        
        content = result.response.result.content
        @test length(content) == 2
        @test content[1]["type"] == "text"
        @test content[2]["type"] == "resource"
        @test content[2]["resource"]["uri"] == "test://resource"
        @test content[2]["resource"]["text"] == "Resource data"
        @test content[2]["annotations"]["priority"] == "high"
    end
end