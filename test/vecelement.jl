# This file is a part of Julia. License is MIT: http://julialang.org/license

typealias Vec{N,T} NTuple{N,Base.VecElement{T}}

# Crash report for #15244 motivated this test.
@generated function thrice_iota{N,T}(::Type{Vec{N,T}})
    :(tuple($([:(Base.VecElement(3*$i)) for i in 1:N]...)))
end

function call_iota(N)
    x = thrice_iota(Vec{N,Float32})
    @test x[1].value+x[N].value === 3+3*N
end

call_iota(2)
call_iota(4)
call_iota(7)  # try non-power of two
call_iota(8)
call_iota(16)

# Another crash report for #15244 motivated this test.
immutable Bunch{N,T}
    elts::NTuple{N,Base.VecElement{T}}
end

unpeel(x) = x.elts[1].value

@test unpeel(Bunch{2,Float64}((Base.VecElement(5.0),
                               Base.VecElement(4.0)))) === 5.0

immutable Herd{N,T}
    elts::NTuple{N,Base.VecElement{T}}
    Herd(elts::NTuple{N,T}) = new(ntuple(i->Base.VecElement{T}(elts[i]), N))
end

function check{N,T}(x::Herd{N,T})
    for i=1:N
        @test x.elts[i].value === N*N+i-1
    end
end

check(Herd{1,Int}((1,)))
check(Herd{2,Int}((4,5)))
check(Herd{4,Int}((16,17,18,19)))

