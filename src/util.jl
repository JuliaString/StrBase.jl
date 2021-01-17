#=
Utility functions for Str strings

Copyright 2018-2020 Gandalf Software, Inc., Scott P. Jones,
and other contributors to the Julia language
Licensed under MIT License, see LICENSE.md
Based initially on julia/test/strings/util.jl
=#

function _concat(T, a, b)
    la = ncodeunits(a)
    lb = ncodeunits(b)
    buf, out = _allocate(T, la + lb)
    @preserve a unsafe_copyto!(out, pointer(a), la)
    @preserve b unsafe_copyto!(out + la, pointer(b), lb)
    buf
end

function _string(T, a, b, rest)
    la = ncodeunits(a)
    lb = ncodeunits(b)
    len = la + lb
    @inbounds for str in rest
        len += ncodeunits(str)
    end
    buf, out = _allocate(T, len)
    @preserve a unsafe_copyto!(out, pointer(a), la)
    out += la
    @preserve b unsafe_copyto!(out, pointer(b), lb)
    out += lb
    @inbounds for str in rest
        len = ncodeunits(str)
        @preserve str unsafe_copyto!(out, pointer(str), len)
        out += len
    end
    buf
end

function _string(T, coll)
    len = 0
    @inbounds for str in coll
        len += ncodeunits(str)
    end
    buf, out = _allocate(T, len)
    @inbounds for str in coll
        len = ncodeunits(str)
        @preserve str unsafe_copyto!(out, pointer(str), len)
        out += len
    end
    buf
end

# Handle concatenation where all the same CSE for strings, and character set for characters
#=
"""
WIP: this is rather tricky.
It really should handle any type of Chr / Str / CSE, not just the ones defined
in CharSetEncodings, ChrBase and StrBase
Ideally, it could also handle mixes with String and Char (or other AbstractString / AbstractChar
types.
It may need to do two or even three passes, one to determine the correct type to be output,
another to determine the output length, and finally another to copy the strings / characters into
the buffer.
The result type should be based on promotion rules, i.e. outputting UCS2Str if only ASCII, Latin, UCS2 characters and strings are in the list.
This is difficult to do in a way that will still be type stable.
"""

function _string_chr(a::Union{<:Chr{CS,T}, <:Str{C}, SubString{<:Str{C}}}...
                     ) where {CS<:CharSet,T,C<:CSE{CS}}
    len = 0
    for v in a
        if v isa Chr
            len += 1
        else
            len += ncodeunits(v)
        end
    end
    buf, out = _allocate(T, len)
    for v in a
        len = ncodeunits(str)
        @preserve str unsafe_copyto!(out, pointer(str), len)
        out += len
    end
    buf
end
=#

string(c::MaybeSub{<:Str}) = c
string(c::MaybeSub{<:Str{<:Union{ASCIICSE,Latin_CSEs}}}...) = Str(LatinCSE, _string(UInt8, c))
string(c::MaybeSub{<:Str{<:Union{ASCIICSE,UTF8CSE}}}...) = Str(UTF8CSE, _string(UInt8, c))
string(c::MaybeSub{<:Str{<:UCS2_CSEs}}...) = Str(UCS2CSE, _string(UInt16, c))
string(c::MaybeSub{<:Str{<:Union{UCS2_CSEs,UTF16CSE}}}...) = Str(UTF16CSE, _string(UInt16, c))
string(c::MaybeSub{<:Str{<:UTF32_CSEs}}...) = Str(UTF32CSE, _string(UInt32, c))

#=
const MS_Str{C} = MaybeSub{<:Str{C}}
string(a::MS_Str{C}, b::MS_Str{C}) where {C<:CSE} = Str(C, _concat(codeunit(C), a, b))
string(a::MS_Str{C}, b::MS_Str{C}, c::MS_Str{C}...) where {C<:CSE} =
    Str(C, _string(codeunit(C), a, b, c))

string(a::T, b::T) where {T<:MS_Str{ASCIICSE}} = string(ASCIICSE, _concat(UInt8, a, b))
string(a::T, b::T) where {T<:MS_Str{ASCIICSE}} = string(ASCIICSE, _concat(UInt8, a, b))
string(a::T, b::T) where {T<:MS_Str{ASCIICSE}} = string(ASCIICSE, _concat(UInt8, a, b))

const MS_AL = MS_Str{<:Union{ASCIICSE,Latin_CSEs}}
string(a::MS_AL, b::MS_AL) = Str(LatinCSE, _concat(UInt8, a, b))
string(a::MS_AL, b::MS_AL, c::MS_AL...) = Str(LatinCSE, _string(UInt8, a, b, c))

const MS_AU = MS_Str{<:Union{ASCIICSE,UTF8CSE}}
string(a::MS_AU, b::MS_AU) = Str(UTF8CSE, _concat(UInt8, a, b))
string(a::MS_AU, b::MS_AU, c::MS_AU...) = Str(UTF8CSE, _string(UInt8, a, b, c))

const MS_U2 = MS_Str{<:UCS2_CSEs}
string(a::MS_U2, b::MS_U2) = Str(UCS2CSE, _concat(UInt16, a, b))
string(a::MS_U2, b::MS_U2, c::MS_U2...) = Str(UCS2CSE, _string(UInt16, a, b, c))

const MS_UT = MS_Str{<:Union{UCS2_CSEs,UTF16CSE}}
string(a::MS_UT, b::MS_UT) = Str(UTF16CSE, _concat(UInt16, a, b))
string(a::MS_UT, b::MS_UT, c::MS_UT...) = Str(UTF16CSE, _string(UInt16, a, b, c))

const MS_U4 = MS_Str{<:UTF32_CSEs}
string(a::MS_U4, b::MS_U4) = Str(UTF32CSE, _concat(UInt32, a, b))
string(a::MS_U4, b::MS_U4, c::MS_U4...) = Str(UTF32CSE, _string(UInt32, a, b, c))
=#

#=
string(c::MaybeSub{<:Str{<:Union{ASCIICSE,Latin_CSEs}}}...) =
    length(c) == 1 ? c[1] : Str(LatinCSE, _string(UInt8, c))

string(c::MaybeSub{<:Str{<:Union{ASCIICSE,UTF8CSE}}}...) =
    length(c) == 1 ? c[1] : Str(UTF8CSE, _string(UInt8, c))

string(c::MaybeSub{<:Str{<:UCS2_CSEs}}...) =
    length(c) == 1 ? c[1] : Str(UCS2CSE, _string(UInt16, c))

string(c::MaybeSub{<:Str{<:Union{UCS2_CSEs,UTF16CSE}}}...) =
    length(c) == 1 ? c[1] : Str(UTF16CSE, _string(UInt16, c))

string(c::MaybeSub{<:Str{<:UTF32_CSEs}}...) =
    length(c) == 1 ? c[1] : Str(UTF32CSE, _string(UInt32, c))
=#
string(c::MaybeSub{<:Str{<:Union{ASCIICSE,Latin_CSEs}}}...) = Str(LatinCSE, _string(UInt8, c))
string(c::MaybeSub{<:Str{<:Union{ASCIICSE,UTF8CSE}}}...) = Str(UTF8CSE, _string(UInt8, c))
string(c::MaybeSub{<:Str{<:UCS2_CSEs}}...) = Str(UCS2CSE, _string(UInt16, c))
string(c::MaybeSub{<:Str{<:Union{UCS2_CSEs,UTF16CSE}}}...) = Str(UTF16CSE, _string(UInt16, c))
string(c::MaybeSub{<:Str{<:UTF32_CSEs}}...) = Str(UTF32CSE, _string(UInt32, c))

# starts with and ends with predicates

starts_with(a::MaybeSub{<:Str{C}}, b::MaybeSub{<:Str{C}}) where {C<:CSE} =
    (len = ncodeunits(b)) <= ncodeunits(a) &&
    (@preserve a b _memcmp(pointer(a), pointer(b), len)) == 0

ends_with(a::MaybeSub{<:Str{C}}, b::MaybeSub{<:Str{C}}) where {C<:CSE} =
    (lenb = ncodeunits(b)) <= (lena = ncodeunits(a)) &&
    (@preserve a b _memcmp(pointer(a) + lena - lenb, pointer(b), lenb)) == 0

@static if false
function chop(s::AbstractString; head::Integer = 0, tail::Integer = 1)
    SubString(s, nextind(s, firstindex(s), head), prevind(s, lastindex(s), tail))
end
end # if false

function chomp(str::MaybeSub{<:Str})
    (len = ncodeunits(str)) != 0 && @preserve str begin
        pnt = pointer(str)
        get_codeunit(pnt, len) == 0xa &&
            (len -= (len > 1 && get_codeunit(pnt, len - 1) == 0x0d) + 1)
    end
    SubString(str, 1, thisind(str, len))
end

## string padding functions ##

# Todo: make these not build two strings, and return the correct type (i.e. of the first argument)

function _lpad(cnt, pad, str)
    cnt, rem = divrem(cnt, length(pad))
    rem == 0 ? string(pad^cnt, str) : string(pad^cnt, first(pad, rem), str)
end
lpad(str::MaybeSub{<:Str}, cnt::Integer, pad::AbstractString) =
    (cnt -= length(str)) <= 0 ? str : _lpad(cnt, pad, str)
lpad(ch::Chr, cnt::Integer, pad::AbstractString) =
    (cnt -= 1) <= 0 ? string(ch) : _lpad(cnt, pad, ch)
lpad(str::MaybeSub{<:Str}, cnt::Integer, pad::AbstractChar=' ') =
    (cnt -= length(str)) <= 0 ? str : string(pad^cnt, str)
lpad(ch::Chr, cnt::Integer, pad::AbstractChar=' ') =
    (cnt -= 1) <= 0 ? string(ch) : string(pad^cnt, ch)

function _rpad(cnt, pad, str)
    cnt, rem = divrem(cnt, length(pad))
    rem == 0 ? string(str, pad^cnt) : string(str, pad^cnt, first(pad, rem))
end
rpad(str::MaybeSub{<:Str}, cnt::Integer, pad::AbstractString) =
    (cnt -= length(str)) <= 0 ? str : _rpad(cnt, pad, str)
rpad(ch::Chr, cnt::Integer, pad::AbstractString) =
    (cnt -= 1) <= 0 ? string(ch) : _rpad(cnt, pad, ch)
rpad(str::MaybeSub{<:Str}, cnt::Integer, pad::AbstractChar=' ') =
    (cnt -= length(str)) <= 0 ? str : string(str, pad^cnt)
rpad(ch::Chr, cnt::Integer, pad::AbstractChar=' ') =
    (cnt -= 1) <= 0 ? string(ch) : string(ch, pad^cnt)

const SetOfChars =
    Union{Tuple{Vararg{<:AbstractChar}},AbstractVector{<:AbstractChar},Set{<:AbstractChar}}

function __split(str, splitter, limit::Integer, keep_empty::Bool, strs::Vector)
    pos = 1
    lst = lastindex(str)
    res = find(First, splitter, str)
    if res !== 0:-1
        j, k = first(res), nextind(str, last(res))
        while 0 < j <= lst && length(strs) != limit - 1
            if pos < k
                (keep_empty || pos < j) &&
                    push!(strs, SubString(str, pos, prevind(str, j)))
                pos = k
            end
            (k <= j) && (k = nextind(str, j))
            res = find(Fwd, splitter, str, k)
            res === 0:-1 && break
            j, k = first(res), nextind(str, last(res))
        end
    end
    (keep_empty || pos <= lst) ? push!(strs, SubString(str, pos)) : strs
end

function __rsplit(str, splitter, limit::Integer, keep_empty::Bool, strs::Vector)
    res = find(Last, splitter, str)
    j, k = first(res), last(res)
    pos = lastindex(str)
    while j > 0 && k > 0 && length(strs) != limit-1
        (keep_empty || k < pos) && pushfirst!(strs, SubString(str, nextind(str, k), pos))
        (pos = prevind(str, j)) > 0 || break
        res = find(Rev, splitter, str, pos)
        j, k = first(res), last(res)
    end
    (keep_empty || pos > 0) && pushfirst!(strs, SubString(str, 1, pos))
    strs
end

function checkkeep(keepempty, keep, fun)
    keep === nothing && return keepempty
    Base.depwarn("The `keep` keyword argument is deprecated; use `keepempty` instead", fun)
end

splitarr(::Type{C}) where {C<:CSE} = SubString{Str{basecse(C),Nothing,Nothing,Nothing}}[]

splitarr(::MaybeSub{String}) = SubString{String}[]
splitarr(::MaybeSub{T}) where {T<:Str} =
    SubString{Str{basecse(T),Nothing,Nothing,Nothing}}[]

Base._split(str::MaybeSub{<:Str}, splitter, limit, keepempty, vec) =
    __split(str, splitter, limit, keepempty, vec)
Base._rsplit(str::MaybeSub{<:Str}, splitter, limit, keepempty, vec) =
    __rsplit(str, splitter, limit, keepempty, vec)

split(str::MaybeSub{<:Str}, splitter;
      limit::Integer=0, keepempty::Bool=true, keep::Union{Nothing,Bool}=nothing) =
    __split(str, splitter, limit, checkkeep(keepempty, keep, :split), splitarr(str))

split(str::MaybeSub{<:Str}, splitter::AbstractChar;
      limit::Integer=0, keepempty::Bool=true, keep::Union{Nothing,Bool}=nothing) =
    __split(str, isequal(splitter), limit, checkkeep(keepempty, keep, :split), splitarr(str))

split(str::MaybeSub{<:Str}, splitter::SetOfChars;
      limit::Integer=0, keepempty::Bool=true, keep::Union{Nothing,Bool}=nothing) =
    __split(str, in(splitter), limit, checkkeep(keepempty, keep, :split), splitarr(str))

rsplit(str::MaybeSub{<:Str}, splitter;
       limit::Integer=0, keepempty::Bool=true, keep::Union{Nothing,Bool}=nothing) =
    __rsplit(str, splitter, limit, checkkeep(keepempty, keep, :rsplit), splitarr(str))
rsplit(str::MaybeSub{<:Str}, splitter::AbstractChar;
       limit::Integer=0, keepempty::Bool=true, keep::Union{Nothing,Bool}=nothing) =
    __rsplit(str, isequal(splitter), limit, checkkeep(keepempty, keep, :rsplit), splitarr(str))
rsplit(str::MaybeSub{<:Str}, splitter::SetOfChars;
       limit::Integer=0, keepempty::Bool=true, keep::Union{Nothing,Bool}=nothing) =
    __rsplit(str, in(splitter), limit, checkkeep(keepempty, keep, :rsplit), splitarr(str))

# Todo: this is using print, but it should be changed to make sure that everything is done via
# writes (i.e. no translation to UTF-8)
function __replace(str, pat_repl::Pair; count::Integer=typemax(Int))
    pattern, repl = pat_repl
    count == 0 && return str
    count < 0 && throw(DomainError(count, "`count` must be non-negative."))
    pos = 1
    lst = lastindex(str)
    res = find(First, pattern, str)
    # Just return the string if not found
    (j = first(res)) == 0 && return str

    out = get_iobuffer(floor(Int, 1.2 * sizeof(str)))

    while true
        k = last(res)
        if pos == 1 || pos <= k
            print(out, SubString(str, pos, thisind(str, j - 1)))
            #unsafe_write(out, pointer(str, pos), UInt(j - pos))
            Base._replace(out, repl, str, res, pattern)
        end
        if k < j
            pos = j
            j > lst && break
            k = nextind(str, j)
        else
            pos = k = nextind(str, k)
        end
        (count -= 1) > 0 || break
        res = find(Fwd, pattern, str, k)
        (j = first(res)) == 0 && break
    end
    print(out, SubString(str, pos))
    convert(Str{basecse(str),Nothing,Nothing,Nothing}, String(take!(out)))
end

replace(str::MaybeSub{<:Str}, pat_repl::Pair; count::Integer=typemax(Int)) =
    __replace(str, pat_repl; count=count)
replace(str::MaybeSub{<:Str}, pat_repl::Pair{<:AbstractChar}; count::Integer=typemax(Int)) =
    __replace(str, ==(first(pat_repl)) => last(pat_repl); count=count)
replace(str::MaybeSub{<:Str}, pat_repl::Pair{<:SetOfChars}; count::Integer=typemax(Int)) =
    __replace(str, in(first(pat_repl)) => last(pat_repl); count=count)
