# 🎨 PTColors.jl

[![Julia 1.11+](https://img.shields.io/badge/Julia-1.11%2B-9558B2?logo=julia)](https://julialang.org)
[![Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-4063D8)](LICENSE)

`PTColors` is a lightweight Julia package designed to add color-coded, timestamped messages to terminal output with minimal effort. It is useful for command-line applications, scripts, simulations, and other projects that need readable status messages.

The package provides information, success, warning, failure, and header messages without requiring users to work directly with ANSI escape codes. It also includes convenience macros and callback handling for common application workflows.

## 🚦 Project Status

| Workflow                  | Status |
| ------------------------- | ------ |
|  Testing Suite          | [![Continuous Integration](https://github.com/ec-intl/ptcolors.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/ec-intl/ptcolors.jl/actions/workflows/ci.yml) |
|  Deployment Suite       | [![Continuous Deployment](https://github.com/ec-intl/ptcolors.jl/actions/workflows/cd.yml/badge.svg)](https://github.com/ec-intl/ptcolors.jl/actions/workflows/cd.yml) |
|  Documentation          | [![Documentation](https://github.com/ec-intl/ptcolors.jl/actions/workflows/docs.yml/badge.svg)](https://github.com/ec-intl/ptcolors.jl/actions/workflows/docs.yml) |
|  Guard Main Branch     | [![Guard Main Branch](https://github.com/ec-intl/ptcolors.jl/actions/workflows/guard.yml/badge.svg)](https://github.com/ec-intl/ptcolors.jl/actions/workflows/guard.yml) |
|  Code Quality Checker   | [![Lint Code Base](https://github.com/ec-intl/ptcolors.jl/actions/workflows/super-linter.yml/badge.svg)](https://github.com/ec-intl/ptcolors.jl/actions/workflows/super-linter.yml) |

## 📋 Requirements

- Julia 1.11 or later

## 📦 Installation

While the package is under development, install it from the `staging` branch:

```julia
using Pkg
Pkg.add(url = "https://github.com/ec-intl/ptcolors.jl", rev = "staging")
```

After the package is registered in Julia’s General registry, install it by name:

```julia
using Pkg
Pkg.add("PTColors")
```

## 🧩 Components

The package currently has the following structure:

```plaintext
.
├── .devcontainer/
├── .github/
│   └── workflows/
├── build_docs/
│   ├── src/
│   │   ├── assets/
│   │   │   ├── custom.css
│   │   │   └── ptcolors-julia-example.png
│   │   ├── api.md
│   │   └── index.md
│   ├── make.jl
│   ├── Manifest.toml
│   └── Project.toml
├── environments/
├── scripts/
│   ├── ci/
│   └── dev/
├── src/
│   └── PTColors.jl
├── test/
│   ├── runtests.jl
│   └── test_PTColors.jl
├── .dockerignore
├── .gitignore
├── CHANGELOG.md
├── docker-compose.yml
├── Dockerfile
├── LICENSE
├── Manifest.toml
├── Project.toml
├── README.md
└── VERSION
```

## 🖍️ Example

Load the package:

```julia
using PTColors
```

Use the message functions:

```julia
headermsg("This is a header message.")
okmsg("This is a success message.")
warnmsg("This is a warning message.")
failmsg("This is a failure message.")
infomsg("This is an information message.")
```

This produces timestamped terminal messages with a color and label appropriate to each message type.

> **Terminal colors:** PTColors uses standard ANSI color categories rather than
> fixed RGB values. The exact shades depend on the terminal emulator and its
> active color theme. This example was captured in the VS Code terminal using
> the Monokai theme.

![Example terminal output](build_docs/src/assets/ptcolors-julia-example.png)

The package also provides convenience macros:

```julia
@ptinfo "Simulation started."
@ptok "Simulation completed."
@ptwarn "A fallback value is being used."
@pterror "The simulation failed."
```

## ⚙️ Running a Callback

The `messages` function prints an information message, runs a callback, and then prints either a success or failure message.

```julia
# Define the callback that PTColors will run.
function foo(bar)
    println("Processing: ", bar)
end

# Run the callback with start, success, and failure messages.
status = messages(
    "Running the foo function...",
    "foo function complete.",
    "foo function experienced a problem!",
    foo,
    "bar";
    exception = Exception,
)

# Interpret the status returned by messages.
if status == 0
    println("Hooray!")
else
    println("Oh no!")
end
```

This produces terminal output similar to the following:

![Callback terminal output](build_docs/src/assets/ptcolors-julia-callback-example.png)

The function returns `0` when the callback succeeds and `1` when it throws an expected exception. Unexpected exceptions are rethrown.

## 🛠️ Main API

| Name         | Purpose                                                |
| ------------ | ------------------------------------------------------ |
| `timestamp`  | Return the current date and time as a formatted string |
| `defaultmsg` | Print a standard timestamped message                   |
| `headermsg`  | Print a magenta header message                         |
| `infomsg`    | Print a blue information message                       |
| `okmsg`      | Print a green success message                          |
| `warnmsg`    | Print a yellow warning message                         |
| `failmsg`    | Print a red failure message                            |
| `messages`   | Run a callback with status and failure handling        |
| `@ptinfo`    | Print an information message                           |
| `@ptok`      | Print a success message                                |
| `@ptwarn`    | Print a warning message                                |
| `@pterror`   | Print a failure message                                |

## 🧪 Testing

Run the complete test suite from the repository root:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```

## 🚀 Development

Development work is based on the `staging` branch. Create feature branches from `staging` and open pull requests back into `staging`.

## 📄 License

This project is licensed under the [Apache License 2.0](LICENSE).
