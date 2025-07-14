# External Integration Tests

This directory contains integration tests that use external dependencies not included in the main project.

## Setup

1. Activate the test environment:
   ```julia
   using Pkg
   Pkg.activate("test/external")
   Pkg.instantiate()
   ```

2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Running Tests

To run the Python client integration tests:

```julia
using Pkg
Pkg.activate("test/external")
Pkg.test()
```

Or directly:

```bash
julia --project=test/external test/external/test_integration.jl
```

## Test Structure

- `test_python_client.jl` - Basic tests for Python MCP client compatibility
- `test_integration.jl` - Full integration test that spawns a Julia MCP server and tests it with a Python client

## CI Integration

These tests can be run in CI by:
1. Setting up both Julia and Python environments
2. Installing dependencies from both `Project.toml` and `requirements.txt`
3. Running the test files

The tests use subprocess communication to test the stdio transport between Python clients and Julia servers, validating the MCP protocol implementation.