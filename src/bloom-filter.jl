type BloomFilter
    array::Union(BitVector, BitArray)
    k::Int
    capacity::Int
    error_rate::Float64
    n_bits::Int
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
    BloomFilter(BitVector(n_bits), k_hashes, capacity, NaN, n_bits)
end

function BloomFilter(mmap_handle::IOStream, capacity::Int, bits_per_elem::Int, k_hashes::Int)
    n_bits = capacity * bits_per_elem
    mb = mmap_bitarray((n_bits, 1), mmap_handle)
    BloomFilter(mb, k_hashes, capacity, NaN, n_bits)
end

function BloomFilter(mmap_string::String, capacity::Int, bits_per_elem::Int, k_hashes::Int)
    if isfile(mmap_string)
        mmap_handle = open(mmap_string, "r+")
    else
        mmap_handle = open(mmap_string, "w+")
    end
    BloomFilter(mmap_handle, bits_per_elem, k_hashes)
end

## TODO: Add 3 add'l dispatches (in-memory, IOStream, String) when specifying capacity, error rate, and k (using pre-computed probability table)
# # Specify capacity, error rate, and k (*best* call in many circumstances, uses pre-computed probabilities table)
# function BloomFilter(capacity::Int, error_rate::Float64, k_hashes::Int)

# end

# Specify capacity and error rate only
function BloomFilter(capacity::Int, error_rate::Float64)
    bits_per_elem = int(ceil(-1.0 * (log(error_rate) / (log(2) ^ 2))))
    k_hashes = int(round(log(2) * bits_per_elem))  # Note: ceil() would be strictly more conservative
    n_bits = capacity * bits_per_elem
    BloomFilter(BitVector(n_bits), k_hashes, capacity, error_rate, n_bits)
end

function BloomFilter(mmap_handle::IOStream, capacity::Int, error_rate::Float64)
    bits_per_elem = int(ceil(-1.0 * (log(error_rate) / (log(2) ^ 2))))
    k_hashes = int(round(log(2) * bits_per_elem))  # Note: ceil() would be strictly more conservative
    n_bits = capacity * bits_per_elem
    mb = mmap_bitarray((n_bits, 1), mmap_handle)
    BloomFilter(mb, k_hashes, capacity, error_rate, n_bits)
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
