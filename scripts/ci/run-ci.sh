#!/usr/bin/env bash

set -euo pipefail

echo "============================================================"
echo "Running the PTColors.jl continuous-integration checks"
echo "============================================================"

echo "Instantiating the package environment..."
julia --project=. -e 'using Pkg; Pkg.instantiate()'

echo "Running the package tests..."
julia --project=. -e 'using Pkg; Pkg.test()'

echo "Instantiating the documentation environment..."
julia --project=build_docs -e 'using Pkg; Pkg.instantiate()'

echo "Building the documentation..."
julia --project=build_docs build_docs/make.jl

echo "============================================================"
echo "All PTColors.jl checks passed."
echo "============================================================"
