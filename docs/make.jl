using Documenter
using ModelContextProtocol

# Set up DocMeta for all files
DocMeta.setdocmeta!(ModelContextProtocol, :DocTestSetup, :(using ModelContextProtocol); recursive=true)

makedocs(
    modules = [ModelContextProtocol],
    authors = "Your Name",
    repo = "https://github.com/yourusername/ModelContextProtocol.jl/blob/{commit}{path}#{line}",
    sitename = "ModelContextProtocol.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://yourusername.github.io/ModelContextProtocol.jl",
        edit_link = "main",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "API Reference" => "api/api_dump.md"
    ],
    doctest = true,
    linkcheck = true,
    warnonly = true
)

deploydocs(;
    repo = "github.com/yourusername/ModelContextProtocol.jl",
    devbranch = "main",
    push_preview = true
)