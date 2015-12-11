# This file is a part of Julia. License is MIT: http://julialang.org/license

# Support for unchecked integer arithmetic

module unchecked

export unchecked_neg, unchecked_abs, unchecked_add, unchecked_sub,
       unchecked_mul, unchecked_div, unchecked_rem, unchecked_fld,
       unchecked_mod, unchecked_cld

import Core.Intrinsics: box, unbox,
       unchecked_sneg_int, unchecked_sadd_int, unchecked_ssub_int,
       unchecked_smul_int, unchecked_sdiv_int, unchecked_srem_int,
       unchecked_uneg_int, unchecked_uadd_int, unchecked_usub_int,
       unchecked_umul_int, unchecked_udiv_int, unchecked_urem_int

typealias SignedInt Union{Int8,Int16,Int32,Int64,Int128}
typealias UnsignedInt Union{UInt8,UInt16,UInt32,UInt64,UInt128}

# LLVM has several code generation bugs for unchecked integer arithmetic (see
# e.g. #4905). We thus distinguish between operations that can be implemented
# via intrinsics, and operations for which we have to provide work-arounds.

# Note: As far as this code has been tested, most unchecked_* functions are
# working fine in LLVM. (Note that division is still handled via `base/int.jl`,
# which always checks for overflow, and which provides its own sets of
# work-arounds for LLVM codegen bugs.) However, the comments in `base/int.jl`
# and in issue #4905 are more pessimistic. For the time being, we thus retain
# the ability to handle codegen bugs in LLVM, until the code here has been
# tested on more systems and architectures.

#=
if VersionNumber(Base.libllvm_version) >= v"3.5"
    # These unions are used for almost all unchecked functions:
    typealias BrokenSignedInt Union{}
    typealias BrokenUnsignedInt Union{}
    # These unions are used for unchecked_mul:
    typealias BrokenSignedIntMul Union{}
    typealias BrokenUnsignedIntMul Union{}
else
    if WORD_SIZE == 32
        typealias BrokenSignedInt Union{}
        typealias BrokenUnsignedInt Union{}
        typealias BrokenSignedIntMul Union{Int8,Int64,Int128}
        typealias BrokenUnsignedIntMul Union{UInt8,UInt64,UInt128}
    else
        typealias BrokenSignedInt Union{}
        typealias BrokenUnsignedInt Union{}
        typealias BrokenSignedIntMul Union{Int8,Int128}
        typealias BrokenUnsignedIntMul Union{UInt8,UInt128}
    end
end
=#
# Use these definitions to test the non-LLVM implementations
typealias BrokenSignedInt SignedInt
typealias BrokenUnsignedInt UnsignedInt
typealias BrokenSignedIntMul SignedInt
typealias BrokenUnsignedIntMul UnsignedInt

# A tight `widen`
nextwide(::Type{Int8}) = Int16
nextwide(::Type{Int16}) = Int32
nextwide(::Type{Int32}) = Int64
nextwide(::Type{Int64}) = Int128
nextwide(::Type{UInt8}) = UInt16
nextwide(::Type{UInt16}) = UInt32
nextwide(::Type{UInt32}) = UInt64
nextwide(::Type{UInt64}) = UInt128
nextwide{T<:Integer}(x::T) = convert(nextwide(T), x)

"""
    Base.unchecked_neg(x)

Calculates `-x` without any overflow checking. It is the caller's
responsiblity to ensure that there is no overflow, and the compiler is free to
optimize the code assuming there is no overflow.
"""
function unchecked_neg end

function unchecked_neg{T<:SignedInt}(x::T)
    box(T, unchecked_sneg_int(unbox(T,x)))
end
function unchecked_neg{T<:UnsignedInt}(x::T)
    box(T, unchecked_uneg_int(unbox(T,x)))
end
unchecked_neg{T<:BrokenSignedInt}(x::T) = -x
unchecked_neg{T<:BrokenUnsignedInt}(x::T) = T(0)

"""
    Base.unchecked_abs(x)

Calculates `abs(x)` without any overflow checking. It is the caller's
responsiblity to ensure that there is no overflow, and the compiler is free to
optimize the code assuming there is no overflow.
"""
function unchecked_abs end

unchecked_abs(x::SignedInt) = ifelse(x<0, -x, x)
unchecked_abs(x::UnsignedInt) = x

"""
    Base.unchecked_add(x, y)

Calculates `x+y` without any overflow checking. It is the caller's
responsiblity to ensure that there is no overflow, and the compiler is free to
optimize the code assuming there is no overflow.
"""
function unchecked_add end

unchecked_add(x::Integer, y::Integer) = unchecked_add(promote(x,y)...)
unchecked_add{T<:Integer}(x::T, y::T) = x+y
function unchecked_add{T<:SignedInt}(x::T, y::T)
    box(T, unchecked_sadd_int(unbox(T,x), unbox(T,y)))
end
function unchecked_add{T<:UnsignedInt}(x::T, y::T)
    box(T, unchecked_uadd_int(unbox(T,x), unbox(T,y)))
end
unchecked_add{T<:BrokenSignedInt}(x::T, y::T) = x+y
unchecked_add{T<:BrokenUnsignedInt}(x::T, y::T) = x+y

# Handle multiple arguments
unchecked_add(x) = x
unchecked_add{T}(x1::T, x2::T, x3::T) =
    unchecked_add(unchecked_add(x1, x2), x3)
unchecked_add{T}(x1::T, x2::T, x3::T, x4::T) =
    unchecked_add(unchecked_add(x1, x2), x3, x4)
unchecked_add{T}(x1::T, x2::T, x3::T, x4::T, x5::T) =
    unchecked_add(unchecked_add(x1, x2), x3, x4, x5)
unchecked_add{T}(x1::T, x2::T, x3::T, x4::T, x5::T, x6::T) =
    unchecked_add(unchecked_add(x1, x2), x3, x4, x5, x6)
unchecked_add{T}(x1::T, x2::T, x3::T, x4::T, x5::T, x6::T, x7::T) =
    unchecked_add(unchecked_add(x1, x2), x3, x4, x5, x6, x7)
unchecked_add{T}(x1::T, x2::T, x3::T, x4::T, x5::T, x6::T, x7::T, x8::T) =
    unchecked_add(unchecked_add(x1, x2), x3, x4, x5, x6, x7, x8)

"""
    Base.unchecked_sub(x, y)

Calculates `x-y` without any overflow checking. It is the caller's
responsiblity to ensure that there is no overflow, and the compiler is free to
optimize the code assuming there is no overflow.
"""
function unchecked_sub end

unchecked_sub(x::Integer, y::Integer) = unchecked_sub(promote(x,y)...)
unchecked_sub{T<:Integer}(x::T, y::T) = x-y
function unchecked_sub{T<:SignedInt}(x::T, y::T)
    box(T, unchecked_ssub_int(unbox(T,x), unbox(T,y)))
end
function unchecked_sub{T<:UnsignedInt}(x::T, y::T)
    box(T, unchecked_usub_int(unbox(T,x), unbox(T,y)))
end
unchecked_sub{T<:BrokenSignedInt}(x::T, y::T) = x-y
unchecked_sub{T<:BrokenUnsignedInt}(x::T, y::T) = x-y

"""
    Base.unchecked_mul(x, y)

Calculates `x*y` without any overflow checking. It is the caller's
responsiblity to ensure that there is no overflow, and the compiler is free to
optimize the code assuming there is no overflow.
"""
function unchecked_mul end

unchecked_mul(x::Integer, y::Integer) = unchecked_mul(promote(x,y)...)
unchecked_mul{T<:Integer}(x::T, y::T) = x*y
function unchecked_mul{T<:SignedInt}(x::T, y::T)
    box(T, unchecked_smul_int(unbox(T,x), unbox(T,y)))
end
function unchecked_mul{T<:UnsignedInt}(x::T, y::T)
    box(T, unchecked_umul_int(unbox(T,x), unbox(T,y)))
end
unchecked_mul{T<:BrokenSignedIntMul}(x::T, y::T) = x*y
unchecked_mul{T<:BrokenUnsignedIntMul}(x::T, y::T) = x*y

# Handle multiple arguments
unchecked_mul(x) = x
unchecked_mul{T}(x1::T, x2::T, x3::T) =
    unchecked_mul(unchecked_mul(x1, x2), x3)
unchecked_mul{T}(x1::T, x2::T, x3::T, x4::T) =
    unchecked_mul(unchecked_mul(x1, x2), x3, x4)
unchecked_mul{T}(x1::T, x2::T, x3::T, x4::T, x5::T) =
    unchecked_mul(unchecked_mul(x1, x2), x3, x4, x5)
unchecked_mul{T}(x1::T, x2::T, x3::T, x4::T, x5::T, x6::T) =
    unchecked_mul(unchecked_mul(x1, x2), x3, x4, x5, x6)
unchecked_mul{T}(x1::T, x2::T, x3::T, x4::T, x5::T, x6::T, x7::T) =
    unchecked_mul(unchecked_mul(x1, x2), x3, x4, x5, x6, x7)
unchecked_mul{T}(x1::T, x2::T, x3::T, x4::T, x5::T, x6::T, x7::T, x8::T) =
    unchecked_mul(unchecked_mul(x1, x2), x3, x4, x5, x6, x7, x8)

"""
    Base.unchecked_div(x, y)

Calculates `div(x,y)` without any overflow checking. It is the caller's
responsiblity to ensure that there is no overflow, and the compiler is free to
optimize the code assuming there is no overflow.
"""
function unchecked_div end

unchecked_div(x::Integer, y::Integer) = unchecked_div(promote(x,y)...)
unchecked_div{T<:Integer}(x::T, y::T) = div(x, y)
function unchecked_div{T<:SignedInt}(x::T, y::T)
    box(T, unchecked_sdiv_int(unbox(T,x), unbox(T,y)))
end
function unchecked_div{T<:UnsignedInt}(x::T, y::T)
    box(T, unchecked_udiv_int(unbox(T,x), unbox(T,y)))
end
unchecked_div{T<:BrokenSignedInt}(x::T, y::T) = div(x, y)
unchecked_div{T<:BrokenUnsignedInt}(x::T, y::T) = div(x, y)

"""
    Base.unchecked_rem(x, y)

Calculates `rem(x,y)` without any overflow checking. It is the caller's
responsiblity to ensure that there is no overflow, and the compiler is free to
optimize the code assuming there is no overflow.
"""
function unchecked_rem end

unchecked_rem(x::Integer, y::Integer) = unchecked_rem(promote(x,y)...)
unchecked_rem{T<:Integer}(x::T, y::T) = rem(x, y)
function unchecked_rem{T<:SignedInt}(x::T, y::T)
    y == -1 && return T(0)   # avoid overflow
    box(T, unchecked_srem_int(unbox(T,x), unbox(T,y)))
end
function unchecked_rem{T<:UnsignedInt}(x::T, y::T)
    box(T, unchecked_urem_int(unbox(T,x), unbox(T,y)))
end
unchecked_rem{T<:BrokenSignedInt}(x::T, y::T) = rem(x, y)
unchecked_rem{T<:BrokenUnsignedInt}(x::T, y::T) = rem(x, y)

"""
    Base.unchecked_fld(x, y)

Calculates `fld(x,y)` without any overflow checking. It is the caller's
responsiblity to ensure that there is no overflow, and the compiler is free to
optimize the code assuming there is no overflow.
"""
function unchecked_fld end

unchecked_fld(x::Integer, y::Integer) = unchecked_fld(promote(x,y)...)
unchecked_fld{T<:Integer}(x::T, y::T) = fld(x, y)
function unchecked_fld{T<:SignedInt}(x::T, y::T)
    d = unchecked_div(x,y)
    d - (((x<0) != (y<0)) & (d*y!=x))
end
unchecked_fld{T<:UnsignedInt}(x::T, y::T) = unchecked_div(x, y)

"""
    Base.unchecked_mod(x, y)

Calculates `mod(x,y)` without any overflow checking. It is the caller's
responsiblity to ensure that there is no overflow, and the compiler is free to
optimize the code assuming there is no overflow.
"""
function unchecked_mod end

unchecked_mod(x::Integer, y::Integer) = unchecked_mod(promote(x,y)...)
unchecked_mod{T<:Integer}(x::T, y::T) = mod(x, y)
function unchecked_mod{T<:SignedInt}(x::T, y::T)
    y == -1 && return T(0)   # avoid potential overflow in fld
    x - unchecked_fld(x,y)*y
end
unchecked_mod{T<:UnsignedInt}(x::T, y::T) = unchecked_rem(x, y)

"""
    Base.unchecked_cld(x, y)

Calculates `cld(x,y)` without any overflow checking. It is the caller's
responsiblity to ensure that there is no overflow, and the compiler is free to
optimize the code assuming there is no overflow.
"""
function unchecked_cld end

unchecked_cld(x::Integer, y::Integer) = unchecked_cld(promote(x,y)...)
unchecked_cld{T<:Integer}(x::T, y::T) = cld(x, y)
function unchecked_cld{T<:SignedInt}(x::T, y::T)
    d = unchecked_div(x,y)
    d + (((x>0) == (y>0)) & (d*y!=x))
end
function unchecked_cld{T<:UnsignedInt}(x::T, y::T)
    d = unchecked_div(x,y)
    d + (d*y!=x)
end

end
