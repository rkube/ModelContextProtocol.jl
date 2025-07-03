using Test

# Run all external integration tests
@testset "External Integration Tests" begin
    @testset "Stdio Protocol Tests" begin
        include("test_stdio_protocol.jl")
    end
    
    @testset "Python Client Tests" begin
        include("test_python_client.jl")
    end
    
    @testset "Full Integration Tests" begin
        include("test_integration.jl") 
    end
end