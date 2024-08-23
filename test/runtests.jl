using MathJuMPAccessories
using Test

@testset "MathJuMPAccessories.jl" begin
    @test MathJuMPAccessories.∑([1,2,3,4,5]) == 15
end
