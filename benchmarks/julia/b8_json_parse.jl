# B8: JSON node counting matching cJSON semantics (objects '{', arrays '[',
# string VALUES only — a string followed by ':' is a key and is NOT counted —
# numbers, true/false bools, nulls). Byte scanner; NO external package (Julia's
# JSON is not a stdlib). Output: objects=.. arrays=.. strings=.. numbers=.. bools=.. nulls=..
function main()
    fn = length(ARGS) > 0 ? ARGS[1] : "../../data/json_input.json"
    data = read(fn)::Vector{UInt8}
    n = length(data)
    obj = 0; arr = 0; strv = 0; num = 0; boo = 0; nul = 0
    Q = UInt8('"'); BSL = UInt8('\\'); COL = UInt8(':')
    OB = UInt8('{'); OA = UInt8('[')
    SP = UInt8(' '); TAB = UInt8('\t'); NL = UInt8('\n'); CR = UInt8('\r')
    Z0 = UInt8('0'); Z9 = UInt8('9'); DOT = UInt8('.'); MIN = UInt8('-'); PLU = UInt8('+')
    LE = UInt8('e'); UE = UInt8('E')
    i = 1
    while i <= n
        c = data[i]
        if c == OB
            obj += 1; i += 1
        elseif c == OA
            arr += 1; i += 1
        elseif c == Q
            j = i + 1
            while j <= n
                if data[j] == BSL
                    j += 2; continue
                end
                if data[j] == Q
                    break
                end
                j += 1
            end
            k = j + 1
            while k <= n && (data[k] == SP || data[k] == TAB || data[k] == NL || data[k] == CR)
                k += 1
            end
            if !(k <= n && data[k] == COL)
                strv += 1            # string VALUE (not an object key)
            end
            i = j + 1
        elseif c == UInt8('t')
            if i + 3 <= n && data[i+1] == UInt8('r') && data[i+2] == UInt8('u') && data[i+3] == UInt8('e')
                boo += 1; i += 4
            else
                i += 1
            end
        elseif c == UInt8('f')
            if i + 4 <= n && data[i+1] == UInt8('a') && data[i+2] == UInt8('l') && data[i+3] == UInt8('s') && data[i+4] == UInt8('e')
                boo += 1; i += 5
            else
                i += 1
            end
        elseif c == UInt8('n')
            if i + 3 <= n && data[i+1] == UInt8('u') && data[i+2] == UInt8('l') && data[i+3] == UInt8('l')
                nul += 1; i += 4
            else
                i += 1
            end
        elseif c == MIN || (c >= Z0 && c <= Z9)
            j = i + 1
            while j <= n
                d = data[j]
                if (d >= Z0 && d <= Z9) || d == DOT || d == LE || d == UE || d == PLU || d == MIN
                    j += 1
                else
                    break
                end
            end
            num += 1; i = j
        else
            i += 1
        end
    end
    println("objects=$obj arrays=$arr strings=$strv numbers=$num bools=$boo nulls=$nul")
end
main()
