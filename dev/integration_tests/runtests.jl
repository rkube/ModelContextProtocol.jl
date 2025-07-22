using Test

# Run all external integration tests
@testset "External Integration Tests" begin
    @testset "Basic Stdio Tests" begin
        include("test_basic_stdio.jl")
    end
    
    # These tests require the Python MCP SDK which may not be available
    # or may have API changes
    if get(ENV, "RUN_PYTHON_INTEGRATION_TESTS", "false") == "true"
        @testset "Stdio Protocol Tests" begin
            include("test_stdio_protocol.jl")
        end
        
        @testset "Python Client Tests" begin
            include("test_python_client.jl")
        end
        
        @testset "Full Integration Tests" begin
            include("test_integration.jl") 
        end
    else
        @info "Skipping Python integration tests. Set RUN_PYTHON_INTEGRATION_TESTS=true to run them."
    end
end