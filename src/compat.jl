# This file contains code that was a part of Julia
# License is MIT: see LICENSE.md

## Start of codeunits support from basic.jl ======================================
##
function sizeof(str::SubString{T}) where {T<:Str}
    is_multi(str) || return str.endof
    str.endof == 0 && return 0
    _nextind(MultiCU(), str.string, str.offset + str.endof) - str.offset - 1
end

function repeat(ch::Char, cnt::Integer)
    cnt > 1 && return String(_repeat(MultiCU(), UTF8CSE, ch%UInt32, cnt))
    cnt < 0 && repeaterr(cnt)
    cnt == 0 ? empty_string : string(Char(ch%UInt32))
end

function thisind(str::String, pos::Integer)
    pos == 0 && return 0
    len = ncodeunits(str)
    pos == len + 1 && return pos
    @boundscheck 0 < pos <= len || boundserr(str, pos)
    pnt = pointer(str) + pos - 1
    pos - (checkcont(pnt) ? (checkcont(pnt - 1) ? (checkcont(pnt - 2) ? 3 : 2) : 1) : 0)
end

typemin(::Type{String}) = ""

const _Chars = Union{<:Chr,Tuple{Vararg{<:Chr}},AbstractArray{<:Chr},Set{<:Chr},Base.Chars}

starts_with(str::AbstractString, chars::_Chars) = !is_empty(str) && first(str) in chars

ends_with(str::AbstractString, chars::_Chars) = !is_empty(str) && last(str) in chars

function Base.lstrip(s::AbstractString, chars::_Chars)
    e = lastindex(s)
    for (i, c) in pairs(s)
        c in chars || return SubString(s, i, e)
    end
    SubString(s, e+1, e)
end

@static if NEW_ITERATE
using Iterators
function Base.rstrip(f, s::AbstractString)
    for (i, c) in Iterators.reverse(pairs(s))
        f(c) || return SubString(s, 1, i)
    end
    SubString(s, 1, 0)
end
else
function Base.rstrip(s::AbstractString, chars::_Chars)
    r = RevString(s)
    i = start(r)
    while !done(r,i)
        c, j = next(r,i)
        c in chars || return s[1:end-i+1]
        i = j
    end
    s[1:0]
end
end

Base.strip(s::AbstractString, chars::_Chars) = lstrip(rstrip(s, chars), chars)

function Base.length(s::AbstractString, i::Int, j::Int)
    @boundscheck begin
        0 < i ≤ ncodeunits(s)+1 || throw(BoundsError(s, i))
        0 ≤ j < ncodeunits(s)+1 || throw(BoundsError(s, j))
    end
    n = 0
    for k = i:j
        @inbounds n += isvalid(s, k)
    end
    return n
end

@propagate_inbounds Base.length(s::AbstractString, i::Integer, j::Integer) =
    length(s, Int(i), Int(j))

@inline function _length(s::String, i::Int, n::Int, c::Int)
    i < n || return c
    @inbounds b = codeunit(s, i)
    @inbounds while true
        while true
            (i += 1) ≤ n || return c
            0xc0 ≤ b ≤ 0xf7 && break
            b = codeunit(s, i)
        end
        l = b
        b = codeunit(s, i) # cont byte 1
        c -= (x = b & 0xc0 == 0x80)
        x & (l ≥ 0xe0) || continue

        (i += 1) ≤ n || return c
        b = codeunit(s, i) # cont byte 2
        c -= (x = b & 0xc0 == 0x80)
        x & (l ≥ 0xf0) || continue

        (i += 1) ≤ n || return c
        b = codeunit(s, i) # cont byte 3
        c -= (b & 0xc0 == 0x80)
    end
end

function Base.length(s::String, i::Int, j::Int)
    @boundscheck begin
        0 < i ≤ ncodeunits(s)+1 || throw(BoundsError(s, i))
        0 ≤ j < ncodeunits(s)+1 || throw(BoundsError(s, j))
    end
    j < i && return 0
    @inbounds i, k = thisind(s, i), i
    c = j - i + (i == k)
    _length(s, i, j, c)
end

occurs_in(needle::String, str::String) = contains(str, needle)
occurs_in(needle::Char,   str::String) = contains(str, string(needle))
