# MCP Tools

Tools represent callable functions that language models can invoke. Each tool has a name, description, parameters, and a handler function.

## Tool Structure

Every tool in ModelContextProtocol.jl is represented by the `MCPTool` struct, which contains:

- `name`: Unique identifier for the tool
- `description`: Human-readable explanation of the tool's purpose
- `parameters`: List of input parameters the tool accepts
- `handler`: Function that executes when the tool is called
- `return_type`: The type of content the tool returns (defaults to `TextContent`)

## Creating Tools

Here's how to create a basic tool:

```julia
calculator_tool = MCPTool(
    name = "calculate",
    description = "Perform basic arithmetic",
    parameters = [
        ToolParameter(
            name = "expression",
            type = "string",
            description = "Math expression to evaluate",
            required = true
        )
    ],
    handler = params -> TextContent(
        text = JSON3.write(Dict(
            "result" => eval(Meta.parse(params["expression"]))
        ))
    )
)
```

## Parameters

Tool parameters are defined using the `ToolParameter` struct:

- `name`: Parameter identifier
- `description`: Explanation of the parameter
- `type`: JSON schema type (e.g., "string", "number", "boolean")
- `required`: Whether the parameter must be provided (default: false)

## Return Values

Tools must return one of the following content types:

- `TextContent`: For text-based responses
- `ImageContent`: For binary image data

## Registering Tools

Tools can be registered with a server in two ways:

1. During server creation:
```julia
server = mcp_server(
    name = "my-server",
    tools = my_tool  # Single tool or vector of tools
)
```

2. After server creation:
```julia
register!(server, my_tool)
```

## Directory-Based Organization

Tools can be organized in directory structures and auto-registered:

```
my_server/
└── tools/
    ├── calculator.jl
    └── time_tool.jl
```

Each file should export one or more `MCPTool` instances:

```julia
# calculator.jl
using ModelContextProtocol
using JSON3

calculator_tool = MCPTool(
    name = "calculate",
    description = "Basic calculator",
    parameters = [
        ToolParameter(name = "expression", type = "string", required = true)
    ],
    handler = params -> TextContent(
        text = JSON3.write(Dict("result" => eval(Meta.parse(params["expression"]))))
    )
)
```

Then auto-register from the directory:

```julia
server = mcp_server(
    name = "my-server",
    auto_register_dir = "my_server"
)
```