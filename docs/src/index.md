# ModelContextProtocol.jl

ModelContextProtocol.jl is a Julia implementation of the [Model Context Protocol (MCP)](https://github.com/modelcontextprotocol), enabling integration with Large Language Models (LLMs) like Anthropic's Claude.

## Overview

The Model Context Protocol provides a standardized way for applications to offer context and capabilities to LLMs. This package implements the full MCP specification, with `mcp_server()` as the main entry point.

## Installation

```julia
using Pkg
Pkg.add("ModelContextProtocol")
```

## Key Components

The package provides three main types that can be registered with an MCP server:

- **Tools**: Callable functions that LLMs can use
- **Resources**: Data sources that LLMs can read
- **Prompts**: Template-based messages

## Quick Start

```julia
using ModelContextProtocol
using JSON3, Dates

# Create a simple tool
time_tool = MCPTool(
    name = "get_time",
    description = "Get current time in specified format",
    parameters = [
        ToolParameter(
            name = "format",
            type = "string",
            description = "DateTime format string",
            required = true
        )
    ],
    handler = params -> TextContent(
        text = JSON3.write(Dict("time" => Dates.format(now(), params["format"])))
    )
)

# Create and start server
server = mcp_server(
    name = "time-server",
    description = "Simple MCP server with time tool",
    tools = time_tool
)

start!(server)
```

See the [Tools](tools.md), [Resources](resources.md), and [Prompts](prompts.md) sections for more details.