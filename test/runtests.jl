using Test
using ModelContextProtocol
using ModelContextProtocol: handle_initialize, handle_read_resource, handle_list_resources, handle_get_prompt, handle_ping
using JSON3, URIs, DataStructures
using Logging

# Test data
const TEST_PROMPT = MCPPrompt(
    name="test-prompt",
    description="A test prompt",
    arguments=[PromptArgument(name="arg1", description="Test arg", required=true)],
    messages=[PromptMessage(
        content=TextContent(type="text", text="Test prompt with {arg1}"),
        role=ModelContextProtocol.user
    )]
)

const TEST_RESOURCE = MCPResource(
    uri=URI("test://example"),
    name="test-resource",
    description="Test resource",
    mime_type="text/plain",
    data_provider=() -> "test data"
)

const TEST_TOOL = MCPTool(
    name="test-tool",
    description="Test tool",
    parameters=[ToolParameter(name="param1", description="Test param", type="string", required=true)],
    handler=args -> "Test response: $(args["param1"])",
    return_type=TextContent  # Explicitly specify return type
)


@testset "ModelContextProtocol.jl" begin
    @testset "Core Types" begin
        @test TextContent(type="text", text="test").text == "test"
        @test ImageContent(type="image", data=UInt8[], mime_type="image/png").mime_type == "image/png"
        @test PromptMessage(content=TextContent(type="text", text="test"), role=ModelContextProtocol.user).role == ModelContextProtocol.user
    end

    @testset "Server Configuration" begin
        config = ServerConfig(
            name="test-server",
            version="1.0.0",
            capabilities=[
                ResourceCapability(list_changed=true),
                ToolCapability(list_changed=true)
            ]
        )

        @test config.name == "test-server"
        @test length(config.capabilities) == 2
        @test config.capabilities[1] isa ResourceCapability

        # Test server creation
        server = Server(config)
        @test server.config.name == "test-server"
        @test !server.active
    end

    @testset "Message Parsing" begin
        # Test parsing initialize request
        init_req = """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "capabilities": {},
                "clientInfo": {"name": "test", "version": "1.0"},
                "protocolVersion": "1.0"
            }
        }
        """
        parsed = ModelContextProtocol.parse_message(init_req)
        @test parsed isa JSONRPCRequest
        @test parsed.method == "initialize"

        # Test parsing error response
        error_resp = """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "error": {
                "code": -32600,
                "message": "Invalid Request"
            }
        }
        """
        parsed = ModelContextProtocol.parse_message(error_resp)
        @test parsed isa JSONRPCError
        @test parsed.error.code == -32600
    end

    @testset "Request Handling" begin
        server = Server(ServerConfig(name="test"))
        ctx = RequestContext(server=server)

        # Test initialize request handling
        init_params = InitializeParams(
            capabilities=ClientCapabilities(),
            clientInfo=Implementation(),
            protocolVersion="1.0"
        )
        ctx = RequestContext(server=server, request_id=1)  # Set a valid request ID
        result = handle_initialize(ctx, init_params)
        @test result isa HandlerResult
        @test !isnothing(result.response)
        @test result.response.id == 1

        # Test list resources handling
        list_params = ListResourcesParams()
        result = handle_list_resources(ctx, list_params)
        @test result isa HandlerResult
        @test !isnothing(result.response)

        # Ping requests
        ctx = RequestContext(server=server, request_id=2)
        result = handle_ping(ctx, nothing)
        @test result isa HandlerResult
        @test !isnothing(result.response)
        @test result.response.id == 2
        @test isempty(result.response.result)
    end

    @testset "Template Processing" begin
        # Create and configure server first
        server = Server(ServerConfig(name="test"))
        register!(server, TEST_PROMPT)  # Register the test prompt
        
        @test TEST_PROMPT.messages[1].content.text == "Test prompt with {arg1}"
        
        # Test prompt template with arguments
        args = Dict("arg1" => "World")
        ctx = RequestContext(server=server, request_id=1)
        result = handle_get_prompt(ctx, GetPromptParams(name="test-prompt", arguments=args))
        
        @test result isa HandlerResult
        @test !isnothing(result.response)
        @test result.response isa JSONRPCResponse
        @test result.response.result isa GetPromptResult
        @test result.response.result.messages[1].content.text == "Test prompt with World"
    end

    @testset "Error Handling" begin
        # Test resource not found error
        server = Server(ServerConfig(name="test"))
        ctx = RequestContext(server=server)
        result = handle_read_resource(ctx, ReadResourceParams(uri="invalid://uri"))
        @test result.error.code == ErrorCodes.RESOURCE_NOT_FOUND

        # Test invalid params error
        result = handle_get_prompt(ctx, GetPromptParams(name="non-existent"))
        @test result.error.code == ErrorCodes.PROMPT_NOT_FOUND
    end

    @testset "Logging" begin
        # Test MCP logger
        buf = IOBuffer()
        logger = MCPLogger(buf)

        with_logger(logger) do
            @info "Test message"
        end

        log_output = String(take!(buf))
        @test occursin("notifications/message", log_output)
        @test occursin("test message", lowercase(log_output))
    end

    @testset "Server Component Registration" begin
        server = Server(ServerConfig(name="test-server"))

        # Register test components
        register!(server, TEST_RESOURCE)
        register!(server, TEST_TOOL)
        register!(server, TEST_PROMPT)

        @test length(server.resources) == 1
        @test length(server.tools) == 1
        @test length(server.prompts) == 1

        @test server.resources[1].name == "test-resource"
        @test server.tools[1].name == "test-tool"
        @test server.prompts[1].name == "test-prompt"
    end

    @testset "Integration Tests" begin
        # Create a server with all components
        config = ServerConfig(
            name="test-server",
            version="1.0.0",
            capabilities=[
                ResourceCapability(list_changed=true, subscribe=true),
                ToolCapability(list_changed=true),
                PromptCapability(list_changed=true)
            ]
        )

        server = Server(config)
        register!(server, TEST_RESOURCE)
        register!(server, TEST_TOOL)
        register!(server, TEST_PROMPT)

        # Test full initialization sequence
        init_req = JSONRPCRequest(
            id=1,
            method="initialize",
            params=InitializeParams(
                capabilities=ClientCapabilities(),
                clientInfo=Implementation(name="test-client"),
                protocolVersion="1.0"
            )
        )

        ctx = RequestContext(server=server, request_id=init_req.id)
        result = handle_initialize(ctx, init_req.params)

        @test result isa HandlerResult
        @test !isnothing(result.response)
        @test result.response.result isa InitializeResult
        @test haskey(result.response.result.capabilities, "resources")

        # Test resource reading
        read_req = JSONRPCRequest(
            id=2,
            method="resources/read",
            params=ReadResourceParams(uri="test://example")
        )

        ctx = RequestContext(server=server, request_id=read_req.id)
        result = handle_read_resource(ctx, read_req.params)

        @test result isa HandlerResult
        @test !isnothing(result.response)
        @test result.response.result isa ReadResourceResult
    end
    
    # Include multi-content tests
    include("test_multi_content.jl")
    
    # Include null params tests - some clients like Cursor send null params for list requests
    include("test_null_params.jl")
    
    # Include CallToolResult return type tests
    include("test_calltoolresult_return.jl")
    
    # Include content2dict tests
    include("test_content2dict.jl")
end