__precompile__(true)
"""
StrBase package

Copyright 2017-2018 Gandalf Software, Inc., Scott P. Jones,
and other contributors to the Julia language
Licensed under MIT License, see LICENSE.md
Based partly on code in LegacyStrings that used to be part of Julia
"""
module StrBase

using StrAPI, CharSetEncodings, Chars

@import_list StrAPI base_api_ext base_dev_ext
@using_list  StrAPI api_def dev_def
@import_list StrAPI api_ext dev_ext
@using_list  CharSetEncodings api_def dev_def
@import_list CharSetEncodings api_ext
@using_list  Chars api_def dev_def
@import_list Chars api_ext dev_ext

const api_ext = Symbol[]
const api_def = Symbol[]
const dev_ext = Symbol[]
const dev_def = Symbol[]

# Convenience aliases
const SingleCU = SingleCodeUnitEncoding
const MultiCU  = MultiCodeUnitEncoding
const SCU = SingleCU()
const MCU = MultiCU()

# Convenience functions
push!(api_ext, :str, :unsafe_str, :to_ascii, :utf8, :utf16, :utf32, :is_mutable, :index)
push!(dev_def, :LineCounts, :CharTypes, :CharStat, :maxbit, :calcstats)
push!(dev_def, :UTF_LONG, :UTF_LATIN1, :UTF_UNICODE2, :UTF_UNICODE3, :UTF_UNICODE4,
      :UTF_SURROGATE, :UTF_INVALID, :check_continuation,
      :_memcmp, :_memcpy, :_memset, :_fwd_memchr, :_rev_memchr)
push!(dev_ext, :check_string, :unsafe_check_string, :fast_check_string, :skipascii, :skipbmp,
      :countmask, :count_chars, :_count_mask_al, :_count_mask_ul, :count_latin,
      :byte_string_classify, :_copysub, :_cvtsize, _repeat)

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

end # module StrBase
