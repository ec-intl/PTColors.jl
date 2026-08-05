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
    format = Documenter.HTML(),
    modules = [PTColors],
    pages = [
        "Home" => "index.md",
        "API Reference" => "api.md",
    ],
    sitename = "PTColors.jl",
)
