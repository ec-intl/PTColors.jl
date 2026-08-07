"""
    module PTColors

A lightweight Julia module providing color-coded, timestamped terminal messages.

## Exports
- `defaultmsg(msg, typ, color)`: Print a timestamped message with an optional ANSI color.
- `headermsg(msg)`: Print a magenta notice message.
- `infomsg(msg)`: Print a blue information message.
- `okmsg(msg)`: Print a green success message.
- `warnmsg(msg)`: Print a yellow warning message.
- `failmsg(msg)`: Print a red failure message.
- `messages(...)`: Run a callback with information, success, and failure messages.
- `@ptok`, `@ptinfo`, `@ptwarn`, `@pterror`: Convenience macros for colored messages.

All functions print to standard output by default with a consistent format and ANSI color codes.
No dependencies required.
""" module PTColors

using Dates

export HEADER, INFO, OKGREEN, WARNING, FAIL, ENDC
export timestamp, defaultmsg, headermsg, failmsg, okmsg, warnmsg, infomsg, messages
export @ptok, @ptinfo, @ptwarn, @pterror

@doc """HEADER: ANSI magenta color code for header messages.
Example:
    println(HEADER * "Header text" * ENDC)
""" const HEADER = "\033[95m"
@doc """INFO: ANSI blue color code for info messages.
Example:
    println(INFO * "Info text" * ENDC)
""" const INFO = "\033[94m"
@doc """OKGREEN: ANSI green color code for success messages.
Example:
    println(OKGREEN * "Success text" * ENDC)
""" const OKGREEN = "\033[92m"
@doc """WARNING: ANSI yellow color code for warning messages.
Example:
    println(WARNING * "Warning text" * ENDC)
""" const WARNING = "\033[93m"
@doc """FAIL: ANSI red color code for failure messages.
Example:
    println(FAIL * "Failure text" * ENDC)
""" const FAIL = "\033[91m"
@doc """ENDC: ANSI code to reset color formatting.
Example:
    println(HEADER * "Header" * ENDC)
""" const ENDC = "\033[0m"

@doc """
timestamp()

Return the current date and time as a formatted string for log messages.
Format: yyyy-mm-dd HH:MM:SS

Example:
    ts = timestamp()
    println(ts)
""" function timestamp()
    return Dates.format(Dates.now(), "yyyy-mm-dd HH:MM:SS")
end

@doc """
defaultmsg(msg, typ="  NOTICE  ", color=nothing; io=stdout)

Print a timestamped message. When `color` is supplied, it is applied to the type label.

Example:
    defaultmsg("Hello!", "INFO", INFO)
    defaultmsg("No color label")
""" function defaultmsg(msg, typ::AbstractString="  NOTICE  ", color=nothing; io::IO=stdout)
    if color === nothing
        println(io, timestamp(), "  [", typ, "]  ", msg)
    else
        println(io, timestamp(), " ", color, " [", typ, "] ", ENDC, " ", msg)
    end
    return nothing
end

@doc """
headermsg(msg; io=stdout)

Print a magenta notice message.

Example:
    headermsg("This is a header message.")
""" function headermsg(msg; io::IO=stdout)
    return defaultmsg(msg, "  NOTICE   ", HEADER; io=io)
end

@doc """
failmsg(msg; io=stdout)

Print a red failure message.

Example:
    failmsg("Something failed!")
""" function failmsg(msg; io::IO=stdout)
    return defaultmsg(msg, "  FAILURE  ", FAIL; io=io)
end

@doc """
okmsg(msg; io=stdout)

Print a green success message.

Example:
    okmsg("Operation succeeded!")
""" function okmsg(msg; io::IO=stdout)
    return defaultmsg(msg, "  SUCCESS  ", OKGREEN; io=io)
end

@doc """
warnmsg(msg; io=stdout)

Print a yellow warning message.

Example:
    warnmsg("This is a warning.")
""" function warnmsg(msg; io::IO=stdout)
    return defaultmsg(msg, "  WARNING  ", WARNING; io=io)
end

@doc """
infomsg(msg; io=stdout)

Print a blue information message.

Example:
    infomsg("This is an info message.")
""" function infomsg(msg; io::IO=stdout)
    return defaultmsg(msg, "INFORMATION", INFO; io=io)
end

_is_expected_exception(err, exception_type::Type{<:Exception}) = isa(err, exception_type)
function _is_expected_exception(err, exception_types::Tuple)
    return any(exception_type -> _is_expected_exception(err, exception_type), exception_types)
end

@doc """
messages(info_msg, success_msg, failure_msg, callback, args...; exception=Exception, io=stdout, kwargs...)

Print `info_msg`, run `callback(args...; kwargs...)`, then print either `success_msg` or
`failure_msg`. Returns `0` when the callback succeeds and `1` when it throws the expected
exception type. Unexpected exceptions are rethrown.

`exception` can be a single exception type or a tuple of exception types.

Example:
    messages("Starting...", "Done!", "Failed!", x -> println(x), "Hello")
""" function messages(
    info_msg,
    success_msg,
    failure_msg,
    callback,
    args...;
    exception::Union{Type{<:Exception},Tuple}=Exception,
    io::IO=stdout,
    kwargs...,
)
    try
        infomsg(info_msg; io=io)
        callback(args...; kwargs...)
        okmsg(success_msg; io=io)
        return 0
    catch err
        if _is_expected_exception(err, exception)
            failmsg(failure_msg; io=io)
            failmsg(sprint(showerror, err); io=io)
            return 1
        end
        rethrow()
    end
end

@doc """@ptok msg
Print a green success message with a timestamp and the given message.
Example:
    @ptok "Module loaded successfully."
""" macro ptok(msg)
    return :(okmsg($(esc(msg))))
end

@doc """@ptinfo msg
Print a blue information message with a timestamp and the given message.
Example:
    @ptinfo "Simulation started."
""" macro ptinfo(msg)
    return :(infomsg($(esc(msg))))
end

@doc """@ptwarn msg
Print a yellow warning message with a timestamp and the given message.
Example:
    @ptwarn "Configuration file missing."
""" macro ptwarn(msg)
    return :(warnmsg($(esc(msg))))
end

@doc """@pterror msg
Print a red failure message with a timestamp and the given message.
Example:
    @pterror "Failed to load module."
""" macro pterror(msg)
    return :(failmsg($(esc(msg))))
end

end # module
