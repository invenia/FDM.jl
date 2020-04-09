# Dummy type where length(x::DummyType) ≠ length(first(to_vec(x)))
struct DummyType{TX<:Matrix}
    X::TX
end

function FiniteDifferences.to_vec(x::DummyType)
    x_vec, back = to_vec(x.X)
    return x_vec, x_vec -> DummyType(back(x_vec))
end

Base.:(==)(x::DummyType, y::DummyType) = x.X == y.X
Base.length(x::DummyType) = size(x.X, 1)

function test_to_vec(x::T) where {T}
    x_vec, back = to_vec(x)
    @test x_vec isa Vector
    @test x == back(x_vec)
    @test back(x_vec) isa T
    return nothing
end

@testset "to_vec" begin
    @testset "$T" for T in (Float32, ComplexF32, Float64, ComplexF64)
        if T == Float64
            test_to_vec(1.0)
            test_to_vec(1)
        else
            test_to_vec(.7 + .8im)
            test_to_vec(1 + 2im)
        end
        test_to_vec(randn(T, 3))
        test_to_vec(randn(T, 5, 11))
        test_to_vec(randn(T, 13, 17, 19))
        test_to_vec(randn(T, 13, 0, 19))
        test_to_vec([1.0, randn(T, 2), randn(T, 1), 2.0])
        test_to_vec([randn(T, 5, 4, 3), (5, 4, 3), 2.0])
        test_to_vec(reshape([1.0, randn(T, 5, 4, 3), randn(T, 4, 3), 2.0], 2, 2))
        test_to_vec(UpperTriangular(randn(T, 13, 13)))
        test_to_vec(Symmetric(randn(T, 11, 11)))
        test_to_vec(Diagonal(randn(T, 7)))
        test_to_vec(DummyType(randn(T, 2, 9)))
        test_to_vec(SVector{2, T}(1.0, 2.0))
        test_to_vec(SMatrix{2, 2, T}(1.0, 2.0, 3.0, 4.0))

        @testset "$Op" for Op in (Adjoint, Transpose)
            test_to_vec(Op(randn(T, 4, 4)))
            test_to_vec(Op(randn(T, 6)))
            test_to_vec(Op(randn(T, 2, 5)))
        end

        @testset "Tuples" begin
            test_to_vec((5, 4))
            test_to_vec((5, randn(T, 5)))
            test_to_vec((randn(T, 4), randn(T, 4, 3, 2), 1))
            test_to_vec((5, randn(T, 4, 3, 2), UpperTriangular(randn(T, 4, 4)), 2.5))
            test_to_vec(((6, 5), 3, randn(T, 3, 2, 0, 1)))
            test_to_vec((DummyType(randn(T, 2, 7)), DummyType(randn(T, 3, 9))))
            test_to_vec((DummyType(randn(T, 3, 2)), randn(T, 11, 8)))
        end
        @testset "Dictionary" begin
            if T == Float64
                test_to_vec(Dict(:a=>5, :b=>randn(10, 11), :c=>(5, 4, 3)))
            else
                test_to_vec(Dict(:a=>3 + 2im, :b=>randn(T, 10, 11), :c=>(5+im, 2-im, 1+im)))
            end
        end
    end
end
