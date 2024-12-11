using ModelContextProtocol
using Documenter

DocMeta.setdocmeta!(ModelContextProtocol, :DocTestSetup, :(using ModelContextProtocol); recursive=true)

makedocs(;
    modules=[ModelContextProtocol],
    authors="klidke@unm.edu",
    sitename="ModelContextProtocol.jl",
    format=Documenter.HTML(;
        canonical="https://JuliaSMLM.github.io/ModelContextProtocol.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaSMLM/ModelContextProtocol.jl",
    devbranch="main",
)
