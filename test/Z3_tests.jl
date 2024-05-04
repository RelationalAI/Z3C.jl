@testitem "create sort" begin
    sort = DeclareSort("S")
    @test "$sort" == "S"
end

@testitem "create bool sort" begin
    sort = BoolSort()
    @test "$sort" == "Bool"
end

@testitem "create bool value" begin
    t = BoolVal(true)
    @test "$t" == "true"
    f = BoolVal(false)
    @test "$f" == "false"
end

@testitem "simple solve" begin
    s = Solver()
    push(s)
    add(s, BoolVal(false))
    r = check(s)
    @test r == CheckResult(:unsat)
    pop(s)
    r = check(s)
    @test r == CheckResult(:sat)
    add(s, BoolVal(true))
    @test check(s) == CheckResult(:sat)
end