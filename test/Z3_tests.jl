@testitem "create sort" begin
    sort = DeclareSort("S")
    @test "$sort" == "S"
end