const CHUNK = 1024 * 1024
const CHUNKS = 4096

function main()
    fname = length(ARGS) > 0 ? ARGS[1] : "../../data/fileio_test_julia.tmp"
    buf = fill(UInt8('A'), CHUNK)
    open(fname, "w") do f
        for _ in 1:CHUNKS
            write(f, buf)
        end
        flush(f)
        ccall(:fsync, Cint, (Cint,), fd(f))
    end
    total = Int64(0)
    open(fname, "r") do f
        rbuf = Vector{UInt8}(undef, CHUNK)
        while !eof(f)
            n = readbytes!(f, rbuf, CHUNK)
            total += n
        end
    end
    println(total)
    rm(fname)
end

main()
