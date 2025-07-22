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

@testset "Server Component Registration" begin
    # Test data
    test_resource = MCPResource(
        uri=URI("test://example"),
        name="test-resource",
        description="Test resource",
        mime_type="text/plain",
        data_provider=() -> "test data"
    )

    test_tool = MCPTool(
        name="test-tool",
        description="Test tool",
        parameters=[ToolParameter(name="param1", description="Test param", type="string", required=true)],
        handler=args -> "Test response: $(args["param1"])",
        return_type=TextContent
    )

    test_prompt = MCPPrompt(
        name="test-prompt",
        description="A test prompt",
        arguments=[PromptArgument(name="arg1", description="Test arg", required=true)],
        messages=[PromptMessage(
            content=TextContent(type="text", text="Test prompt with {arg1}"),
            role=ModelContextProtocol.user
        )]
    )

    server = Server(ServerConfig(name="test-server"))

    # Register test components
    register!(server, test_resource)
    register!(server, test_tool)
    register!(server, test_prompt)

    @test length(server.resources) == 1
    @test length(server.tools) == 1
    @test length(server.prompts) == 1

    @test server.resources[1].name == "test-resource"
    @test server.tools[1].name == "test-tool"
    @test server.prompts[1].name == "test-prompt"
end