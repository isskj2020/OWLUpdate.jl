using OWLUpdate, Test

@testset "All Tests" begin
    include("single_test.jl")
    include("shapley_test.jl")
    include("bulk_calculation_test.jl")
end
