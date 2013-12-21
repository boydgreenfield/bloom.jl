include("probabilities.jl")

type BloomFilter
    array::Union(BitVector, BitArray)
    k::Int
    capacity::Int
    error_rate::Float64
    n_bits::Int
    mmap_location::String
end

### Hash functions (uses 2 hash method)
# Uses MurmurHash on 64-bit systems so sufficiently vast
function hash_n(key::Any, k::Int, max::Int)
    a_hash = hash(key, 0)
    b_hash = hash(key, 170)
    hashes = Array(Uint, k)
    for i in 1:k
        hashes[i] = mod(a_hash + i * b_hash, max) + 1
    end
    return hashes
end

### Bloom filter constructor
# Specify key params explicitly
function BloomFilter(capacity::Int, bits_per_elem::Int, k_hashes::Int)
    n_bits = capacity * bits_per_elem
    BloomFilter(BitVector(n_bits), k_hashes, capacity, NaN, n_bits, "")
end

function BloomFilter(mmap_handle::IOStream, capacity::Int, bits_per_elem::Int, k_hashes::Int)
    n_bits = capacity * bits_per_elem
    mb = mmap_bitarray((n_bits, 1), mmap_handle)
    BloomFilter(mb, k_hashes, capacity, NaN, n_bits, mmap_handle.name)
end

function BloomFilter(mmap_string::String, capacity::Int, bits_per_elem::Int, k_hashes::Int)
    if isfile(mmap_string)
        mmap_handle = open(mmap_string, "r+")
    else
        mmap_handle = open(mmap_string, "w+")
    end
    BloomFilter(mmap_handle, capacity, bits_per_elem, k_hashes)
end

## TODO: Add 3 add'l dispatches (in-memory, IOStream, String) when specifying capacity, error rate, and k (using pre-computed probability table)
# # Specify capacity, error rate, and k (*best* call in many circumstances, uses pre-computed probabilities table)
# function BloomFilter(capacity::Int, error_rate::Float64, k_hashes::Int)
function BloomFilter(capacity::Int, error_rate::Float64, k_hashes::Int)
    bits_per_elem, error_rate = get_k_error(error_rate, k_hashes)
    n_bits = capacity * bits_per_elem
    BloomFilter(BitVector(n_bits), k_hashes, capacity, error_rate, n_bits, "")
end

function BloomFilter(mmap_handle::IOStream, capacity::Int, error_rate::Float64, k_hashes::Int)
    bits_per_elem, error_rate = get_k_error(error_rate, k_hashes)
    n_bits = capacity * bits_per_elem
    mb = mmap_bitarray((n_bits, 1), mmap_handle)
    BloomFilter(mb, k_hashes, capacity, error_rate, n_bits, mmap_handle.name)
end

function BloomFilter(mmap_string::String, capacity::Int, error_rate::Float64, k_hashes::Int)
    if isfile(mmap_string)
        mmap_handle = open(mmap_string, "r+")
    else
        mmap_handle = open(mmap_string, "w+")
    end
    BloomFilter(mmap_handle, capacity, error_rate, k_hashes)
end

# Specify capacity and error rate only, uses optimal number of k hashes (not really recommended as k may become large enough to be computationally taxing)
function BloomFilter(capacity::Int, error_rate::Float64)
    bits_per_elem = int(ceil(-1.0 * (log(error_rate) / (log(2) ^ 2))))
    k_hashes = int(round(log(2) * bits_per_elem))  # Note: ceil() would be strictly more conservative
    n_bits = capacity * bits_per_elem
    BloomFilter(BitVector(n_bits), k_hashes, capacity, error_rate, n_bits, "")
end

function BloomFilter(mmap_handle::IOStream, capacity::Int, error_rate::Float64)
    bits_per_elem = int(ceil(-1.0 * (log(error_rate) / (log(2) ^ 2))))
    k_hashes = int(round(log(2) * bits_per_elem))  # Note: ceil() would be strictly more conservative
    n_bits = capacity * bits_per_elem
    mb = mmap_bitarray((n_bits, 1), mmap_handle)
    BloomFilter(mb, k_hashes, capacity, error_rate, n_bits, mmap_handle.name)
end

function BloomFilter(mmap_string::String, capacity::Int, error_rate::Float64)
    if isfile(mmap_string)
        mmap_handle = open(mmap_string, "r+")
    else
        mmap_handle = open(mmap_string, "w+")
    end
    BloomFilter(mmap_handle, capacity, error_rate)
end

### Bloom filter functions
function insert!(bf::BloomFilter, key::Any)
    hashes = hash_n(key, bf.k, bf.n_bits)
    for h in hashes
        bf.array[h] = 1
    end
end

function contains(bf::BloomFilter, key::Any)
    hashes = hash_n(key, bf.k, bf.n_bits)
    for h in hashes
        if bf.array[h] != 1
            return false
        end
    end
    return true
end

function show(io::IO, bf::BloomFilter)
    @printf "Bloom filter with capacity %d, " bf.capacity
    @printf "error rate of %.2f, and k of %d.\n" (bf.error_rate * 100) (bf.k)
    @printf "Total bits required: %d (%.1f / element).\n" bf.n_bits (bf.n_bits / bf.capacity)
    if bf.mmap_location != ""
        @printf "Bloom filter is backed by mmap at %s." bf.mmap_location
    else
        @printf "Bloom filter is in-memory."
    end
end
