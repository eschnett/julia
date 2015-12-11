# This file is a part of Julia. License is MIT: http://julialang.org/license

# unchecked integer arithmetic

import Base.Unchecked:
    unchecked_abs, unchecked_neg, unchecked_add, unchecked_sub,
    unchecked_mul, unchecked_div, unchecked_rem, unchecked_fld,
    unchecked_mod, unchecked_cld

# Test return types
for T in (Int8,Int16,Int32,Int64,Int128, UInt8,UInt16,UInt32,UInt64,UInt128)
    z, o = T(0), T(1)
    @test typeof(unchecked_neg(z)) === T
    @test typeof(unchecked_abs(z)) === T
    @test typeof(unchecked_add(z)) === T
    @test typeof(unchecked_mul(z)) === T
    @test typeof(unchecked_add(z,z)) === T
    @test typeof(unchecked_sub(z,z)) === T
    @test typeof(unchecked_mul(z,z)) === T
    @test typeof(unchecked_div(z,o)) === T
    @test typeof(unchecked_rem(z,o)) === T
    @test typeof(unchecked_fld(z,o)) === T
    @test typeof(unchecked_mod(z,o)) === T
    @test typeof(unchecked_cld(z,o)) === T
end

# unchecked operations

for T in (Int8, Int16, Int32, Int64, Int128)
    # regular cases
    for s in (-1, +1)
        @test unchecked_abs(T(0s)) === T(abs(0s))
        @test unchecked_neg(T(0s)) === T(-(0s))
        @test unchecked_add(T(0s)) === T(0s)
        @test unchecked_mul(T(0s)) === T(0s)
        @test unchecked_abs(T(3s)) === T(abs(3s))
        @test unchecked_neg(T(3s)) === T(-(3s))
        @test unchecked_add(T(3s)) === T(3s)
        @test unchecked_mul(T(3s)) === T(3s)
        @test unchecked_abs(T(s*typemax(T))) === typemax(T)
        @test unchecked_neg(T(s*typemax(T))) === T(-s*typemax(T))
        @test unchecked_add(T(s*typemax(T))) === T(s*typemax(T))
        @test unchecked_mul(T(s*typemax(T))) === T(s*typemax(T))
    end

    # regular cases
    for s1 in (-1, +1), s2 in (-1,+1)
        @test unchecked_add(T(4s1), T(3s2)) === T(4s1 + 3s2)
        @test unchecked_sub(T(4s1), T(3s2)) === T(4s1 - 3s2)
        @test unchecked_mul(T(4s1), T(3s2)) === T(4s1 * 3s2)
        @test unchecked_div(T(4s1), T(3s2)) === T(div(4s1, 3s2))
        @test unchecked_rem(T(4s1), T(3s2)) === T(rem(4s1, 3s2))
        @test unchecked_fld(T(4s1), T(3s2)) === T(fld(4s1, 3s2))
        @test unchecked_mod(T(4s1), T(3s2)) === T(mod(4s1, 3s2))
        @test unchecked_cld(T(4s1), T(3s2)) === T(cld(4s1, 3s2))
    end

    # corner cases
    halfmax = T(typemax(T)÷2)
    halfmax_plus1 = T(halfmax+1)
    halfmin = T(typemin(T)÷2)
    halfmin_minus1 = T(halfmin-1)
    sqrtmax = T(1) << T(sizeof(T)*4)
    half_sqrtmax = sqrtmax >> T(1)
    half_sqrtmax_plus1 = half_sqrtmax + T(1)

    @test unchecked_add(typemax(T), T(-1)) === T(typemax(T) - 1)
    @test unchecked_add(typemax(T), T(0)) === typemax(T)
    @test unchecked_add(typemin(T), T(0)) === typemin(T)
    @test unchecked_add(typemin(T), T(1)) === T(typemin(T) + 1)
    @test unchecked_add(T(-1), typemax(T)) === T(typemax(T) - 1)
    @test unchecked_add(T(0), typemax(T)) === typemax(T)
    @test unchecked_add(T(0), typemin(T)) === typemin(T)
    @test unchecked_add(T(1), typemin(T)) === T(typemin(T) + 1)
    @test unchecked_add(typemax(T), typemin(T)) === T(-1)
    @test unchecked_add(typemin(T), typemax(T)) === T(-1)

    @test unchecked_sub(typemax(T), T(0)) === typemax(T)
    @test unchecked_sub(typemax(T), T(1)) === T(typemax(T) - 1)
    @test unchecked_sub(typemin(T), T(-1)) === T(typemin(T) + 1)
    @test unchecked_sub(typemin(T), T(0)) === typemin(T)
    @test unchecked_sub(T(0), typemax(T)) === T(typemin(T) + 1)
    @test unchecked_sub(T(1), typemax(T)) === T(typemin(T) + 2)
    @test unchecked_sub(T(-1), typemin(T)) === typemax(T)
    @test unchecked_sub(typemax(T), typemax(T)) === T(0)
    @test unchecked_sub(typemin(T), typemin(T)) === T(0)
    @test unchecked_sub(halfmax, T(-halfmin)) === T(-1)

    @test unchecked_mul(typemax(T), T(0)) === T(0)
    @test unchecked_mul(typemin(T), T(0)) === T(0)
    @test unchecked_mul(typemax(T), T(1)) === typemax(T)
    @test unchecked_mul(typemin(T), T(1)) === typemin(T)
    @test unchecked_mul(sqrtmax, -half_sqrtmax) === T(sqrtmax * -half_sqrtmax)
    @test unchecked_mul(-sqrtmax, half_sqrtmax) === T(-sqrtmax * half_sqrtmax)

    @test unchecked_div(typemax(T), T(1)) === typemax(T)
    @test unchecked_div(typemax(T), T(-1)) === T(-typemax(T))
    @test unchecked_div(typemin(T), T(1)) === typemin(T)
    @test unchecked_rem(typemax(T), T(1)) === T(0)
    @test unchecked_rem(typemax(T), T(-1)) === T(0)
    @test unchecked_rem(typemin(T), T(1)) === T(0)
    @test unchecked_rem(typemin(T), T(-1)) === T(0)
    @test unchecked_fld(typemax(T), T(1)) === typemax(T)
    @test unchecked_fld(typemax(T), T(-1)) === T(-typemax(T))
    @test unchecked_fld(typemin(T), T(1)) === typemin(T)
    @test unchecked_mod(typemax(T), T(1)) === T(0)
    @test unchecked_mod(typemax(T), T(-1)) === T(0)
    @test unchecked_mod(typemin(T), T(1)) === T(0)
    @test unchecked_mod(typemin(T), T(-1)) === T(0)
    @test unchecked_cld(typemax(T), T(-1)) === T(-typemax(T))
    @test unchecked_cld(typemin(T), T(1)) === typemin(T)
end

for T in (UInt8, UInt16, UInt32, UInt64, UInt128)
    # regular cases
    @test unchecked_abs(T(0)) === T(0)
    @test unchecked_neg(T(0)) === T(0)
    @test unchecked_abs(T(3)) === T(3)

    # regular cases
    @test unchecked_add(T(4), T(3)) === T(7)
    @test unchecked_sub(T(4), T(3)) === T(1)
    @test unchecked_mul(T(4), T(3)) === T(12)

    # corner cases
    halfmax = T(typemax(T)÷2)
    halfmax_plus1 = T(halfmax+1)
    sqrtmax = T(1) << T(sizeof(T)*4)

    @test unchecked_add(typemax(T), T(0)) === typemax(T)
    @test unchecked_add(T(0), T(0)) === T(0)
    @test unchecked_add(T(0), T(1)) === T(T(0) + 1)
    @test unchecked_add(T(0), typemax(T)) === typemax(T)
    @test unchecked_add(T(0), T(0)) === T(0)
    @test unchecked_add(T(1), T(0)) === T(T(0) + 1)
    @test unchecked_add(typemax(T), T(0)) === typemax(T)
    @test unchecked_add(T(0), typemax(T)) === typemax(T)

    @test unchecked_sub(typemax(T), T(0)) === typemax(T)
    @test unchecked_sub(typemax(T), T(1)) === T(typemax(T) - 1)
    @test unchecked_sub(T(0), T(0)) === T(0)
    @test unchecked_sub(T(0), T(0)) === T(0)
    @test unchecked_sub(typemax(T), typemax(T)) === T(0)

    @test unchecked_mul(typemax(T), T(0)) === T(0)
    @test unchecked_mul(T(0), T(0)) === T(0)
    @test unchecked_mul(typemax(T), T(1)) === typemax(T)
    @test unchecked_mul(T(0), T(1)) === T(0)

    @test unchecked_div(typemax(T), T(1)) === typemax(T)
    @test unchecked_rem(typemax(T), T(1)) === T(0)
    @test unchecked_fld(typemax(T), T(1)) === typemax(T)
    @test unchecked_mod(typemax(T), T(1)) === T(0)
    @test unchecked_cld(typemax(T), T(1)) === typemax(T)
end
