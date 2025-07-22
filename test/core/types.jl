@testset "Core Types" begin
    @test TextContent(type="text", text="test").text == "test"
    @test ImageContent(type="image", data=UInt8[], mime_type="image/png").mime_type == "image/png"
    @test PromptMessage(content=TextContent(type="text", text="test"), role=ModelContextProtocol.user).role == ModelContextProtocol.user
end