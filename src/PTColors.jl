"""
    module PTColors

A lightweight Julia module providing color-coded, timestamped terminal messages.

## Exports
- `defaultmsg(msg, typ, color)`: Print a timestamped message with an optional ANSI color.
- `headermsg(msg)`: Print a notice message with a bright magenta status label.
- `infomsg(msg)`: Print an information message with a bright blue status label.
- `okmsg(msg)`: Print a success message with a bright green status label.
- `warnmsg(msg)`: Print a warning message with a bright yellow status label.
- `failmsg(msg)`: Print a failure message with a bright red status label.
- `messages(...)`: Run a callback with information, success, and failure messages.
- `@ptok`, `@ptinfo`, `@ptwarn`, `@pterror`: Convenience macros for colored messages.

All functions print to standard output by default with a consistent format and ANSI color codes.
No dependencies required.
""" module PTColors

using Dates

export HEADER, INFO, OKGREEN, WARNING, FAIL, ENDC
export timestamp, defaultmsg, headermsg, failmsg, okmsg, warnmsg, infomsg, messages
export @ptok, @ptinfo, @ptwarn, @pterror

@doc """HEADER: ANSI bright magenta foreground code for header messages.
Example:
    println(HEADER * "Header text" * ENDC)
""" const HEADER = "\033[95m"
@doc """INFO: ANSI bright blue foreground code for information messages.
Example:
    println(INFO * "Info text" * ENDC)
""" const INFO = "\033[94m"
@doc """OKGREEN: ANSI bright green foreground code for success messages.
Example:
    println(OKGREEN * "Success text" * ENDC)
""" const OKGREEN = "\033[92m"
@doc """WARNING: ANSI bright yellow foreground code for warning messages.
Example:
    println(WARNING * "Warning text" * ENDC)
""" const WARNING = "\033[93m"
@doc """FAIL: ANSI bright red foreground code for failure messages.
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
_format_message(msg, typ, color, time_text)

Build a timestamped message with a padded header and aligned continuation lines.
Accept a string, a vector of strings, or another printable value.
""" function _format_message(
    msg,
    typ::AbstractString,
    color,
    time_text::AbstractString,
)
    # 1. Center short labels and preserve longer labels.
    label = strip(typ)
    padding = max(0, 11 - textwidth(label))
    left_padding = padding ÷ 2
    right_padding = padding - left_padding

    header = string(
        "[",
        repeat(" ", left_padding),
        label,
        repeat(" ", right_padding),
        "]",
    )

    # 2. Convert the message into individual lines.
    if msg isa AbstractVector{<:AbstractString}
        message_text = join(msg, "\n")
    else
        message_text = string(msg)
    end

    message_text = replace(message_text, "\r\n" => "\n")
    message_lines = split(message_text, '\n'; keepempty=true)

    # 3. Measure the prefix before applying color.
    visible_prefix = string(time_text, "  ", header, "  ")
    indentation = repeat(" ", textwidth(visible_prefix))

    if color === nothing
        prefix = visible_prefix
    else
        prefix = string(time_text, " ", color, " ", header, " ", ENDC, " ")
    end

    # 4. Align continuation text while preserving blank lines.
    formatted_lines = [string(prefix, first(message_lines))]

    for index in 2:length(message_lines)
        line = message_lines[index]

        if isempty(line)
            push!(formatted_lines, "")
        else
            push!(formatted_lines, string(indentation, line))
        end
    end

    return join(formatted_lines, "\n")
end

@doc """
defaultmsg(msg, typ="  NOTICE   ", color=nothing; io=stdout)

Print a timestamped message with an optional colored header.

Short labels are centered within 11 visible columns. Longer labels are
preserved in full. Existing surrounding label padding is normalized.

Accept a string containing line breaks or a vector of message strings.
Print the timestamp and header once, then align continuation lines beneath
the first message line. Intentional blank lines are preserved.

When `color` is supplied, it is applied to the header.

Examples:
    defaultmsg("Hello!", "LOCAL", INFO)
    defaultmsg(["Calculation completed.", "Results saved locally."])
""" function defaultmsg(
    msg,
    typ::AbstractString="  NOTICE   ",
    color=nothing;
    io::IO=stdout,
)
    formatted_message = _format_message(msg, typ, color, timestamp())
    println(io, formatted_message)
    return nothing
end

@doc """
headermsg(msg; io=stdout)

Print a notice message with a bright magenta status label.

Example:
    headermsg("This is a header message.")
""" function headermsg(msg; io::IO=stdout)
    return defaultmsg(msg, "  NOTICE   ", HEADER; io=io)
end

@doc """
failmsg(msg; io=stdout)

Print a failure message with a bright red status label.

Example:
    failmsg("Something failed!")
""" function failmsg(msg; io::IO=stdout)
    return defaultmsg(msg, "  FAILURE  ", FAIL; io=io)
end

@doc """
okmsg(msg; io=stdout)

Print a success message with a bright green status label.

Example:
    okmsg("Operation succeeded!")
""" function okmsg(msg; io::IO=stdout)
    return defaultmsg(msg, "  SUCCESS  ", OKGREEN; io=io)
end

@doc """
warnmsg(msg; io=stdout)

Print a warning message with a bright yellow status label.

Example:
    warnmsg("This is a warning.")
""" function warnmsg(msg; io::IO=stdout)
    return defaultmsg(msg, "  WARNING  ", WARNING; io=io)
end

@doc """
infomsg(msg; io=stdout)

Print an information message with a bright blue status label.

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
Print a success message with a timestamp and a bright green status label.
Example:
    @ptok "Module loaded successfully."
""" macro ptok(msg)
    return :(okmsg($(esc(msg))))
end

@doc """@ptinfo msg
Print an information message with a timestamp and a bright blue status label.
Example:
    @ptinfo "Simulation started."
""" macro ptinfo(msg)
    return :(infomsg($(esc(msg))))
end

@doc """@ptwarn msg
Print a warning message with a timestamp and a bright yellow status label.
Example:
    @ptwarn "Configuration file missing."
""" macro ptwarn(msg)
    return :(warnmsg($(esc(msg))))
end

@doc """@pterror msg
Print a failure message with a timestamp and a bright red status label.
Example:
    @pterror "Failed to load module."
""" macro pterror(msg)
    return :(failmsg($(esc(msg))))
end

end # module
