# This file contains code that was a part of Julia. License is MIT: https://julialang.org/license
# It fixes problems with dealing with AbstractString types that don't use the Char type

import Base: parseint_iterate, parseint_preamble, tryparse_internal
import Base.Checked: add_with_overflow, mul_with_overflow

function parseint_iterate(s::T, startpos::Int, endpos::Int) where {T<:Str}
    C = eltype(T)
    (0 < startpos <= endpos) || (return C(0), 0, 0)
    j = startpos
    c, startpos = iterate(s,startpos)::Tuple{C, Int}
    c, startpos, j
end

function parseint_preamble(signed::Bool, base::Int, s::T, startpos::Int, endpos::Int
                           ) where {T<:Str}
    c, i, j = parseint_iterate(s, startpos, endpos)

    while isspace(c)
        c, i, j = parseint_iterate(s,i,endpos)
    end
    (j == 0) && (return 0, 0, 0)

    sgn = 1
    if signed
        if c == '-' || c == '+'
            (c == '-') && (sgn = -1)
            c, i, j = parseint_iterate(s,i,endpos)
        end
    end

    while isspace(c)
        c, i, j = parseint_iterate(s,i,endpos)
    end
    (j == 0) && (return 0, 0, 0)

    if base == 0
        if c == '0' && i <= ncodeunits(s)
            c, i = iterate(s,i)::Tuple{eltype(s), Int}
            base = c=='b' ? 2 : c=='o' ? 8 : c=='x' ? 16 : 10
            if base != 10
                c, i, j = parseint_iterate(s,i,endpos)
            end
        else
            base = 10
        end
    end
    return sgn, base, j
end

function tryparse_internal(::Type{T}, s::S, startpos::Int, endpos::Int,
                           base_::Integer, raise::Bool) where {T<:Integer, S<:Str}
    C = eltype(S)
    sgn, base, i = parseint_preamble(T<:Signed, Int(base_), s, startpos, endpos)
    if sgn == 0 && base == 0 && i == 0
        raise && throw(ArgumentError("input string is empty or only contains whitespace"))
        return nothing
    end
    if !(2 <= base <= 62)
        raise && throw(ArgumentError("invalid base: base must be 2 ≤ base ≤ 62, got $base"))
        return nothing
    end
    if i == 0
        raise && throw(ArgumentError("premature end of integer: $(repr(SubString(s,startpos,endpos)))"))
        return nothing
    end
    c, i = parseint_iterate(s,i,endpos)
    if i == 0
        raise && throw(ArgumentError("premature end of integer: $(repr(SubString(s,startpos,endpos)))"))
        return nothing
    end

    base = convert(T,base)
    m::T = div(typemax(T)-base+1,base)
    n::T = 0
    a::Int = base <= 36 ? 10 : 36
    while n <= m
        d::T = '0' <= c <= '9' ? c-'0'    :
               'A' <= c <= 'Z' ? c-'A'+10 :
               'a' <= c <= 'z' ? c-'a'+a  : base
        if d >= base
            raise && throw(ArgumentError("invalid base $base digit $(repr(c)) in $(repr(SubString(s,startpos,endpos)))"))
            return nothing
        end
        n *= base
        n += d
        if i > endpos
            n *= sgn
            return n
        end
        c, i = iterate(s,i)::Tuple{C, Int}
        isspace(c) && break
    end
    (T <: Signed) && (n *= sgn)
    while !isspace(c)
        d::T = '0' <= c <= '9' ? c-'0'    :
        'A' <= c <= 'Z' ? c-'A'+10 :
            'a' <= c <= 'z' ? c-'a'+a  : base
        if d >= base
            raise && throw(ArgumentError("invalid base $base digit $(repr(c)) in $(repr(SubString(s,startpos,endpos)))"))
            return nothing
        end
        (T <: Signed) && (d *= sgn)

        n, ov_mul = mul_with_overflow(n, base)
        n, ov_add = add_with_overflow(n, d)
        if ov_mul | ov_add
            raise && throw(OverflowError("overflow parsing $(repr(SubString(s,startpos,endpos)))"))
            return nothing
        end
        (i > endpos) && return n
        c, i = iterate(s,i)::Tuple{C, Int}
    end
    while i <= endpos
        c, i = iterate(s,i)::Tuple{C, Int}
        if !isspace(c)
            raise && throw(ArgumentError("extra characters after whitespace in $(repr(SubString(s,startpos,endpos)))"))
            return nothing
        end
    end
    return n
end
