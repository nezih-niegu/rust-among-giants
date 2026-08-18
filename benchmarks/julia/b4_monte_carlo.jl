using Printf

const ITERATIONS = 1_000_000_000

mutable struct SimpleRNG
    state::UInt64
end

function next_double!(rng::SimpleRNG)::Float64
    rng.state = rng.state * UInt64(6364136223846793005) + UInt64(1442695040888963407)
    return Float64(rng.state >> 33) / Float64(UInt64(1) << 31)
end

# Hot loop wrapped in a function — Julia compiles global non-const accesses as
# dynamic dispatch (Any), which silently makes 100M-iter loops 10-50x slower.
function main()
    rng = SimpleRNG(UInt64(42))
    inside = Int64(0)
    for _ in 1:ITERATIONS
        x = next_double!(rng)
        y = next_double!(rng)
        if x*x + y*y <= 1.0
            inside += 1
        end
    end
    @printf("%.10f\n", 4.0 * inside / ITERATIONS)
end

main()
