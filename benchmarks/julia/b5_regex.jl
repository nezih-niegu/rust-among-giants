# Hot loop in a typed function so eachline/occursin run with concrete types
# rather than dispatching through Any-typed globals.
function count_matches(io::IO, pat::Regex)
    count = 0
    for line in eachline(io)
        if occursin(pat, line)
            count += 1
        end
    end
    return count
end

function main()
    fn = length(ARGS) > 0 ? ARGS[1] : "../../data/regex_input.txt"
    pat = r"[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}"
    n = open(io -> count_matches(io, pat), fn)
    println(n)
end

main()
