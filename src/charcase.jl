#=
Case folding for Unicode characters

Copyright 2018 Gandalf Software, Inc., Scott P. Jones
Licensed under MIT License, see LICENSE.md
=#

module CaseTables
include("maketables.jl")

const ct, tupvec, offvec, bitvec, sizvecl, sizvecu = case_tables()
end # module CaseTables

using .CaseTables

const ct = CaseTables.ct

using ModuleInterfaceTools
@api extend ChrBase

_can_upper_lat(c) = ifelse(c > (V6_COMPAT ? 0xdf : 0xde), c != 0xf7, c == 0xb5)

_wide_lower_latin(ch) = (ch == 0xb5) | (ch == 0xff) | (!V6_COMPAT && (ch == 0xdf))

_wide_out_upper(ch) =
    ifelse(ch == 0xb5, 0x39c,
           ifelse(ch == 0xff, 0x178, ifelse(!V6_COMPAT && ch == 0xdf, 0x1e9e, ch%UInt16)))

@inline function _check_tab(mask, tab, ch)
    t = (ch >>> 9)
    ((mask >>> (t & 0x7f)) & 1) != 0 && (off = tab[t+1]) != 0 &&
        (CaseTables.bitvec[off][((ch >>> 5) & 0xf) + 1] & (UInt32(1) << (ch & 0x1f))) != 0
end

@inline _get_tab(off, ch, base) =
    off == 0 ? ch : (off = CaseTables.offvec[off][((ch >>> 5) & 0x1f) + 1]) == 0 ? ch :
    (base + CaseTables.tupvec[off][(ch & 0x1f) + 1])

@inline _get_tab_bmp(mask, tab, ch) =
    (t = (ch >>> 9); ((mask >>> t) & 1) == 0 ? ch : _get_tab(tab[(t>>1)+1], ch, 0x0000))
@inline _get_tab_slp(mask, tab, ch) =
    (t = (ch >>> 9); ((mask >>> (t & 0x7f)) & 1) == 0 ? ch : _get_tab(tab[(t>>1)+1], ch, 0x10000))

@inline _upper_lat(ch) = _get_tab(ct.u_tab[1], ch, 0x0000)

@inline _upper_bmp(ch) = _get_tab_bmp(ct.can_u_flg, ct.u_tab, ch)
@inline _lower_bmp(ch) = _get_tab_bmp(ct.can_l_flg, ct.l_tab, ch)
@inline _title_bmp(ch) = _get_tab_bmp(ct.can_u_flg, ct.t_tab, ch)
@inline _upper_slp(ch) = _get_tab_slp(ct.can_su_flg, ct.u_tab, ch)
@inline _lower_slp(ch) = _get_tab_slp(ct.can_sl_flg, ct.l_tab, ch)

@inline _can_lower_bmp(ch) = _check_tab(ct.can_l_flg, ct.can_l_tab, ch)
@inline _can_upper_bmp(ch) = _check_tab(ct.can_u_flg, ct.can_u_tab, ch)
@inline _can_lower_slp(ch) = _check_tab(ct.can_sl_flg, ct.can_l_tab, ch)
@inline _can_upper_slp(ch) = _check_tab(ct.can_su_flg, ct.can_u_tab, ch)
@inline _is_lower_bmp(ch)  = _check_tab(ct.is_l_flg, ct.is_l_tab, ch)
@inline _is_upper_bmp(ch)  = _check_tab(ct.is_u_flg, ct.is_u_tab, ch)
@inline _is_lower_slp(ch)  = _check_tab(ct.is_sl_flg, ct.is_sl_tab, ch)
@inline _is_upper_slp(ch)  = _check_tab(ct.is_su_flg, ct.is_su_tab, ch)

const _can_title_bmp = _can_upper_bmp

@inline _is_lower_ch(ch) =
    ch <= 0x7f ? _islower_a(ch) :
    ch <= 0xff ? _islower_l(ch) :
    ch <= 0xffff ? _is_lower_bmp(ch) :
    ch <= 0x1ffff ? _is_lower_slp(ch) : false

@inline _is_upper_ch(ch) =
    ch <= 0x7f ? _isupper_a(ch) :
    ch <= 0xff ? _isupper_l(ch) :
    ch <= 0xffff ? _is_upper_bmp(ch) :
    ch <= 0x1ffff ? _is_upper_slp(ch) : false

@inline _can_lower_ch(ch) =
    ch <= 0x7f ? _isupper_a(ch) :
    ch <= 0xff ? _isupper_l(ch) :
    ch <= 0xffff ? _can_lower_bmp(ch) :
    ch <= 0x1ffff ? _can_lower_slp(ch) : false

@inline _can_upper_ch(ch) =
    ch <= 0x7f ? _islower_a(ch) :
    ch <= 0xff ? _can_upper_lat(ch) :
    ch <= 0xffff ? _can_upper_bmp(ch) :
    ch <= 0x1ffff ? _can_upper_slp(ch) : false

@inline _lower_ch(ch) =
    ch <= 0x7f ? (ch + (_isupper_a(ch)<<5)) :
    ch <= 0xff ? (ch + (_isupper_l(ch)<<5)) :
    ch <= 0xffff ? _lower_bmp(ch) :
    ch <= 0x1ffff ? _lower_slp(ch) : ch

@inline _upper_ch(ch) =
    ch <= 0x7f ? (_islower_a(ch) ? (ch - 0x20) : ch) :
    ch <= 0xff ? _upper_lat(ch) :
    ch <= 0xffff ? _upper_bmp(ch) :
    ch <= 0x1ffff ? _upper_slp(ch) : ch

@inline _title_ch(ch) =
    ch <= 0x7f ? (_islower_a(ch) ? (ch - 0x20) : ch) :
    ch <= 0xff ? _upper_lat(ch) :
    ch <= 0xffff ? _title_bmp(ch) :
    ch <= 0x1ffff ? _upper_slp(ch) : ch
