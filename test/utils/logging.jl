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