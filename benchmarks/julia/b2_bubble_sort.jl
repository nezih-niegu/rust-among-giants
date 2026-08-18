using Random
function bubble_sort!(arr)
    n = length(arr)
    for i in 1:n-1
        swapped = false
        for j in 1:n-i
            if arr[j] > arr[j+1]
                arr[j], arr[j+1] = arr[j+1], arr[j]
                swapped = true
            end
        end
        swapped || break
    end
end
Random.seed!(42)
arr = rand(1:100_000, 100_000)
bubble_sort!(arr)
println(arr[1], " ", arr[end])
