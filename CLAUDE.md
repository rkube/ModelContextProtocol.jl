# ModelContextProtocol.jl Development Guide

## Commands
- Build: `using Pkg; Pkg.build("ModelContextProtocol")`
- Test all: `using Pkg; Pkg.test("ModelContextProtocol")`
- Test single: `julia --project -e 'using Pkg; Pkg.test("ModelContextProtocol", test_args=["specific_test.jl"])'`
- Documentation: `julia --project=docs docs/make.jl`
- Documentation deployment: Automatic via GitHub Actions on push to main
- REPL: `using ModelContextProtocol` after activating project
- Example server: `julia --project examples/multi_content_tool.jl`

## Code Style
- Imports: Group related imports (e.g., `using JSON3, URIs, DataStructures`)
- Types: Use abstract type hierarchy, concrete types with `Base.@kwdef`
- Naming: 
  - PascalCase for types (e.g., `MCPTool`, `TextContent`)
  - snake_case for functions and variables (e.g., `mcp_server`, `request_id`)
  - Use descriptive names that reflect purpose
- Documentation: 
  - Add full docstrings for all types and methods
  - Use imprative phrasing for the one line description in docstrings "Scan a directory" not "Scans a directory"
  - Use triple quotes with function signature at top including all parameters and return type:
    ```julia
    """
        function_name(param1::Type1, param2::Type2) -> ReturnType
    
    Brief, one line imperative phrase of the function's action.
    
    # Arguments
    - `param1::Type1`: Description of the first parameter
    - `param2::Type2`: Description of the second parameter
    
    # Returns
    - `ReturnType`: Description of the return value
    """
    ```
  - For structs and types, include the constructor pattern and all fields:
    ```julia
    """
        StructName(; field1::Type1=default1, field2::Type2=default2)
    
    Description of the struct's purpose.
    
    # Fields
    - `field1::Type1`: Description of the first field
    - `field2::Type2`: Description of the second field
    """
    ```
  - Include a concise description after the signature
  - Always separate sections with blank lines
  - No examples block required 
- Error handling: Use `ErrorCodes` enum for structured error reporting
- Organization: Follow modular structure with core, features, protocol, utils
- Type annotations: Use for function parameters and struct fields
- Constants: Use UPPER_CASE for true constants

## Key Features
- **Multi-Content Tool Returns**: Tools can return either a single `Content` object or a `Vector{<:Content}` for multiple items
  - Single: `return TextContent(text = "result")`
  - Multiple: `return [TextContent(text = "item1"), ImageContent(data = ..., mime_type = "image/png")]`
  - Mixed content types in same response supported
  - Default `return_type` is `Vector{Content}` - single items are auto-wrapped
  - Set `return_type = TextContent` to validate single content returns