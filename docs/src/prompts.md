# MCP Prompts

Prompts are template-based messages that language models can use. Each prompt has a name, description, arguments, and message templates.

## Prompt Structure

Every prompt in ModelContextProtocol.jl is represented by the `MCPPrompt` struct:

- `name`: Unique identifier for the prompt
- `description`: Human-readable explanation of the prompt's purpose
- `arguments`: List of parameters the prompt accepts
- `messages`: Template messages with placeholders for arguments

## Creating Prompts

Here's how to create a basic prompt:

```julia
greeting_prompt = MCPPrompt(
    name = "greeting",
    description = "Personalized greeting message",
    arguments = [
        PromptArgument(
            name = "name",
            description = "User's name",
            required = true
        ),
        PromptArgument(
            name = "time_of_day",
            description = "Morning, afternoon, or evening",
            required = false
        )
    ],
    messages = [
        PromptMessage(
            role = user,
            content = TextContent(
                text = "Hello! {?time_of_day?Good {time_of_day}}! My name is {name}."
            )
        )
    ]
)
```

## Arguments

Prompt arguments are defined using the `PromptArgument` struct:

- `name`: Parameter identifier
- `description`: Explanation of the parameter
- `required`: Whether the argument must be provided (default: false)

## Template Syntax

Prompt templates support parameter substitution and conditional blocks:

- Basic substitution: `{parameter_name}`
- Conditional blocks: `{?parameter_name?content if parameter exists}`

## Registering Prompts

Prompts can be registered with a server in two ways:

1. During server creation:
```julia
server = mcp_server(
    name = "my-server",
    prompts = my_prompt  # Single prompt or vector of prompts
)
```

2. After server creation:
```julia
register!(server, my_prompt)
```

## Directory-Based Organization

Prompts can be organized in directory structures and auto-registered:

```
my_server/
└── prompts/
    ├── greeting.jl
    └── faq.jl
```

Each file should export one or more `MCPPrompt` instances:

```julia
# greeting.jl
using ModelContextProtocol

greeting_prompt = MCPPrompt(
    name = "greeting",
    description = "Personalized greeting message",
    arguments = [
        PromptArgument(name = "name", description = "User's name", required = true)
    ],
    messages = [
        PromptMessage(
            role = user,
            content = TextContent(text = "Hello! My name is {name}.")
        )
    ]
)
```

Then auto-register from the directory:

```julia
server = mcp_server(
    name = "my-server",
    auto_register_dir = "my_server"
)
```