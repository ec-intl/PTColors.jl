# PTColors.jl Documentation

PTColors is a lightweight Julia package for printing color-coded, timestamped terminal messages.

## Installation

While the package is under development, install it from the `staging` branch:

```julia
using Pkg
Pkg.add(url = "https://github.com/ec-intl/ptcolors.jl", rev = "staging")
```

After registration in Julia’s General registry, install it by name:

```julia
using Pkg
Pkg.add("PTColors")
```

## Basic Usage

```julia
using PTColors

headermsg("Starting the application.")
infomsg("Loading configuration.")
okmsg("Operation completed successfully.")
warnmsg("A fallback value is being used.")
failmsg("The operation failed.")
```

## Convenience Macros

```julia
@ptinfo "Simulation started."
@ptok "Simulation completed."
@ptwarn "A fallback value is being used."
@pterror "The simulation failed."
```

## Callback Handling

The `messages` function prints an information message, runs a callback, and then prints either a success or failure message.

```julia
status = messages(
    "Starting operation...",
    "Operation completed.",
    "Operation failed.",
    () -> println("Running operation"),
)
```

It returns `0` when the callback succeeds and `1` when it throws an expected exception.

## Testing

Run the test suite from the repository root:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```
