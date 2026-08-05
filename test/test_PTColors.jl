using Test

const TIMESTAMP_PATTERN = "\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}"

function capture_output(f)
    io = IOBuffer()
    f(io)
    return String(take!(io))
end

println("\nUnittesting PTColors.jl in ", get(ENV, "PWD", ""), " with Julia ", VERSION, " on ", Sys.KERNEL,"\n")

@testset "PTColors" begin
    @testset "message formatting" begin
        out = capture_output(io -> PTColors.defaultmsg("plain"; io=io))
        @test occursin(Regex("^" * TIMESTAMP_PATTERN * "  \\[  NOTICE  \\]  plain\n\$"), out)

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
