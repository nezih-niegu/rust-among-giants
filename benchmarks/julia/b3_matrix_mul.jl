using Printf
const SIZE = 2000

# LCG matches the other 8 languages — all 9 produce identical matrices and checksum
const RNG = Ref(UInt64(42))
@inline function next_double()
    RNG[] = RNG[] * UInt64(6364136223846793005) + UInt64(1442695040888963407)
    return Float64(RNG[] >> 33) / Float64(UInt64(1) << 31)
end

# Flat 1D rather than Julia's native column-major Matrix: the row-major ikj loop
# would otherwise be stride-SIZE in the inner j and tank Julia for reasons unrelated
# to language performance.
function init!(A::Vector{Float64}, B::Vector{Float64})
    @inbounds for i in 1:length(A)
        A[i] = next_double()
        B[i] = next_double()
    end
end

function matmul!(C::Vector{Float64}, A::Vector{Float64}, B::Vector{Float64}, n::Int)
    @inbounds for i in 0:n-1
        for k in 0:n-1
            a_ik = A[i*n + k + 1]
            for j in 0:n-1
                C[i*n + j + 1] += a_ik * B[k*n + j + 1]
            end
        end
    end
end

# Wrap the hot path in a function — Julia compiles global non-const accesses as
# dynamic dispatch (Any), which silently makes the matmul 10-50x slower.
function main()
    A = Vector{Float64}(undef, SIZE * SIZE)
    B = Vector{Float64}(undef, SIZE * SIZE)
    C = zeros(Float64, SIZE * SIZE)
    init!(A, B)
    matmul!(C, A, B, SIZE)
    @printf("%.6f\n", sum(C))
end

main()
