# PTColors.jl

```@raw html
<div class="ptcolors-hero">
    <p class="ptcolors-eyebrow">Readable Julia terminal output</p>
    <p class="ptcolors-tagline">
        PTColors provides lightweight, color-coded, timestamped messages for
        command-line applications, scripts, simulations, and automated workflows.
    </p>
</div>

<div class="ptcolors-badges">
    <a href="https://julialang.org">
        <img alt="Julia 1.10+" src="https://img.shields.io/badge/Julia-1.10%2B-9558B2">
    </a>
    <a href="https://github.com/ec-intl/PTColors.jl">
        <img alt="GitHub repository" src="https://img.shields.io/badge/GitHub-PTColors.jl-181717?logo=github">
    </a>
    <a href="https://github.com/ec-intl/PTColors.jl/blob/staging/LICENSE">
        <img alt="Apache 2.0 license" src="https://img.shields.io/badge/License-Apache%202.0-4063D8">
    </a>
</div>
```

PTColors makes terminal messages easier to identify without requiring users to work directly with ANSI escape codes. It provides standard functions, convenience macros, timestamp formatting, and callback status handling.

## Related Python package

Working in Python? See [ptcolors](https://github.com/ec-intl/ptcolors), ECI’s Python package for colorized terminal messages. `PTColors.jl` provides similar terminal-message functionality for Julia users, but the packages are maintained separately.


## Why PTColors?

- Consistent timestamps and status labels
- Information, success, warning, failure, and header messages
- Convenient macros for common message types
- Callback execution with success and failure handling
- No external runtime dependencies
- Support for Julia 1.10 and later

## Installation

Install PTColors from Julia’s General registry:

```julia
using Pkg
Pkg.add("PTColors")
```

## Quick start

Load the package:

```julia
using PTColors
```

Print status messages:

```julia
headermsg("Starting the application.")
infomsg("Loading configuration.")
okmsg("Operation completed successfully.")
warnmsg("A fallback value is being used.")
failmsg("The operation failed.")
defaultmsg("A general status message.")
```

Each message includes a timestamp and status label. The predefined message functions color their labels, while `defaultmsg` is uncolored unless a color is supplied.

| Function | Label | ANSI color | Typical use |
|---|---|---|---|
| `headermsg` | `NOTICE` | Bright magenta | Section headings and important notices |
| `infomsg` | `INFORMATION` | Bright blue | General progress information |
| `okmsg` | `SUCCESS` | Bright green | Successful operations |
| `warnmsg` | `WARNING` | Bright yellow | Recoverable problems or cautions |
| `failmsg` | `FAILURE` | Bright red | Errors and failed operations |
| `defaultmsg` | `NOTICE` | Uncolored by default | Custom or general messages |

> **Terminal colors:** PTColors uses standard ANSI color categories rather than
> fixed RGB values. The exact shades depend on the terminal emulator and its
> active color theme. This example was captured in the VS Code terminal using
> the Monokai theme.

```@raw html
<div class="ptcolors-example">
    <img
        src="assets/ptcolors-julia-terminal-example.png"
        alt="Example PTColors terminal output"
        loading="lazy"
    >
    <p>Example color-coded terminal output produced by PTColors.</p>
</div>
```

## Convenience macros

PTColors also provides concise macros for frequently used message types:

```julia
@ptinfo "Simulation started."
@ptok "Simulation completed."
@ptwarn "A fallback value is being used."
@pterror "The simulation failed."
```

These macros call the corresponding message functions and automatically include the timestamp, label, and terminal color.

## Callback handling

The `messages` function prints an information message, runs a callback, and then reports whether the callback succeeded or failed.

```julia
function process_item(item)
    println("Processing: ", item)
end

status = messages(
    "Starting item processing...",
    "Item processing completed.",
    "Item processing failed.",
    process_item,
    "example";
    exception = Exception,
)

if status == 0
    println("The callback completed successfully.")
else
    println("The callback encountered an expected error.")
end
```

The function returns:

- `0` when the callback completes successfully
- `1` when the callback throws one of the expected exception types

Unexpected exceptions are rethrown so they are not silently hidden.

```@raw html
<div class="ptcolors-example">
    <img
        src="assets/ptcolors-julia-callback-example.png"
        alt="PTColors callback terminal output"
        loading="lazy"
    >
    <p>Successful callback execution reported by PTColors.</p>
</div>
```

## Testing

Run the complete package test suite from the repository root:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```

## Learn more

> **💡 Explore the package**
>
> Review the [API Reference](@ref) for the complete exported interface, or visit the [PTColors.jl GitHub repository](https://github.com/ec-intl/PTColors.jl) for source code, issues, and development information.

## License

PTColors.jl is available under the [Apache License 2.0](https://github.com/ec-intl/PTColors.jl/blob/main/LICENSE).
