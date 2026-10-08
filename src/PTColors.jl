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
_visible_width(text)

Return the visible column width, excluding ANSI color and style sequences.
""" function _visible_width(text::AbstractString)
    return textwidth(replace(text, r"\e\[[0-9;:]*m" => ""))
end

@doc """
_output_columns(io)

Return the terminal width or an explicitly supplied IOContext display width.
Leave files, pipes, and ordinary buffers unconstrained.
""" function _output_columns(io::IO)
    if io isa IOContext
        if get(io, :displaysize, nothing) !== nothing
            return displaysize(io)[2]
        end
        return _output_columns(io.io)
    end

    return io isa Base.TTY ? displaysize(io)[2] : nothing
end

@doc """
_wrap_message_line(line, columns)

Wrap at spaces where possible, removing the space replaced by a line break.
Split long words between Unicode grapheme clusters and keep ANSI SGR codes intact.
Return `nothing` when a cluster cannot fit or unsupported controls are present.
""" function _wrap_message_line(line::AbstractString, columns::Integer)
    # 1. Check whether the line can be measured safely.
    plain = replace(line, r"\e\[[0-9;:]*m" => "")
    if columns < 1 || occursin(r"[\x00-\x1f\x7f]", plain)
        return nothing
    end
    if textwidth(plain) <= columns
        return [String(line)]
    end

    # 2. Treat color sequences and complete grapheme clusters as single tokens.
    tokens = [matched.match for matched in eachmatch(r"\e\[[0-9;:]*m|\X", line)]
    widths = [_visible_width(token) for token in tokens]
    if any(width -> width > columns, widths)
        return nothing
    end

    # 3. Fit each row, preferring the last available word boundary.
    wrapped_lines = String[]
    first_index = 1
    while first_index <= length(tokens)
        row_width = 0
        last_index = first_index - 1
        last_space = 0

        for index in first_index:length(tokens)
            if row_width + widths[index] > columns
                if tokens[index] == " "
                    last_space = index
                end
                break
            end

            row_width += widths[index]
            last_index = index
            if tokens[index] == " "
                last_space = index
            end
        end

        if last_index == length(tokens)
            push!(wrapped_lines, join(tokens[first_index:last_index]))
            break
        elseif last_space > first_index
            push!(wrapped_lines, join(tokens[first_index:(last_space - 1)]))
            first_index = last_space + 1
        else
            push!(wrapped_lines, join(tokens[first_index:last_index]))
            first_index = last_index + 1
        end
    end

    return wrapped_lines
end

@doc """
_isolate_message_styles(lines)

Reset message styles before each guide and restore them on the following row.
Replay SGR sequences since the most recent full reset to preserve compound styles.
""" function _isolate_message_styles(lines)
    active_style = ""
    styled_lines = String[]

    for line in lines
        opening_style = active_style
        for matched in eachmatch(r"\e\[[0-9;:]*m", line)
            sequence = matched.match
            if sequence == "\e[0m" || sequence == "\e[m"
                active_style = ""
            else
                active_style = string(active_style, sequence)
            end
        end

        closing_style = isempty(active_style) ? "" : ENDC
        push!(styled_lines, string(opening_style, line, closing_style))
    end

    return styled_lines
end

@doc """
_format_message(msg, typ, color, time_text; columns=nothing)

Build a timestamped message with a padded header and aligned continuation lines.
Wrap multiline output to the available columns before adding its grouping guide.
Accept a string, a vector of strings, or another printable value.
""" function _format_message(
    msg,
    typ::AbstractString,
    color,
    time_text::AbstractString;
    columns::Union{Nothing,Integer}=nothing,
)
    # 1. Center short labels and preserve longer labels.
    label = strip(typ)
    padding = max(0, 11 - _visible_width(label))
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
    prefix_width = _visible_width(visible_prefix)
    indentation = repeat(" ", prefix_width)

    if color === nothing
        prefix = visible_prefix
    else
        prefix = string(time_text, " ", color, " ", header, " ", ENDC, " ")
    end

    # 4. Preserve the existing single-line layout.
    if length(message_lines) == 1
        return string(prefix, first(message_lines))
    end

    # 5. Validate controls and reserve space for the grouping guide.
    for line in message_lines
        plain = replace(line, r"\e\[[0-9;:]*m" => "")
        if occursin(r"[\x00-\x1f\x7f]", plain)
            return string(prefix, join(message_lines, "\n" * indentation))
        end
    end

    # Reserve seven guide columns and one spare terminal column.
    if columns !== nothing
        message_width = columns - prefix_width - 8
        wrapped_lines = String[]

        for line in message_lines
            wrapped = _wrap_message_line(line, message_width)
            if wrapped === nothing
                # Preserve all text without a guide when the layout cannot fit.
                return string(prefix, join(message_lines, "\n" * indentation))
            end
            append!(wrapped_lines, wrapped)
        end

        message_lines = wrapped_lines
    end

    message_lines = _isolate_message_styles(message_lines)
    line_widths = [_visible_width(line) for line in message_lines]
    longest_width = maximum(line_widths)
    formatted_lines = String[]

    # 6. Align the message lines and add matching grouping markers.
    for index in eachindex(message_lines)
        line = message_lines[index]
        line_prefix = index == 1 ? prefix : indentation

        # Reserve five leader columns beyond the longest message text.
        leader_width = longest_width - line_widths[index] + 5

        if index == 1 || index == length(message_lines)
            leader = repeat(" ─", leader_width ÷ 2)

            if isodd(leader_width)
                leader = string("─", leader)
            end

            corner = index == 1 ? "┐" : "┘"
            marker = string(leader, corner)
        else
            marker = string(repeat(" ", leader_width), "│")
        end

        if color !== nothing
            marker = string(color, marker, ENDC)
        end

        push!(formatted_lines, string(line_prefix, line, " ", marker))
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
the first message line.

Multiline messages have dashed connections on their first and last lines,
joined by a right-hand bracket beyond the longest visible message line.
Blank message rows retain their position within the group.
Single-line messages retain their existing layout.

Multiline terminal output wraps before grouping, reserving space for the
actual header and guide. Long words split between Unicode grapheme clusters.
Files and ordinary buffers keep their supplied line breaks; an IOContext
with `:displaysize` can request a specific width.

If the header leaves insufficient space, a grapheme cannot fit, or a message
contains controls other than ANSI SGR styles, omit the guide and preserve
the supplied text. Very narrow output may still wrap naturally in the terminal.
Resizing the terminal after printing does not reformat previous messages.

When `color` is supplied, it is applied to the header and grouping markers,
with a reset after each colored element.

Examples:
    defaultmsg("Hello!", "LOCAL", INFO)
    defaultmsg(["Calculation completed.", "Results saved locally."])
""" function defaultmsg(
    msg,
    typ::AbstractString="  NOTICE   ",
    color=nothing;
    io::IO=stdout,
)
    formatted_message = _format_message(
        msg, typ, color, timestamp(); columns=_output_columns(io),
    )
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
