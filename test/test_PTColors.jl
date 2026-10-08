using Test

const TIMESTAMP_PATTERN = "\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}"

function capture_output(f; columns=nothing)
    buffer = IOBuffer()
    io = columns === nothing ? buffer : IOContext(buffer, :displaysize => (24, columns))
    f(io)
    return String(take!(buffer))
end

"""
Capture message layout with a fixed timestamp and ANSI colors removed.
"""
function capture_layout(f; columns=nothing)
    out = capture_output(f; columns=columns)
    out = replace(out, r"\e\[[0-9;:]*m" => "")
    return replace(
        out,
        Regex("^" * TIMESTAMP_PATTERN) => "2000-01-01 00:00:00";
        count=1,
    )
end

println("\nUnittesting PTColors.jl in ", get(ENV, "PWD", ""), " with Julia ", VERSION, " on ", Sys.KERNEL,"\n")

@testset "PTColors" begin
    @testset "message formatting" begin
        out = capture_output(io -> PTColors.defaultmsg("plain"; io=io))
        @test occursin(Regex("^" * TIMESTAMP_PATTERN * "  \\[  NOTICE   \\]  plain\n\$"), out)

        out = capture_output(io -> PTColors.okmsg("done"; io=io))
        @test occursin(PTColors.OKGREEN * " [  SUCCESS  ] " * PTColors.ENDC * " done", out)

        out = capture_output(io -> PTColors.warnmsg("careful"; io=io))
        @test occursin(PTColors.WARNING * " [  WARNING  ] " * PTColors.ENDC * " careful", out)

        out = capture_output(io -> PTColors.failmsg("bad"; io=io))
        @test occursin(PTColors.FAIL * " [  FAILURE  ] " * PTColors.ENDC * " bad", out)

        out = capture_output(io -> PTColors.infomsg("details"; io=io))
        @test occursin(PTColors.INFO * " [INFORMATION] " * PTColors.ENDC * " details", out)

        out = capture_output(io -> PTColors.headermsg("title"; io=io))
        @test occursin(PTColors.HEADER * " [  NOTICE   ] " * PTColors.ENDC * " title", out)
    end

    @testset "custom headers and multiline messages" begin
        local_prefix = "2000-01-01 00:00:00  [   LOCAL   ]  "
        indentation = repeat(" ", 36)

        expected_local = string(
            local_prefix,
            "first  ─ ─ ─┐\n",
            indentation,
            "second ─ ─ ─┘\n",
        )

        # 1. Headers retain their padding and continuation alignment.
        for sample in (
            (label="LOCAL", header="[   LOCAL   ]", width=36),
            (label="INFORMATION", header="[INFORMATION]", width=36),
            (label="REMOTE CONTROLLER", header="[REMOTE CONTROLLER]", width=42),
            (label="測試", header="[   測試    ]", width=36),
        )
            expected = string(
                "2000-01-01 00:00:00  ",
                sample.header,
                "  first  ─ ─ ─┐\n",
                repeat(" ", sample.width),
                "second ─ ─ ─┘\n",
            )

            for color in (nothing, PTColors.INFO)
                out = capture_layout(
                    io -> PTColors.defaultmsg(
                        ["first", "second"], sample.label, color; io=io,
                    ),
                )
                @test out == expected
            end
        end

        # 2. Input forms, blank rows, and Unicode text retain their meaning.
        for message in (
            "first\nsecond",
            "first\r\nsecond",
            ["first", "second"],
            ["first\nsecond"],
        )
            out = capture_layout(
                io -> PTColors.defaultmsg(message, "LOCAL"; io=io),
            )
            @test out == expected_local
        end

        out = capture_layout(
            io -> PTColors.okmsg(["first", "", "third\nfourth"]; io=io),
        )
        expected_blank = string(
            "2000-01-01 00:00:00  [  SUCCESS  ]  first  ─ ─ ─┐\n",
            repeat(" ", 48),
            "│\n",
            indentation,
            "third",
            repeat(" ", 7),
            "│\n",
            indentation,
            "fourth ─ ─ ─┘\n",
        )
        @test out == expected_blank

        out = capture_layout(
            io -> PTColors.defaultmsg("first\n", "LOCAL"; io=io),
        )
        expected_trailing = string(
            local_prefix,
            "first ─ ─ ─┐\n",
            indentation,
            "  ─ ─ ─ ─ ─┘\n",
        )
        @test out == expected_trailing

        out = capture_layout(
            io -> PTColors.defaultmsg(
                ["\e[31m測試\e[0m", "e\u0301"],
                "LOCAL",
                PTColors.INFO;
                io=io,
            ),
        )
        expected_unicode = string(
            local_prefix,
            "測試 ─ ─ ─┐\n",
            indentation,
            "e\u0301  ─ ─ ─ ─┘\n",
        )
        @test out == expected_unicode

        # 3. The longest line can appear anywhere in the message.
        for message in (
            ["wide", "a", "bb"],
            ["a", "wide", "bb"],
            ["a", "bb", "wide"],
        )
            out = capture_layout(
                io -> PTColors.defaultmsg(message, "LOCAL"; io=io),
            )
            lines = split(chomp(out), '\n')

            @test length(lines) == 3
            @test all(line -> textwidth(line) == 47, lines)
            @test endswith(lines[1], "┐")
            @test endswith(lines[2], "│")
            @test endswith(lines[3], "┘")
            @test length(collect(eachmatch(Regex(TIMESTAMP_PATTERN), out))) == 1
        end

        # 4. Each grouping marker uses and resets the header color.
        out = capture_output(
            io -> PTColors.defaultmsg(
                ["a", "b", "c"], "LOCAL", PTColors.INFO; io=io,
            ),
        )
        @test occursin(
            PTColors.INFO * "─ ─ ─┐" * PTColors.ENDC * "\n", out,
        )
        @test occursin(
            PTColors.INFO * repeat(" ", 5) * "│" * PTColors.ENDC * "\n", out,
        )
        @test endswith(
            out, PTColors.INFO * "─ ─ ─┘" * PTColors.ENDC * "\n",
        )

        plain = capture_output(
            io -> PTColors.defaultmsg(["a", "b", "c"], "LOCAL"; io=io),
        )
        @test !occursin('\e', plain)

        # 5. Every existing message function uses the shared grouping.
        for message_function in (
            PTColors.defaultmsg,
            PTColors.headermsg,
            PTColors.infomsg,
            PTColors.okmsg,
            PTColors.warnmsg,
            PTColors.failmsg,
        )
            out = capture_layout(
                io -> message_function(["first", "second"]; io=io),
            )
            lines = split(out, '\n'; keepempty=true)

            @test length(lines) == 3
            @test lines[2] == indentation * "second ─ ─ ─┘"
        end

        # 6. Single-line values and the return value remain unchanged.
        out = capture_layout(
            io -> PTColors.defaultmsg(42, "LOCAL"; io=io),
        )
        @test out == local_prefix * "42\n"

        for message in ("", String[])
            out = capture_layout(
                io -> PTColors.defaultmsg(message, "LOCAL"; io=io),
            )
            @test out == local_prefix * "\n"
        end

        @test PTColors.defaultmsg(
            ["first", "second"], "LOCAL"; io=IOBuffer(),
        ) === nothing
    end

    @testset "terminal-aware multiline wrapping" begin
        local_prefix = "2000-01-01 00:00:00  [   LOCAL   ]  "
        indentation = repeat(" ", 36)

        # 1. Wrap whole words, retain blank rows, and keep one aligned guide.
        for message in (
            ["alpha beta gamma", "", "done"],
            "alpha beta gamma\r\n\r\ndone",
        )
            out = capture_layout(
                io -> PTColors.defaultmsg(message, "LOCAL"; io=io);
                columns=52,
            )
            lines = split(chomp(out), '\n')
            @test length(lines) == 5
            @test startswith(lines[1], local_prefix * "alpha ")
            @test startswith(lines[2], indentation * "beta ")
            @test startswith(lines[3], indentation * "gamma ")
            @test lines[4] == repeat(" ", 47) * "│"
            @test startswith(lines[5], indentation * "done ")
            @test all(line -> textwidth(line) == 48, lines)
            @test endswith(lines[1], "┐")
            @test all(line -> endswith(line, "│"), lines[2:4])
            @test endswith(lines[5], "┘")
            @test length(collect(eachmatch(Regex(TIMESTAMP_PATTERN), out))) == 1
        end

        # 2. Account for longer headers and keep existing public calls usable.
        out = capture_layout(
            io -> PTColors.defaultmsg(
                ["Using the selected configuration.", "Done."],
                "REMOTE CONTROLLER",
                PTColors.INFO;
                io=io,
            );
            columns=64,
        )
        lines = split(chomp(out), '\n')
        @test length(lines) == 4
        @test startswith(lines[1], "2000-01-01 00:00:00  [REMOTE CONTROLLER]  Using the ")
        @test startswith(lines[2], repeat(" ", 42) * "selected ")
        @test startswith(lines[3], repeat(" ", 42) * "configuration. ")
        @test all(line -> textwidth(line) == 63, lines)

        for message_function in (
            PTColors.defaultmsg, PTColors.headermsg, PTColors.infomsg,
            PTColors.okmsg, PTColors.warnmsg, PTColors.failmsg,
        )
            out = capture_layout(
                io -> message_function(["alpha beta gamma", "done"]; io=io);
                columns=52,
            )
            lines = split(chomp(out), '\n')
            @test length(lines) == 4
            @test all(line -> textwidth(line) < 52, lines)
        end

        # 3. Split long words without dropping text or separating accents.
        out = capture_layout(
            io -> PTColors.defaultmsg(
                ["ABCDEFGHIJKLMNOPQRSTUVWXYZ", "done"], "LOCAL"; io=io,
            );
            columns=50,
        )
        lines = split(chomp(out), '\n')
        @test length(lines) == 6
        for index in eachindex(lines)
            prefix = index == 1 ? local_prefix : indentation
            piece = ("ABCDEF", "GHIJKL", "MNOPQR", "STUVWX", "YZ", "done")[index]
            @test startswith(lines[index], prefix * piece * " ")
        end
        @test all(line -> textwidth(line) == 49, lines)

        out = capture_layout(
            io -> PTColors.defaultmsg(
                ["測試測試" * repeat("e\u0301", 4), "d"], "LOCAL"; io=io,
            );
            columns=48,
        )
        lines = split(chomp(out), '\n')
        @test length(lines) == 4
        @test startswith(lines[1], local_prefix * "測試 ")
        @test startswith(lines[2], indentation * "測試 ")
        @test startswith(lines[3], indentation * repeat("e\u0301", 4) * " ")
        @test all(line -> textwidth(line) == 47, lines)

        # 4. Preserve message styles across wraps and keep guide colors separate.
        for color in (nothing, PTColors.INFO)
            raw = capture_output(
                io -> PTColors.defaultmsg(
                    ["\e[1m\e[31malpha beta\e[0m", "done"], "LOCAL", color; io=io,
                );
                columns=49,
            )
            guide_color = color === nothing ? "" : color
            @test occursin("\e[1m\e[31malpha\e[0m " * guide_color * "─ ─ ─┐", raw)
            @test occursin(indentation * "\e[1m\e[31mbeta\e[0m ", raw)
            plain = replace(raw, r"\e\[[0-9;:]*m" => "")
            @test all(line -> textwidth(line) == 48, split(chomp(plain), '\n'))
        end

        raw = capture_output(
            io -> PTColors.defaultmsg(["\e[31mfirst", "second\e[0m"], "LOCAL"; io=io);
            columns=80,
        )
        @test occursin(indentation * "\e[31msecond\e[0m ", raw)

        # 5. Fall back without truncation when a guide cannot fit safely.
        for columns in (0, 20, 44)
            out = capture_layout(
                io -> PTColors.defaultmsg(["alpha", "beta"], "LOCAL"; io=io);
                columns=columns,
            )
            @test out == local_prefix * "alpha\n" * indentation * "beta\n"
        end

        out = capture_layout(
            io -> PTColors.defaultmsg(["界", "a"], "LOCAL"; io=io);
            columns=45,
        )
        @test out == local_prefix * "界\n" * indentation * "a\n"

        long_label = repeat("H", 70)
        out = capture_layout(
            io -> PTColors.defaultmsg(["alpha", "beta"], long_label; io=io);
            columns=60,
        )
        @test occursin("[" * long_label * "]  alpha", out)
        @test endswith(out, "beta\n")
        @test !occursin('┐', out)

        for columns in (nothing, 80)
            for control in ("\t", "\r", "\b", "\e[2J", "\x7f")
                message = "a" * control * "b"
                out = capture_layout(
                    io -> PTColors.defaultmsg([message, "done"], "LOCAL"; io=io);
                    columns=columns,
                )
                @test out == local_prefix * message * "\n" * indentation * "done\n"
            end
        end

        # 6. Keep single lines, unconstrained streams, and trailing blank rows.
        long_line = repeat("x", 100)
        out = capture_layout(
            io -> PTColors.defaultmsg(long_line, "LOCAL"; io=io);
            columns=50,
        )
        @test out == local_prefix * long_line * "\n"

        for wrap_context in (false, true)
            out = capture_layout(io -> PTColors.defaultmsg(
                [long_line, "done"], "LOCAL";
                io=wrap_context ? IOContext(io, :color => true) : io,
            ))
            @test length(split(chomp(out), '\n')) == 2
            @test occursin(long_line, out)
        end

        out = capture_layout(
            io -> PTColors.defaultmsg("alpha beta\n", "LOCAL"; io=io);
            columns=49,
        )
        lines = split(chomp(out), '\n')
        @test length(lines) == 3
        @test endswith(lines[3], "┘")
        @test all(line -> textwidth(line) == 48, lines)
    end

    @testset "callback messages" begin
        io = IOBuffer()
        status = PTColors.messages("starting", "finished", "failed", x -> 2x, 3; io=io)
        out = String(take!(io))
        @test status == 0
        @test occursin("starting", out)
        @test occursin("finished", out)
        @test !occursin("failed", out)

        io = IOBuffer()
        status = PTColors.messages(
            "starting",
            "finished",
            "failed",
            () -> throw(ArgumentError("missing value"));
            exception=ArgumentError,
            io=io,
        )
        out = String(take!(io))
        @test status == 1
        @test occursin("failed", out)
        @test occursin("missing value", out)

        @test_throws ErrorException PTColors.messages(
            "starting",
            "finished",
            "failed",
            () -> error("unexpected");
            exception=ArgumentError,
            io=IOBuffer(),
        )
    end

    @testset "macros" begin
        mktemp() do path, io
            redirect_stdout(io) do
                PTColors.@ptok "macro ok"
                PTColors.@ptinfo "macro info"
                PTColors.@ptwarn "macro warn"
                PTColors.@pterror "macro error"
            end
            flush(io)
            out = read(path, String)
            @test occursin("macro ok", out)
            @test occursin("macro info", out)
            @test occursin("macro warn", out)
            @test occursin("macro error", out)
        end
    end
end

println("\nAll PTColors.jl tests completed.\n")
