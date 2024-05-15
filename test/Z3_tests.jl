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

@testitem "create int sort" begin
    sort = IntSort()
    @test "$sort" == "Int"
end

@testitem "create int value" begin
    n = IntVal(42)
    @test "$n" == "42"
end

@testitem "int equality" begin
    s = Solver()
    push(s)
    n1 = IntVal(42)
    n2 = IntVal(42)
    add(s, n1 == n2)
    r = check(s)
    @test r == CheckResult(:sat)
    pop(s)
    n3 = IntVal(43)
    add(s, n1 == n3)
    r = check(s)
    @test r == CheckResult(:unsat)
end