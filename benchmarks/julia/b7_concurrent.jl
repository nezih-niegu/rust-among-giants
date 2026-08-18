using Base.Threads

const OPS = 10_000_000

# Must be launched with `julia -t 8` — harness does this for b7 specifically.
# Otherwise nthreads()=1 and @threads runs serially, defeating the contention
# scenario this benchmark exists to measure.
mutable struct Counter
    @atomic value::Int64
end

function main()
    @assert nthreads() == 8 "expected 8 threads, got $(nthreads()) — invoke with: julia -t 8"
    c = Counter(0)
    Threads.@threads for _ in 1:8*OPS
        @atomic :monotonic c.value += 1
    end
    println(c.value)
end

main()
