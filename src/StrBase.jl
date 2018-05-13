__precompile__(true)
"""
StrBase package

Copyright 2017-2018 Gandalf Software, Inc., Scott P. Jones,
and other contributors to the Julia language
Licensed under MIT License, see LICENSE.md
Based partly on code in LegacyStrings that used to be part of Julia
"""
module StrBase

using APITools
@api init

@api extend StrAPI, CharSetEncodings, Chars

# Convenience aliases
const SingleCU = SingleCodeUnitEncoding
const MultiCU  = MultiCodeUnitEncoding
const SCU = SingleCU()
const MCU = MultiCU()

# Convenience functions

@api public unsafe_str, to_ascii, utf8, utf16, utf32, is_mutable, index

@api develop check_string, unsafe_check_string, fast_check_string, skipascii, skipbmp,
             countmask, count_chars, _count_mask_al, _count_mask_ul, count_latin,
             byte_string_classify, _copysub, _cvtsize, _repeat, empty_str, _data, _pnt64, _str,
             ValidatedStyle, MutableStyle, EqualsStyle, CanContain

@api define_develop LineCounts, CharTypes, CharStat, maxbit, calcstats,
                    UTF_LONG, UTF_LATIN1, UTF_UNICODE2, UTF_UNICODE3, UTF_UNICODE4,
                    UTF_SURROGATE, UTF_INVALID, check_continuation,
                    _memcmp, _memcpy, _memset, _fwd_memchr, _rev_memchr,
                    empty_string, _calcpnt, _mask_bytes, _allocate,
                    MS_UTF8, MS_UTF16, MS_UTF32, MS_SubUTF32, MS_Latin, MS_ByteStr, MS_RawUTF8,
                    _wrap_substr, _empty_sub, CHUNKSZ, CHUNKMSK,
                    AccessType, UInt16_U, UInt32_U, UInt16_S, UInt32_S, UInt16_US, UInt32_US,
                    alignedtype, swappedtype

using Base: @_inline_meta, @propagate_inbounds, @_propagate_inbounds_meta, RefValue

include("types.jl")
@static V6_COMPAT && include("compat.jl")
include("chars.jl")
include("access.jl")
include("traits.jl")
include("utf8proc.jl")
include("unicode.jl")
include("casefold.jl")
include("core.jl")
include("support.jl")
include("compare.jl")
include("ascii.jl")
include("latin.jl")
include("utf8.jl")
include("utf16.jl")
include("utf32.jl")
include("search.jl")
include("utf8search.jl")
include("utf16search.jl")
include("encode.jl")
include("stats.jl")
include("legacy.jl")
include("utf8case.jl")
include("utf16case.jl")
include("util.jl")
include("io.jl")
include("murmurhash3.jl")
include("hash.jl")

@api freeze

end # module StrBase
