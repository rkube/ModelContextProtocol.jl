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