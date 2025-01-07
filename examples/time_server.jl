using Pkg
Pkg.activate(@__DIR__)

using ModelContextProtocol
using Dates

# Define a tool 
time_tool = MCPTool(
    name = "current_time",
    description = "Get Current Date and Time",
    parameters = [],
    handler = params -> Dict("time" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS"))
)

# Define a resource 
birthday_resource = MCPResource(
    uri = "character-info://harry-potter/birthday",
    name = "Harry Potter's Birthday",  
    description = "Returns Harry Potter's birthday",
    data_provider = () -> Dict("birthday" => "July 31")
)

# Define a prompt
movie_info_prompt = MCPPrompt(
    name = "movie_analysis",
    description = "Get information about movies by genre",
    arguments = [
        PromptArgument(
            name = "genre",
            description = "Movie genre (e.g., science fiction, horror, drama)",
            required = true
        ),
        PromptArgument(
            name = "year",
            description = "Specific year to analyze (e.g., 1992)",
            required = false
        )
    ],
    messages = [
        PromptMessage(
            TextContent(
                type = "text",
                text = "What are some notable {genre} movies{?year? from {year}} that influenced the genre? Analyze their impact on filmmaking."
            )
        )
    ]
)

# Create and configure server 
config = ServerConfig(
    name = "time-weather-server",
    description = "Time formatting and weather information service",
    capabilities = [
        ResourceCapability(list_changed = true),
        ToolCapability(list_changed = true),
        PromptCapability(list_changed = true)
    ]
)

# Create server instance
server = Server(config)

# Register components
register!(server, time_tool)
register!(server, birthday_resource)
register!(server, movie_info_prompt)

# Start the server
start!(server)
