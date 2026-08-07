push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))

using Documenter
using PTColors

DocMeta.setdocmeta!(
    PTColors,
    :DocTestSetup,
    :(using PTColors);
    recursive = true,
)

makedocs(
    doctest = true,
    checkdocs = :exports,
    format = Documenter.HTML(
        assets = ["assets/custom.css"],
        edit_link = nothing,
        footer = "PTColors.jl is developed by [Elizabeth Consulting International Inc.](https://github.com/ec-intl).",
        repolink = "https://github.com/ec-intl/ptcolors.jl",
    ),
    modules = [PTColors],
    remotes = nothing,
    pages = [
        "Home" => "index.md",
        "API Reference" => "api.md",
    ],
    sitename = "PTColors.jl",
)
