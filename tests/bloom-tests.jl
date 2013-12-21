using Bloom

n = 100000
println(hash_n("Testing...", 5, 100000))
println("Hello.")
bf = BloomFilter(n, 0.001)
bf2 = BloomFilter(BitVector(10), 1, 1, 0.1, 10)
bf3 = BloomFilter(10000, 15, 3)
bf4 = BloomFilter(open("/tmp/test_array1.array", "w+"), n, 0.001)

println(contains(bf3, "testing..."))
insert!(bf3, "testing...")
println(contains(bf3, "testing..."))

# Test actual instantiation
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
    insert!(bf, test_key)
end
)

println("For lookups:")
@time(
for test_key in test_keys
    assert(contains(bf, test_key))
end
)

println("For insertions (mmap-backed):")
@time(
for test_key in test_keys
    insert!(bf4, test_key)
end
)

println("For lookups (mmap-backed):")
@time(
for test_key in test_keys
    assert(contains(bf4, test_key))
end
)


# Test re-opening bf4
#msync(bf4.array)  # Not needed I don't think (but need to follow-up)
bf4 = 0
gc()

bf4 = BloomFilter(open("/tmp/test_array1.array", "r+"), n, 0.001)
println("For lookups after re-opening (mmap-backed):")
@time(
for test_key in test_keys
    assert(contains(bf4, test_key))
end
)

bf4 = 0
gc()

bf4 = BloomFilter("/tmp/test_array1.array", n, 0.001)
println("For lookups after re-opening second time (mmap-backed):")
@time(
for test_key in test_keys
    assert(contains(bf4, test_key))
end
)
