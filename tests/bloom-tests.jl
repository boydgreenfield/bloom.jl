using Bloom


# Set up 9 sample Bloom filters using different constructors
# (Ordered as in bloom-filter.jl)

# Raw construction
bf0 = BloomFilter(BitVector(10), 4, 10, 0.01, 20, "")

# First group of constructors: capacity, bits per element, k
bf1 = BloomFilter(1000, 20, 4)
bf2 = BloomFilter(open("/tmp/test_array1.array", "w+"), 1000, 20, 4)
bf3 = BloomFilter("/tmp/test_array2.array", 1000, 20, 4)

# Second group of constructors: capacity, error rate, k
bf4 = BloomFilter(1000, 0.01, 5)
bf5 = BloomFilter(open("/tmp/test_array3.array", "w+"), 1000, 0.01, 5)
bf6 = BloomFilter("/tmp/test_array4.array", 1000, 0.01, 5)

# Third group of constructors: capacity and error rate only,
# computes optimal k from a space efficiency perspective
bf7 = BloomFilter(1000, 0.01)
bf8 = BloomFilter(open("/tmp/test_array5.array", "w+"), 1000, 0.01)
bf9 = BloomFilter("/tmp/test_array6.array", 1000, 0.01)

# Now create a larger in-memory Bloom filter and an mmap-backed one for testing
n = 100000
bfa = BloomFilter(n, 0.001, 5)
bfb = BloomFilter("/tmp/test_array_lg.array", n, 0.001, 5)

# Test with random strings
random_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
test_keys = Array(String, n)
for i in 1:n
    temp_str = ""
    for j in 1:8
        temp_str = string(temp_str, random_chars[rand(1:62)])
    end
    test_keys[i] = temp_str
end

println("For insertions:")
@time(
for test_key in test_keys
    insert!(bfa, test_key)
end
)

println("For lookups:")
@time(
for test_key in test_keys
    assert(contains(bfa, test_key))
end
)

println("For insertions (mmap-backed):")
@time(
for test_key in test_keys
    insert!(bfb, test_key)
end
)

println("For lookups (mmap-backed):")
@time(
for test_key in test_keys
    assert(contains(bfb, test_key))
end
)


# Test re-opening bfb
bfb = 0
gc()

bfb = BloomFilter(open("/tmp/test_array_lg.array", "r+"), n, 0.001, 5)
println("For lookups after re-opening (mmap-backed):")
@time(
for test_key in test_keys
    assert(contains(bfb, test_key))
end
)

bfb = 0
gc()

bfb = BloomFilter("/tmp/test_array_lg.array", n, 0.001, 5)
println("For lookups after re-opening second time (mmap-backed):")
@time(
for test_key in test_keys
    assert(contains(bfb, test_key))
end
)

## Note: This doesn't work as hash(x::String, seed::Int)
## is only defined for strings in dict.jl
# # Test insertions of non-string types
# test_other_a = 17    # Int
# test_other_b = 15.6  # Float
# test_other_c = "String" #("Tuples", "of", "strings")

# # Test alias'd command
# add!(bfb, test_other_a)
# add!(bfb, test_other_b)
# add!(bfb, test_other_c)

# assert(contains(bfb, test_other_a))
# assert(contains(bfb, test_other_b))
# assert(contains(bfb, test_other_b))
