# MCP Resources

Resources provide data that language models can access. Each resource has a URI, name, MIME type, and a data provider function.

## Resource Structure

Every resource in ModelContextProtocol.jl is represented by the `MCPResource` struct:

- `uri`: Unique URI identifier for the resource
- `name`: Human-readable resource name
- `description`: Explanation of the resource's purpose
- `mime_type`: Content type (e.g., "application/json", "text/plain")
- `data_provider`: Function that returns the resource's data
- `annotations`: Optional metadata about the resource

## Creating Resources

Here's how to create a basic resource:

```julia
weather_resource = MCPResource(
    uri = "mcp://weather/current",
    name = "Current Weather",
    description = "Current weather conditions",
    mime_type = "application/json",
    data_provider = () -> Dict(
        "temperature" => 22.5,
        "conditions" => "Partly Cloudy",
        "updated" => Dates.format(now(), "yyyy-mm-dd HH:MM:SS")
    )
)
```

## Data Providers

The `data_provider` function should return data in a format compatible with the specified MIME type:

- For JSON resources, return Julia objects that can be JSON-serialized
- For text resources, return strings
- For binary resources, return byte arrays

## Registering Resources

Resources can be registered with a server in two ways:

1. During server creation:
```julia
server = mcp_server(
    name = "my-server",
    resources = my_resource  # Single resource or vector of resources
)
```

2. After server creation:
```julia
register!(server, my_resource)
```

## Directory-Based Organization

Resources can be organized in directory structures and auto-registered:

```
my_server/
└── resources/
    ├── weather.jl
    └── stock_data.jl
```

Each file should export one or more `MCPResource` instances:

```julia
# weather.jl
using ModelContextProtocol
using Dates

weather_resource = MCPResource(
    uri = "mcp://weather/current",
    name = "Current Weather",
    description = "Current weather conditions",
    mime_type = "application/json",
    data_provider = () -> Dict(
        "temperature" => 22.5,
        "conditions" => "Partly Cloudy",
        "updated" => Dates.format(now(), "yyyy-mm-dd HH:MM:SS")
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