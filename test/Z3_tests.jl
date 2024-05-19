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

# @testitem "simple solve" begin
#     init_ctx()
#     s = Solver()
#     push(s)
#     add(s, BoolVal(false))
#     r = check(s)
#     @test r == CheckResult(:unsat)
#     pop(s)
#     r = check(s)
#     @test r == CheckResult(:sat)
#     add(s, BoolVal(true))
#     @test check(s) == CheckResult(:sat)
#     # del_solver(s)
#     clear_ctx()
# end

@testitem "create int sort" begin
    sort = IntSort()
    @test "$sort" == "Int"
end

@testitem "create int value" begin
    n = IntVal(42)
    @test "$n" == "42"
end

# @testitem "int equality" begin
#     init_ctx()
#     s = Solver()
#     n1 = IntVal(42)
#     n2 = IntVal(42)
#     add(s, n1 == n2)
#     r = check(s)
#     @test r == CheckResult(:sat)
#     n3 = IntVal(43)
#     add(s, n1 == n3)
#     r = check(s)
#     @test r == CheckResult(:unsat)
#     # del_solver(s)
#     clear_ctx()
# end

@testitem "create bitvec sort" begin
    sort = BitVecSort(8)
    @test "$sort" == "(_ BitVec 8)"
end

@testitem "create bitvec value" begin
    v = BitVecVal(42, 8)
    @test "$v" == "#x2a"
end

@testitem "create float sorts" begin
    sort = Float16Sort()
    @test "$sort" == "(_ FloatingPoint 5 11)"
    sort = Float32Sort()
    @test "$sort" == "(_ FloatingPoint 8 24)"
    sort = Float64Sort()
    @test "$sort" == "(_ FloatingPoint 11 53)"
end

@testitem "create float values" begin
    v = Float32Val(Float32(3.14))
    # hex & binary representation of 3.14
    @test "$v" == "(fp #b0 #x80 #b10010001111010111000011)"
    v = Float64Val(Float64(3.14))
    # binary & hex representation of 3.14
    @test "$v" == "(fp #b0 #b10000000000 #x91eb851eb851f)"
end