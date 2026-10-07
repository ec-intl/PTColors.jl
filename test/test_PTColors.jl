using Test

const TIMESTAMP_PATTERN = "\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}"

function capture_output(f)
    io = IOBuffer()
    f(io)
    return String(take!(io))
end

"""
Capture message layout with a fixed timestamp and ANSI colors removed.
"""
function capture_layout(f)
    out = capture_output(f)
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
        expected_local = string(
            "2000-01-01 00:00:00  [   LOCAL   ]  first\n",
            repeat(" ", 36),
            "second\n",
        )

        # 1. Short headers align with and without color.
        out = capture_layout(
            io -> PTColors.defaultmsg(
                ["first", "second"], "LOCAL"; io=io,
            ),
        )
        @test out == expected_local

        out = capture_layout(
            io -> PTColors.defaultmsg(
                ["first", "second"], "LOCAL", PTColors.INFO; io=io,
            ),
        )
        @test out == expected_local

        # 2. Explicit line breaks have the same layout as a vector.
        out = capture_layout(
            io -> PTColors.defaultmsg(
                "first\nsecond", "LOCAL"; io=io,
            ),
        )
        @test out == expected_local

        # 3. Longer headers remain complete and move the indentation.
        out = capture_layout(
            io -> PTColors.defaultmsg(
                ["first", "second"],
                "REMOTE CONTROLLER",
                PTColors.INFO;
                io=io,
            ),
        )
        expected_long = string(
            "2000-01-01 00:00:00  [REMOTE CONTROLLER]  first\n",
            repeat(" ", 42),
            "second\n",
        )
        @test out == expected_long

        # 4. Wide Unicode characters use their visible column width.
        out = capture_layout(
            io -> PTColors.defaultmsg(
                ["first", "second"], "測試"; io=io,
            ),
        )
        expected_unicode = string(
            "2000-01-01 00:00:00  [   測試    ]  first\n",
            repeat(" ", 36),
            "second\n",
        )
        @test out == expected_unicode

        # 5. Blank lines and line breaks within vector items survive.
        out = capture_layout(
            io -> PTColors.okmsg(
                ["first", "", "third\nfourth"]; io=io,
            ),
        )
        expected_blank = string(
            "2000-01-01 00:00:00  [  SUCCESS  ]  first\n\n",
            repeat(" ", 36),
            "third\n",
            repeat(" ", 36),
            "fourth\n",
        )
        @test out == expected_blank

        out = capture_layout(
            io -> PTColors.defaultmsg(
                "first\r\nsecond", "LOCAL"; io=io,
            ),
        )
        @test out == expected_local

        # 6. Every existing message function supports multiple lines.
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
            @test lines[2] == repeat(" ", 36) * "second"
        end
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
