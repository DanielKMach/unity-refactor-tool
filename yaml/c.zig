pub const __builtin_bswap16 = @import("std").zig.c_builtins.__builtin_bswap16;
pub const __builtin_bswap32 = @import("std").zig.c_builtins.__builtin_bswap32;
pub const __builtin_bswap64 = @import("std").zig.c_builtins.__builtin_bswap64;
pub const __builtin_signbit = @import("std").zig.c_builtins.__builtin_signbit;
pub const __builtin_signbitf = @import("std").zig.c_builtins.__builtin_signbitf;
pub const __builtin_popcount = @import("std").zig.c_builtins.__builtin_popcount;
pub const __builtin_ctz = @import("std").zig.c_builtins.__builtin_ctz;
pub const __builtin_clz = @import("std").zig.c_builtins.__builtin_clz;
pub const __builtin_sqrt = @import("std").zig.c_builtins.__builtin_sqrt;
pub const __builtin_sqrtf = @import("std").zig.c_builtins.__builtin_sqrtf;
pub const __builtin_sin = @import("std").zig.c_builtins.__builtin_sin;
pub const __builtin_sinf = @import("std").zig.c_builtins.__builtin_sinf;
pub const __builtin_cos = @import("std").zig.c_builtins.__builtin_cos;
pub const __builtin_cosf = @import("std").zig.c_builtins.__builtin_cosf;
pub const __builtin_exp = @import("std").zig.c_builtins.__builtin_exp;
pub const __builtin_expf = @import("std").zig.c_builtins.__builtin_expf;
pub const __builtin_exp2 = @import("std").zig.c_builtins.__builtin_exp2;
pub const __builtin_exp2f = @import("std").zig.c_builtins.__builtin_exp2f;
pub const __builtin_log = @import("std").zig.c_builtins.__builtin_log;
pub const __builtin_logf = @import("std").zig.c_builtins.__builtin_logf;
pub const __builtin_log2 = @import("std").zig.c_builtins.__builtin_log2;
pub const __builtin_log2f = @import("std").zig.c_builtins.__builtin_log2f;
pub const __builtin_log10 = @import("std").zig.c_builtins.__builtin_log10;
pub const __builtin_log10f = @import("std").zig.c_builtins.__builtin_log10f;
pub const __builtin_abs = @import("std").zig.c_builtins.__builtin_abs;
pub const __builtin_labs = @import("std").zig.c_builtins.__builtin_labs;
pub const __builtin_llabs = @import("std").zig.c_builtins.__builtin_llabs;
pub const __builtin_fabs = @import("std").zig.c_builtins.__builtin_fabs;
pub const __builtin_fabsf = @import("std").zig.c_builtins.__builtin_fabsf;
pub const __builtin_floor = @import("std").zig.c_builtins.__builtin_floor;
pub const __builtin_floorf = @import("std").zig.c_builtins.__builtin_floorf;
pub const __builtin_ceil = @import("std").zig.c_builtins.__builtin_ceil;
pub const __builtin_ceilf = @import("std").zig.c_builtins.__builtin_ceilf;
pub const __builtin_trunc = @import("std").zig.c_builtins.__builtin_trunc;
pub const __builtin_truncf = @import("std").zig.c_builtins.__builtin_truncf;
pub const __builtin_round = @import("std").zig.c_builtins.__builtin_round;
pub const __builtin_roundf = @import("std").zig.c_builtins.__builtin_roundf;
pub const __builtin_strlen = @import("std").zig.c_builtins.__builtin_strlen;
pub const __builtin_strcmp = @import("std").zig.c_builtins.__builtin_strcmp;
pub const __builtin_object_size = @import("std").zig.c_builtins.__builtin_object_size;
pub const __builtin___memset_chk = @import("std").zig.c_builtins.__builtin___memset_chk;
pub const __builtin_memset = @import("std").zig.c_builtins.__builtin_memset;
pub const __builtin___memcpy_chk = @import("std").zig.c_builtins.__builtin___memcpy_chk;
pub const __builtin_memcpy = @import("std").zig.c_builtins.__builtin_memcpy;
pub const __builtin_expect = @import("std").zig.c_builtins.__builtin_expect;
pub const __builtin_nanf = @import("std").zig.c_builtins.__builtin_nanf;
pub const __builtin_huge_valf = @import("std").zig.c_builtins.__builtin_huge_valf;
pub const __builtin_inff = @import("std").zig.c_builtins.__builtin_inff;
pub const __builtin_isnan = @import("std").zig.c_builtins.__builtin_isnan;
pub const __builtin_isinf = @import("std").zig.c_builtins.__builtin_isinf;
pub const __builtin_isinf_sign = @import("std").zig.c_builtins.__builtin_isinf_sign;
pub const __has_builtin = @import("std").zig.c_builtins.__has_builtin;
pub const __builtin_assume = @import("std").zig.c_builtins.__builtin_assume;
pub const __builtin_unreachable = @import("std").zig.c_builtins.__builtin_unreachable;
pub const __builtin_constant_p = @import("std").zig.c_builtins.__builtin_constant_p;
pub const __builtin_mul_overflow = @import("std").zig.c_builtins.__builtin_mul_overflow;
pub const __builtin_va_list = [*c]u8;
pub const __gnuc_va_list = __builtin_va_list;
pub const va_list = __gnuc_va_list;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:610:3: warning: TODO implement translation of stmt class GCCAsmStmtClass

// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:605:36: warning: unable to translate function, demoted to extern
pub extern fn __debugbreak() void;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:632:3: warning: TODO implement translation of stmt class GCCAsmStmtClass

// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:626:60: warning: unable to translate function, demoted to extern
pub extern fn __fastfail(arg_code: c_uint) noreturn;
pub extern fn __mingw_get_crt_info() [*c]const u8;
pub const rsize_t = usize;
pub const ptrdiff_t = c_longlong;
pub const wchar_t = c_ushort;
pub const wint_t = c_ushort;
pub const wctype_t = c_ushort;
pub const errno_t = c_int;
pub const __time32_t = c_long;
pub const __time64_t = c_longlong;
pub const time_t = __time64_t;
pub const struct_threadlocaleinfostruct = extern struct {
    _locale_pctype: [*c]const c_ushort = @import("std").mem.zeroes([*c]const c_ushort),
    _locale_mb_cur_max: c_int = @import("std").mem.zeroes(c_int),
    _locale_lc_codepage: c_uint = @import("std").mem.zeroes(c_uint),
};
pub const struct_threadmbcinfostruct = opaque {};
pub const pthreadlocinfo = [*c]struct_threadlocaleinfostruct;
pub const pthreadmbcinfo = ?*struct_threadmbcinfostruct;
pub const struct___lc_time_data = opaque {};
pub const struct_localeinfo_struct = extern struct {
    locinfo: pthreadlocinfo = @import("std").mem.zeroes(pthreadlocinfo),
    mbcinfo: pthreadmbcinfo = @import("std").mem.zeroes(pthreadmbcinfo),
};
pub const _locale_tstruct = struct_localeinfo_struct;
pub const _locale_t = [*c]struct_localeinfo_struct;
pub const struct_tagLC_ID = extern struct {
    wLanguage: c_ushort = @import("std").mem.zeroes(c_ushort),
    wCountry: c_ushort = @import("std").mem.zeroes(c_ushort),
    wCodePage: c_ushort = @import("std").mem.zeroes(c_ushort),
};
pub const LC_ID = struct_tagLC_ID;
pub const LPLC_ID = [*c]struct_tagLC_ID;
pub const threadlocinfo = struct_threadlocaleinfostruct;
pub extern fn _wdupenv_s(_Buffer: [*c][*c]wchar_t, _BufferSizeInWords: [*c]usize, _VarName: [*c]const wchar_t) errno_t;
pub extern fn _itow_s(_Val: c_int, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _ltow_s(_Val: c_long, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _ultow_s(_Val: c_ulong, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _wgetenv_s(_ReturnSize: [*c]usize, _DstBuf: [*c]wchar_t, _DstSizeInWords: usize, _VarName: [*c]const wchar_t) errno_t;
pub extern fn _i64tow_s(_Val: c_longlong, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _ui64tow_s(_Val: c_ulonglong, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _wmakepath_s(_PathResult: [*c]wchar_t, _SizeInWords: usize, _Drive: [*c]const wchar_t, _Dir: [*c]const wchar_t, _Filename: [*c]const wchar_t, _Ext: [*c]const wchar_t) errno_t;
pub extern fn _wputenv_s(_Name: [*c]const wchar_t, _Value: [*c]const wchar_t) errno_t;
pub extern fn _wsearchenv_s(_Filename: [*c]const wchar_t, _EnvVar: [*c]const wchar_t, _ResultPath: [*c]wchar_t, _SizeInWords: usize) errno_t;
pub extern fn _wsplitpath_s(_FullPath: [*c]const wchar_t, _Drive: [*c]wchar_t, _DriveSizeInWords: usize, _Dir: [*c]wchar_t, _DirSizeInWords: usize, _Filename: [*c]wchar_t, _FilenameSizeInWords: usize, _Ext: [*c]wchar_t, _ExtSizeInWords: usize) errno_t;
pub const _onexit_t = ?*const fn () callconv(.c) c_int;
pub const struct__div_t = extern struct {
    quot: c_int = @import("std").mem.zeroes(c_int),
    rem: c_int = @import("std").mem.zeroes(c_int),
};
pub const div_t = struct__div_t;
pub const struct__ldiv_t = extern struct {
    quot: c_long = @import("std").mem.zeroes(c_long),
    rem: c_long = @import("std").mem.zeroes(c_long),
};
pub const ldiv_t = struct__ldiv_t;
pub const _LDOUBLE = extern struct {
    ld: [10]u8 = @import("std").mem.zeroes([10]u8),
};
pub const _CRT_DOUBLE = extern struct {
    x: f64 = @import("std").mem.zeroes(f64),
};
pub const _CRT_FLOAT = extern struct {
    f: f32 = @import("std").mem.zeroes(f32),
};
pub const _LONGDOUBLE = extern struct {
    x: c_longdouble = @import("std").mem.zeroes(c_longdouble),
};
pub const _LDBL12 = extern struct {
    ld12: [12]u8 = @import("std").mem.zeroes([12]u8),
};
pub extern fn ___mb_cur_max_func() c_int;
pub const _purecall_handler = ?*const fn () callconv(.c) void;
pub extern fn _set_purecall_handler(_Handler: _purecall_handler) _purecall_handler;
pub extern fn _get_purecall_handler() _purecall_handler;
pub const _invalid_parameter_handler = ?*const fn ([*c]const wchar_t, [*c]const wchar_t, [*c]const wchar_t, c_uint, usize) callconv(.c) void;
pub extern fn _set_invalid_parameter_handler(_Handler: _invalid_parameter_handler) _invalid_parameter_handler;
pub extern fn _get_invalid_parameter_handler() _invalid_parameter_handler;
pub extern fn _errno() [*c]c_int;
pub extern fn _set_errno(_Value: c_int) errno_t;
pub extern fn _get_errno(_Value: [*c]c_int) errno_t;
pub extern fn __doserrno() [*c]c_ulong;
pub extern fn _set_doserrno(_Value: c_ulong) errno_t;
pub extern fn _get_doserrno(_Value: [*c]c_ulong) errno_t;
pub extern fn __sys_errlist() [*c][*c]u8;
pub extern fn __sys_nerr() [*c]c_int;
pub extern fn __p___argv() [*c][*c][*c]u8;
pub extern fn __p__fmode() [*c]c_int;
pub extern fn __p___argc() [*c]c_int;
pub extern fn __p___wargv() [*c][*c][*c]wchar_t;
pub extern fn __p__pgmptr() [*c][*c]u8;
pub extern fn __p__wpgmptr() [*c][*c]wchar_t;
pub extern fn _get_pgmptr(_Value: [*c][*c]u8) errno_t;
pub extern fn _get_wpgmptr(_Value: [*c][*c]wchar_t) errno_t;
pub extern fn _set_fmode(_Mode: c_int) errno_t;
pub extern fn _get_fmode(_PMode: [*c]c_int) errno_t;
pub extern fn __p__environ() [*c][*c][*c]u8;
pub extern fn __p__wenviron() [*c][*c][*c]wchar_t;
pub extern fn __p__osplatform() [*c]c_uint;
pub extern fn __p__osver() [*c]c_uint;
pub extern fn __p__winver() [*c]c_uint;
pub extern fn __p__winmajor() [*c]c_uint;
pub extern fn __p__winminor() [*c]c_uint;
pub extern fn _get_osplatform(_Value: [*c]c_uint) errno_t;
pub extern fn _get_osver(_Value: [*c]c_uint) errno_t;
pub extern fn _get_winver(_Value: [*c]c_uint) errno_t;
pub extern fn _get_winmajor(_Value: [*c]c_uint) errno_t;
pub extern fn _get_winminor(_Value: [*c]c_uint) errno_t;
pub extern fn exit(_Code: c_int) noreturn;
pub extern fn _exit(_Code: c_int) noreturn;
pub extern fn quick_exit(_Code: c_int) noreturn;
pub extern fn _Exit(c_int) noreturn;
pub extern fn abort() noreturn;
pub extern fn _set_abort_behavior(_Flags: c_uint, _Mask: c_uint) c_uint;
pub extern fn abs(_X: c_int) c_int;
pub extern fn labs(_X: c_long) c_long;
pub inline fn _abs64(arg_x: c_longlong) c_longlong {
    var x = arg_x;
    _ = &x;
    return __builtin_llabs(x);
}
pub extern fn atexit(?*const fn () callconv(.c) void) c_int;
pub extern fn at_quick_exit(?*const fn () callconv(.c) void) c_int;
pub extern fn atof(_String: [*c]const u8) f64;
pub extern fn _atof_l(_String: [*c]const u8, _Locale: _locale_t) f64;
pub extern fn atoi(_Str: [*c]const u8) c_int;
pub extern fn _atoi_l(_Str: [*c]const u8, _Locale: _locale_t) c_int;
pub extern fn atol(_Str: [*c]const u8) c_long;
pub extern fn _atol_l(_Str: [*c]const u8, _Locale: _locale_t) c_long;
pub extern fn bsearch(_Key: ?*const anyopaque, _Base: ?*const anyopaque, _NumOfElements: usize, _SizeOfElements: usize, _PtFuncCompare: ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.c) c_int) ?*anyopaque;
pub extern fn qsort(_Base: ?*anyopaque, _NumOfElements: usize, _SizeOfElements: usize, _PtFuncCompare: ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.c) c_int) void;
pub extern fn _byteswap_ushort(_Short: c_ushort) c_ushort;
pub extern fn _byteswap_ulong(_Long: c_ulong) c_ulong;
pub extern fn _byteswap_uint64(_Int64: c_ulonglong) c_ulonglong;
pub extern fn div(_Numerator: c_int, _Denominator: c_int) div_t;
pub extern fn getenv(_VarName: [*c]const u8) [*c]u8;
pub extern fn _itoa(_Value: c_int, _Dest: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn _i64toa(_Val: c_longlong, _DstBuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn _ui64toa(_Val: c_ulonglong, _DstBuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn _atoi64(_String: [*c]const u8) c_longlong;
pub extern fn _atoi64_l(_String: [*c]const u8, _Locale: _locale_t) c_longlong;
pub extern fn _strtoi64(_String: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int) c_longlong;
pub extern fn _strtoi64_l(_String: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int, _Locale: _locale_t) c_longlong;
pub extern fn _strtoui64(_String: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int) c_ulonglong;
pub extern fn _strtoui64_l(_String: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int, _Locale: _locale_t) c_ulonglong;
pub extern fn ldiv(_Numerator: c_long, _Denominator: c_long) ldiv_t;
pub extern fn _ltoa(_Value: c_long, _Dest: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn mblen(_Ch: [*c]const u8, _MaxCount: usize) c_int;
pub extern fn _mblen_l(_Ch: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) c_int;
pub extern fn _mbstrlen(_Str: [*c]const u8) usize;
pub extern fn _mbstrlen_l(_Str: [*c]const u8, _Locale: _locale_t) usize;
pub extern fn _mbstrnlen(_Str: [*c]const u8, _MaxCount: usize) usize;
pub extern fn _mbstrnlen_l(_Str: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) usize;
pub extern fn mbtowc(noalias _DstCh: [*c]wchar_t, noalias _SrcCh: [*c]const u8, _SrcSizeInBytes: usize) c_int;
pub extern fn _mbtowc_l(noalias _DstCh: [*c]wchar_t, noalias _SrcCh: [*c]const u8, _SrcSizeInBytes: usize, _Locale: _locale_t) c_int;
pub extern fn mbstowcs(noalias _Dest: [*c]wchar_t, noalias _Source: [*c]const u8, _MaxCount: usize) usize;
pub extern fn _mbstowcs_l(noalias _Dest: [*c]wchar_t, noalias _Source: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) usize;
pub extern fn mkstemp(template_name: [*c]u8) c_int;
pub extern fn rand() c_int;
pub extern fn _set_error_mode(_Mode: c_int) c_int;
pub extern fn srand(_Seed: c_uint) void;
pub extern fn strtod(_Str: [*c]const u8, _EndPtr: [*c][*c]u8) f64;
pub extern fn strtof(nptr: [*c]const u8, endptr: [*c][*c]u8) f32;
pub extern fn strtold([*c]const u8, [*c][*c]u8) c_longdouble;
pub extern fn __strtod(noalias [*c]const u8, noalias [*c][*c]u8) f64;
pub extern fn __mingw_strtof(noalias [*c]const u8, noalias [*c][*c]u8) f32;
pub extern fn __mingw_strtod(noalias [*c]const u8, noalias [*c][*c]u8) f64;
pub extern fn __mingw_strtold(noalias [*c]const u8, noalias [*c][*c]u8) c_longdouble;
pub extern fn _strtof_l(noalias _Str: [*c]const u8, noalias _EndPtr: [*c][*c]u8, _Locale: _locale_t) f32;
pub extern fn _strtod_l(noalias _Str: [*c]const u8, noalias _EndPtr: [*c][*c]u8, _Locale: _locale_t) f64;
pub extern fn strtol(_Str: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int) c_long;
pub extern fn _strtol_l(noalias _Str: [*c]const u8, noalias _EndPtr: [*c][*c]u8, _Radix: c_int, _Locale: _locale_t) c_long;
pub extern fn strtoul(_Str: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int) c_ulong;
pub extern fn _strtoul_l(noalias _Str: [*c]const u8, noalias _EndPtr: [*c][*c]u8, _Radix: c_int, _Locale: _locale_t) c_ulong;
pub extern fn system(_Command: [*c]const u8) c_int;
pub extern fn _ultoa(_Value: c_ulong, _Dest: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn wctomb(_MbCh: [*c]u8, _WCh: wchar_t) c_int;
pub extern fn _wctomb_l(_MbCh: [*c]u8, _WCh: wchar_t, _Locale: _locale_t) c_int;
pub extern fn wcstombs(noalias _Dest: [*c]u8, noalias _Source: [*c]const wchar_t, _MaxCount: usize) usize;
pub extern fn _wcstombs_l(noalias _Dest: [*c]u8, noalias _Source: [*c]const wchar_t, _MaxCount: usize, _Locale: _locale_t) usize;
pub extern fn calloc(_NumOfElements: c_ulonglong, _SizeOfElements: c_ulonglong) ?*anyopaque;
pub extern fn free(_Memory: ?*anyopaque) void;
pub extern fn malloc(_Size: c_ulonglong) ?*anyopaque;
pub extern fn realloc(_Memory: ?*anyopaque, _NewSize: c_ulonglong) ?*anyopaque;
pub extern fn _aligned_free(_Memory: ?*anyopaque) void;
pub extern fn _aligned_malloc(_Size: usize, _Alignment: usize) ?*anyopaque;
pub extern fn _aligned_offset_malloc(_Size: usize, _Alignment: usize, _Offset: usize) ?*anyopaque;
pub extern fn _aligned_realloc(_Memory: ?*anyopaque, _Size: usize, _Alignment: usize) ?*anyopaque;
pub extern fn _aligned_offset_realloc(_Memory: ?*anyopaque, _Size: usize, _Alignment: usize, _Offset: usize) ?*anyopaque;
pub extern fn _recalloc(_Memory: ?*anyopaque, _Count: usize, _Size: usize) ?*anyopaque;
pub extern fn _aligned_recalloc(_Memory: ?*anyopaque, _Count: usize, _Size: usize, _Alignment: usize) ?*anyopaque;
pub extern fn _aligned_offset_recalloc(_Memory: ?*anyopaque, _Count: usize, _Size: usize, _Alignment: usize, _Offset: usize) ?*anyopaque;
pub extern fn _aligned_msize(_Memory: ?*anyopaque, _Alignment: usize, _Offset: usize) usize;
pub extern fn _itow(_Value: c_int, _Dest: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn _ltow(_Value: c_long, _Dest: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn _ultow(_Value: c_ulong, _Dest: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn __mingw_wcstod(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t) f64;
pub extern fn __mingw_wcstof(noalias nptr: [*c]const wchar_t, noalias endptr: [*c][*c]wchar_t) f32;
pub extern fn __mingw_wcstold(noalias [*c]const wchar_t, noalias [*c][*c]wchar_t) c_longdouble;
pub extern fn wcstod(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t) f64;
pub extern fn wcstof(noalias nptr: [*c]const wchar_t, noalias endptr: [*c][*c]wchar_t) f32;
pub extern fn wcstold(noalias [*c]const wchar_t, noalias [*c][*c]wchar_t) c_longdouble;
pub extern fn _wcstod_l(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Locale: _locale_t) f64;
pub extern fn _wcstof_l(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Locale: _locale_t) f32;
pub extern fn wcstol(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Radix: c_int) c_long;
pub extern fn _wcstol_l(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Radix: c_int, _Locale: _locale_t) c_long;
pub extern fn wcstoul(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Radix: c_int) c_ulong;
pub extern fn _wcstoul_l(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Radix: c_int, _Locale: _locale_t) c_ulong;
pub extern fn _wgetenv(_VarName: [*c]const wchar_t) [*c]wchar_t;
pub extern fn _wsystem(_Command: [*c]const wchar_t) c_int;
pub extern fn _wtof(_Str: [*c]const wchar_t) f64;
pub extern fn _wtof_l(_Str: [*c]const wchar_t, _Locale: _locale_t) f64;
pub extern fn _wtoi(_Str: [*c]const wchar_t) c_int;
pub extern fn _wtoi_l(_Str: [*c]const wchar_t, _Locale: _locale_t) c_int;
pub extern fn _wtol(_Str: [*c]const wchar_t) c_long;
pub extern fn _wtol_l(_Str: [*c]const wchar_t, _Locale: _locale_t) c_long;
pub extern fn _i64tow(_Val: c_longlong, _DstBuf: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn _ui64tow(_Val: c_ulonglong, _DstBuf: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn _wtoi64(_Str: [*c]const wchar_t) c_longlong;
pub extern fn _wtoi64_l(_Str: [*c]const wchar_t, _Locale: _locale_t) c_longlong;
pub extern fn _wcstoi64(_Str: [*c]const wchar_t, _EndPtr: [*c][*c]wchar_t, _Radix: c_int) c_longlong;
pub extern fn _wcstoi64_l(_Str: [*c]const wchar_t, _EndPtr: [*c][*c]wchar_t, _Radix: c_int, _Locale: _locale_t) c_longlong;
pub extern fn _wcstoui64(_Str: [*c]const wchar_t, _EndPtr: [*c][*c]wchar_t, _Radix: c_int) c_ulonglong;
pub extern fn _wcstoui64_l(_Str: [*c]const wchar_t, _EndPtr: [*c][*c]wchar_t, _Radix: c_int, _Locale: _locale_t) c_ulonglong;
pub extern fn _putenv(_EnvString: [*c]const u8) c_int;
pub extern fn _wputenv(_EnvString: [*c]const wchar_t) c_int;
pub extern fn _fullpath(_FullPath: [*c]u8, _Path: [*c]const u8, _SizeInBytes: usize) [*c]u8;
pub extern fn _ecvt(_Val: f64, _NumOfDigits: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) [*c]u8;
pub extern fn _fcvt(_Val: f64, _NumOfDec: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) [*c]u8;
pub extern fn _gcvt(_Val: f64, _NumOfDigits: c_int, _DstBuf: [*c]u8) [*c]u8;
pub extern fn _atodbl(_Result: [*c]_CRT_DOUBLE, _Str: [*c]u8) c_int;
pub extern fn _atoldbl(_Result: [*c]_LDOUBLE, _Str: [*c]u8) c_int;
pub extern fn _atoflt(_Result: [*c]_CRT_FLOAT, _Str: [*c]u8) c_int;
pub extern fn _atodbl_l(_Result: [*c]_CRT_DOUBLE, _Str: [*c]u8, _Locale: _locale_t) c_int;
pub extern fn _atoldbl_l(_Result: [*c]_LDOUBLE, _Str: [*c]u8, _Locale: _locale_t) c_int;
pub extern fn _atoflt_l(_Result: [*c]_CRT_FLOAT, _Str: [*c]u8, _Locale: _locale_t) c_int;
pub extern fn _lrotl(c_ulong, c_int) c_ulong;
pub extern fn _lrotr(c_ulong, c_int) c_ulong;
pub extern fn _makepath(_Path: [*c]u8, _Drive: [*c]const u8, _Dir: [*c]const u8, _Filename: [*c]const u8, _Ext: [*c]const u8) void;
pub extern fn _onexit(_Func: _onexit_t) _onexit_t;
pub extern fn perror(_ErrMsg: [*c]const u8) void;
pub extern fn _rotl64(_Val: c_ulonglong, _Shift: c_int) c_ulonglong;
pub extern fn _rotr64(Value: c_ulonglong, Shift: c_int) c_ulonglong;
pub extern fn _rotr(_Val: c_uint, _Shift: c_int) c_uint;
pub extern fn _rotl(_Val: c_uint, _Shift: c_int) c_uint;
pub extern fn _searchenv(_Filename: [*c]const u8, _EnvVar: [*c]const u8, _ResultPath: [*c]u8) void;
pub extern fn _splitpath(_FullPath: [*c]const u8, _Drive: [*c]u8, _Dir: [*c]u8, _Filename: [*c]u8, _Ext: [*c]u8) void;
pub extern fn _swab(_Buf1: [*c]u8, _Buf2: [*c]u8, _SizeInBytes: c_int) void;
pub extern fn _wfullpath(_FullPath: [*c]wchar_t, _Path: [*c]const wchar_t, _SizeInWords: usize) [*c]wchar_t;
pub extern fn _wmakepath(_ResultPath: [*c]wchar_t, _Drive: [*c]const wchar_t, _Dir: [*c]const wchar_t, _Filename: [*c]const wchar_t, _Ext: [*c]const wchar_t) void;
pub extern fn _wperror(_ErrMsg: [*c]const wchar_t) void;
pub extern fn _wsearchenv(_Filename: [*c]const wchar_t, _EnvVar: [*c]const wchar_t, _ResultPath: [*c]wchar_t) void;
pub extern fn _wsplitpath(_FullPath: [*c]const wchar_t, _Drive: [*c]wchar_t, _Dir: [*c]wchar_t, _Filename: [*c]wchar_t, _Ext: [*c]wchar_t) void;
pub extern fn _beep(_Frequency: c_uint, _Duration: c_uint) void;
pub extern fn _seterrormode(_Mode: c_int) void;
pub extern fn _sleep(_Duration: c_ulong) void;
pub extern fn ecvt(_Val: f64, _NumOfDigits: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) [*c]u8;
pub extern fn fcvt(_Val: f64, _NumOfDec: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) [*c]u8;
pub extern fn gcvt(_Val: f64, _NumOfDigits: c_int, _DstBuf: [*c]u8) [*c]u8;
pub extern fn itoa(_Val: c_int, _DstBuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn ltoa(_Val: c_long, _DstBuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn putenv(_EnvString: [*c]const u8) c_int;
pub extern fn swab(_Buf1: [*c]u8, _Buf2: [*c]u8, _SizeInBytes: c_int) void;
pub extern fn ultoa(_Val: c_ulong, _Dstbuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn onexit(_Func: _onexit_t) _onexit_t;
pub const lldiv_t = extern struct {
    quot: c_longlong = @import("std").mem.zeroes(c_longlong),
    rem: c_longlong = @import("std").mem.zeroes(c_longlong),
};
pub extern fn lldiv(c_longlong, c_longlong) lldiv_t;
pub extern fn llabs(c_longlong) c_longlong;
pub extern fn strtoll([*c]const u8, [*c][*c]u8, c_int) c_longlong;
pub extern fn strtoull([*c]const u8, [*c][*c]u8, c_int) c_ulonglong;
pub extern fn atoll([*c]const u8) c_longlong;
pub extern fn wtoll([*c]const wchar_t) c_longlong;
pub extern fn lltoa(c_longlong, [*c]u8, c_int) [*c]u8;
pub extern fn ulltoa(c_ulonglong, [*c]u8, c_int) [*c]u8;
pub extern fn lltow(c_longlong, [*c]wchar_t, c_int) [*c]wchar_t;
pub extern fn ulltow(c_ulonglong, [*c]wchar_t, c_int) [*c]wchar_t;
pub extern fn _dupenv_s(_PBuffer: [*c][*c]u8, _PBufferSizeInBytes: [*c]usize, _VarName: [*c]const u8) errno_t;
pub extern fn bsearch_s(_Key: ?*const anyopaque, _Base: ?*const anyopaque, _NumOfElements: rsize_t, _SizeOfElements: rsize_t, _PtFuncCompare: ?*const fn (?*anyopaque, ?*const anyopaque, ?*const anyopaque) callconv(.c) c_int, _Context: ?*anyopaque) ?*anyopaque;
pub extern fn getenv_s(_ReturnSize: [*c]usize, _DstBuf: [*c]u8, _DstSize: rsize_t, _VarName: [*c]const u8) errno_t;
pub extern fn _itoa_s(_Value: c_int, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn _i64toa_s(_Val: c_longlong, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn _ui64toa_s(_Val: c_ulonglong, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn _ltoa_s(_Val: c_long, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn mbstowcs_s(_PtNumOfCharConverted: [*c]usize, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _SrcBuf: [*c]const u8, _MaxCount: usize) errno_t;
pub extern fn _mbstowcs_s_l(_PtNumOfCharConverted: [*c]usize, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _SrcBuf: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) errno_t;
pub extern fn _ultoa_s(_Val: c_ulong, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn wctomb_s(_SizeConverted: [*c]c_int, _MbCh: [*c]u8, _SizeInBytes: rsize_t, _WCh: wchar_t) errno_t;
pub extern fn _wctomb_s_l(_SizeConverted: [*c]c_int, _MbCh: [*c]u8, _SizeInBytes: usize, _WCh: wchar_t, _Locale: _locale_t) errno_t;
pub extern fn wcstombs_s(_PtNumOfCharConverted: [*c]usize, _Dst: [*c]u8, _DstSizeInBytes: usize, _Src: [*c]const wchar_t, _MaxCountInBytes: usize) errno_t;
pub extern fn _wcstombs_s_l(_PtNumOfCharConverted: [*c]usize, _Dst: [*c]u8, _DstSizeInBytes: usize, _Src: [*c]const wchar_t, _MaxCountInBytes: usize, _Locale: _locale_t) errno_t;
pub extern fn _ecvt_s(_DstBuf: [*c]u8, _Size: usize, _Val: f64, _NumOfDights: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) errno_t;
pub extern fn _fcvt_s(_DstBuf: [*c]u8, _Size: usize, _Val: f64, _NumOfDec: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) errno_t;
pub extern fn _gcvt_s(_DstBuf: [*c]u8, _Size: usize, _Val: f64, _NumOfDigits: c_int) errno_t;
pub extern fn _makepath_s(_PathResult: [*c]u8, _Size: usize, _Drive: [*c]const u8, _Dir: [*c]const u8, _Filename: [*c]const u8, _Ext: [*c]const u8) errno_t;
pub extern fn _putenv_s(_Name: [*c]const u8, _Value: [*c]const u8) errno_t;
pub extern fn _searchenv_s(_Filename: [*c]const u8, _EnvVar: [*c]const u8, _ResultPath: [*c]u8, _SizeInBytes: usize) errno_t;
pub extern fn _splitpath_s(_FullPath: [*c]const u8, _Drive: [*c]u8, _DriveSize: usize, _Dir: [*c]u8, _DirSize: usize, _Filename: [*c]u8, _FilenameSize: usize, _Ext: [*c]u8, _ExtSize: usize) errno_t;
pub extern fn qsort_s(_Base: ?*anyopaque, _NumOfElements: usize, _SizeOfElements: usize, _PtFuncCompare: ?*const fn (?*anyopaque, ?*const anyopaque, ?*const anyopaque) callconv(.c) c_int, _Context: ?*anyopaque) void;
pub const struct__heapinfo = extern struct {
    _pentry: [*c]c_int = @import("std").mem.zeroes([*c]c_int),
    _size: usize = @import("std").mem.zeroes(usize),
    _useflag: c_int = @import("std").mem.zeroes(c_int),
};
pub const _HEAPINFO = struct__heapinfo;
pub extern fn __p__amblksiz() [*c]c_uint;
pub extern fn __mingw_aligned_malloc(_Size: usize, _Alignment: usize) ?*anyopaque;
pub extern fn __mingw_aligned_free(_Memory: ?*anyopaque) void;
pub extern fn __mingw_aligned_offset_realloc(_Memory: ?*anyopaque, _Size: usize, _Alignment: usize, _Offset: usize) ?*anyopaque;
pub extern fn __mingw_aligned_offset_malloc(usize, usize, usize) ?*anyopaque;
pub extern fn __mingw_aligned_realloc(_Memory: ?*anyopaque, _Size: usize, _Offset: usize) ?*anyopaque;
pub extern fn __mingw_aligned_msize(memblock: ?*anyopaque, alignment: usize, offset: usize) usize;
pub inline fn _mm_malloc(arg___size: usize, arg___align: usize) ?*anyopaque {
    var __size = arg___size;
    _ = &__size;
    var __align = arg___align;
    _ = &__align;
    if (__align == @as(usize, @bitCast(@as(c_longlong, @as(c_int, 1))))) {
        return malloc(__size);
    }
    if (!((__align & (__align -% @as(usize, @bitCast(@as(c_longlong, @as(c_int, 1)))))) != 0) and (__align < @sizeOf(?*anyopaque))) {
        __align = @sizeOf(?*anyopaque);
    }
    var __mallocedMemory: ?*anyopaque = undefined;
    _ = &__mallocedMemory;
    __mallocedMemory = __mingw_aligned_malloc(__size, __align);
    return __mallocedMemory;
}
pub inline fn _mm_free(arg___p: ?*anyopaque) void {
    var __p = arg___p;
    _ = &__p;
    __mingw_aligned_free(__p);
}
pub extern fn _resetstkoflw() c_int;
pub extern fn _set_malloc_crt_max_wait(_NewValue: c_ulong) c_ulong;
pub extern fn _expand(_Memory: ?*anyopaque, _NewSize: usize) ?*anyopaque;
pub extern fn _msize(_Memory: ?*anyopaque) usize;
pub extern fn _get_sbh_threshold() usize;
pub extern fn _set_sbh_threshold(_NewValue: usize) c_int;
pub extern fn _set_amblksiz(_Value: usize) errno_t;
pub extern fn _get_amblksiz(_Value: [*c]usize) errno_t;
pub extern fn _heapadd(_Memory: ?*anyopaque, _Size: usize) c_int;
pub extern fn _heapchk() c_int;
pub extern fn _heapmin() c_int;
pub extern fn _heapset(_Fill: c_uint) c_int;
pub extern fn _heapwalk(_EntryInfo: [*c]_HEAPINFO) c_int;
pub extern fn _heapused(_Used: [*c]usize, _Commit: [*c]usize) usize;
pub extern fn _get_heap_handle() isize;
pub fn _MarkAllocaS(arg__Ptr: ?*anyopaque, arg__Marker: c_uint) callconv(.c) ?*anyopaque {
    var _Ptr = arg__Ptr;
    _ = &_Ptr;
    var _Marker = arg__Marker;
    _ = &_Marker;
    if (_Ptr != null) {
        @as([*c]c_uint, @ptrCast(@alignCast(_Ptr))).* = _Marker;
        _Ptr = @as(?*anyopaque, @ptrCast(@as([*c]u8, @ptrCast(@alignCast(_Ptr))) + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 16)))))));
    }
    return _Ptr;
}
pub fn _freea(arg__Memory: ?*anyopaque) callconv(.c) void {
    var _Memory = arg__Memory;
    _ = &_Memory;
    var _Marker: c_uint = undefined;
    _ = &_Marker;
    if (_Memory != null) {
        _Memory = @as(?*anyopaque, @ptrCast(@as([*c]u8, @ptrCast(@alignCast(_Memory))) - @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 16)))))));
        _Marker = @as([*c]c_uint, @ptrCast(@alignCast(_Memory))).*;
        if (_Marker == @as(c_uint, @bitCast(@as(c_int, 56797)))) {
            free(_Memory);
        }
    }
}
pub extern fn __local_stdio_printf_options() [*c]c_ulonglong;
pub extern fn __local_stdio_scanf_options() [*c]c_ulonglong;
pub const struct__iobuf = extern struct {
    _Placeholder: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
};
pub const FILE = struct__iobuf;
pub const _off_t = c_long;
pub const off32_t = c_long;
pub const _off64_t = c_longlong;
pub const off64_t = c_longlong;
pub const off_t = off32_t;
pub extern fn __acrt_iob_func(index: c_uint) [*c]FILE;
pub extern fn __iob_func() [*c]FILE;
pub const fpos_t = c_longlong;
pub extern fn __mingw_sscanf(noalias _Src: [*c]const u8, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn __mingw_vsscanf(noalias _Str: [*c]const u8, noalias Format: [*c]const u8, argp: va_list) c_int;
pub extern fn __mingw_scanf(noalias _Format: [*c]const u8, ...) c_int;
pub extern fn __mingw_vscanf(noalias Format: [*c]const u8, argp: va_list) c_int;
pub extern fn __mingw_fscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn __mingw_vfscanf(noalias fp: [*c]FILE, noalias Format: [*c]const u8, argp: va_list) c_int;
pub extern fn __mingw_vsnprintf(noalias _DstBuf: [*c]u8, _MaxCount: usize, noalias _Format: [*c]const u8, _ArgList: va_list) c_int;
pub extern fn __mingw_snprintf(noalias s: [*c]u8, n: usize, noalias format: [*c]const u8, ...) c_int;
pub extern fn __mingw_printf(noalias [*c]const u8, ...) c_int;
pub extern fn __mingw_vprintf(noalias [*c]const u8, va_list) c_int;
pub extern fn __mingw_fprintf(noalias [*c]FILE, noalias [*c]const u8, ...) c_int;
pub extern fn __mingw_vfprintf(noalias [*c]FILE, noalias [*c]const u8, va_list) c_int;
pub extern fn __mingw_sprintf(noalias [*c]u8, noalias [*c]const u8, ...) c_int;
pub extern fn __mingw_vsprintf(noalias [*c]u8, noalias [*c]const u8, va_list) c_int;
pub extern fn __mingw_asprintf(noalias [*c][*c]u8, noalias [*c]const u8, ...) c_int;
pub extern fn __mingw_vasprintf(noalias [*c][*c]u8, noalias [*c]const u8, va_list) c_int;
pub extern fn __ms_sscanf(noalias _Src: [*c]const u8, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn __ms_vsscanf(noalias _Str: [*c]const u8, noalias _Format: [*c]const u8, argp: va_list) c_int;
pub extern fn __ms_scanf(noalias _Format: [*c]const u8, ...) c_int;
pub extern fn __ms_vscanf(noalias _Format: [*c]const u8, argp: va_list) c_int;
pub extern fn __ms_fscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn __ms_vfscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const u8, argp: va_list) c_int;
pub extern fn __ms_printf(noalias [*c]const u8, ...) c_int;
pub extern fn __ms_vprintf(noalias [*c]const u8, va_list) c_int;
pub extern fn __ms_fprintf(noalias [*c]FILE, noalias [*c]const u8, ...) c_int;
pub extern fn __ms_vfprintf(noalias [*c]FILE, noalias [*c]const u8, va_list) c_int;
pub extern fn __ms_sprintf(noalias [*c]u8, noalias [*c]const u8, ...) c_int;
pub extern fn __ms_vsprintf(noalias [*c]u8, noalias [*c]const u8, va_list) c_int;
pub extern fn __ms_snprintf(noalias [*c]u8, usize, noalias [*c]const u8, ...) c_int;
pub extern fn __ms_vsnprintf(noalias [*c]u8, usize, noalias [*c]const u8, va_list) c_int;
pub extern fn __stdio_common_vsprintf(options: c_ulonglong, str: [*c]u8, len: usize, format: [*c]const u8, locale: _locale_t, valist: va_list) c_int;
pub extern fn __stdio_common_vfprintf(options: c_ulonglong, file: [*c]FILE, format: [*c]const u8, locale: _locale_t, valist: va_list) c_int;
pub extern fn __stdio_common_vsscanf(options: c_ulonglong, input: [*c]const u8, length: usize, format: [*c]const u8, locale: _locale_t, valist: va_list) c_int;
pub extern fn __stdio_common_vfscanf(options: c_ulonglong, file: [*c]FILE, format: [*c]const u8, locale: _locale_t, valist: va_list) c_int;
pub extern fn fprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn printf(_Format: [*c]const u8, ...) c_int;
pub extern fn sprintf(noalias _Dest: [*c]u8, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn vfprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const u8, _ArgList: __builtin_va_list) c_int;
pub extern fn vprintf(noalias _Format: [*c]const u8, _ArgList: __builtin_va_list) c_int;
pub extern fn vsprintf(noalias _Dest: [*c]u8, noalias _Format: [*c]const u8, _Args: __builtin_va_list) c_int;
pub extern fn fscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn scanf(noalias _Format: [*c]const u8, ...) c_int;
pub extern fn sscanf(noalias _Src: [*c]const u8, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn vfscanf(noalias __stream: [*c]FILE, noalias __format: [*c]const u8, __local_argv: __builtin_va_list) c_int;
pub extern fn vsscanf(noalias __source: [*c]const u8, noalias __format: [*c]const u8, __local_argv: __builtin_va_list) c_int;
pub extern fn vscanf(noalias __format: [*c]const u8, __local_argv: __builtin_va_list) c_int;
pub extern fn _filbuf(_File: [*c]FILE) c_int;
pub extern fn _flsbuf(_Ch: c_int, _File: [*c]FILE) c_int;
pub extern fn _fsopen(_Filename: [*c]const u8, _Mode: [*c]const u8, _ShFlag: c_int) [*c]FILE;
pub extern fn clearerr(_File: [*c]FILE) void;
pub extern fn fclose(_File: [*c]FILE) c_int;
pub extern fn _fcloseall() c_int;
pub extern fn _fdopen(_FileHandle: c_int, _Mode: [*c]const u8) [*c]FILE;
pub extern fn feof(_File: [*c]FILE) c_int;
pub extern fn ferror(_File: [*c]FILE) c_int;
pub extern fn fflush(_File: [*c]FILE) c_int;
pub extern fn fgetc(_File: [*c]FILE) c_int;
pub extern fn _fgetchar() c_int;
pub extern fn fgetpos(noalias _File: [*c]FILE, noalias _Pos: [*c]fpos_t) c_int;
pub extern fn fgetpos64(noalias _File: [*c]FILE, noalias _Pos: [*c]fpos_t) c_int;
pub extern fn fgets(noalias _Buf: [*c]u8, _MaxCount: c_int, noalias _File: [*c]FILE) [*c]u8;
pub extern fn _fileno(_File: [*c]FILE) c_int;
pub extern fn _tempnam(_DirName: [*c]const u8, _FilePrefix: [*c]const u8) [*c]u8;
pub extern fn _flushall() c_int;
pub extern fn fopen(_Filename: [*c]const u8, _Mode: [*c]const u8) [*c]FILE;
pub extern fn fopen64(noalias filename: [*c]const u8, noalias mode: [*c]const u8) [*c]FILE;
pub extern fn fputc(_Ch: c_int, _File: [*c]FILE) c_int;
pub extern fn _fputchar(_Ch: c_int) c_int;
pub extern fn fputs(noalias _Str: [*c]const u8, noalias _File: [*c]FILE) c_int;
pub extern fn fread(_DstBuf: ?*anyopaque, _ElementSize: c_ulonglong, _Count: c_ulonglong, _File: [*c]FILE) c_ulonglong;
pub extern fn freopen(noalias _Filename: [*c]const u8, noalias _Mode: [*c]const u8, noalias _File: [*c]FILE) [*c]FILE;
pub extern fn fsetpos(_File: [*c]FILE, _Pos: [*c]const fpos_t) c_int;
pub extern fn fsetpos64(_File: [*c]FILE, _Pos: [*c]const fpos_t) c_int;
pub extern fn fseek(_File: [*c]FILE, _Offset: c_long, _Origin: c_int) c_int;
pub extern fn ftell(_File: [*c]FILE) c_long;
pub extern fn _fseeki64(_File: [*c]FILE, _Offset: c_longlong, _Origin: c_int) c_int;
pub extern fn _ftelli64(_File: [*c]FILE) c_longlong;
pub fn fseeko(arg__File: [*c]FILE, arg__Offset: _off_t, arg__Origin: c_int) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Offset = arg__Offset;
    _ = &_Offset;
    var _Origin = arg__Origin;
    _ = &_Origin;
    return fseek(_File, _Offset, _Origin);
}
pub fn fseeko64(arg__File: [*c]FILE, arg__Offset: _off64_t, arg__Origin: c_int) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Offset = arg__Offset;
    _ = &_Offset;
    var _Origin = arg__Origin;
    _ = &_Origin;
    return _fseeki64(_File, _Offset, _Origin);
}
pub fn ftello(arg__File: [*c]FILE) callconv(.c) _off_t {
    var _File = arg__File;
    _ = &_File;
    return ftell(_File);
}
pub fn ftello64(arg__File: [*c]FILE) callconv(.c) _off64_t {
    var _File = arg__File;
    _ = &_File;
    return _ftelli64(_File);
}
pub extern fn fwrite(_Str: ?*const anyopaque, _Size: c_ulonglong, _Count: c_ulonglong, _File: [*c]FILE) c_ulonglong;
pub extern fn getc(_File: [*c]FILE) c_int;
pub extern fn getchar() c_int;
pub extern fn _getmaxstdio() c_int;
pub extern fn gets(_Buffer: [*c]u8) [*c]u8;
pub extern fn _getw(_File: [*c]FILE) c_int;
pub extern fn _pclose(_File: [*c]FILE) c_int;
pub extern fn _popen(_Command: [*c]const u8, _Mode: [*c]const u8) [*c]FILE;
pub extern fn putc(_Ch: c_int, _File: [*c]FILE) c_int;
pub extern fn putchar(_Ch: c_int) c_int;
pub extern fn puts(_Str: [*c]const u8) c_int;
pub extern fn _putw(_Word: c_int, _File: [*c]FILE) c_int;
pub extern fn remove(_Filename: [*c]const u8) c_int;
pub extern fn rename(_OldFilename: [*c]const u8, _NewFilename: [*c]const u8) c_int;
pub extern fn _unlink(_Filename: [*c]const u8) c_int;
pub extern fn unlink(_Filename: [*c]const u8) c_int;
pub extern fn rewind(_File: [*c]FILE) void;
pub extern fn _rmtmp() c_int;
pub extern fn setbuf(noalias _File: [*c]FILE, noalias _Buffer: [*c]u8) void;
pub extern fn _setmaxstdio(_Max: c_int) c_int;
pub extern fn _set_output_format(_Format: c_uint) c_uint;
pub extern fn _get_output_format() c_uint;
pub extern fn setvbuf(noalias _File: [*c]FILE, noalias _Buf: [*c]u8, _Mode: c_int, _Size: usize) c_int;
pub extern fn _scprintf(noalias _Format: [*c]const u8, ...) c_int;
pub extern fn _snscanf(noalias _Src: [*c]const u8, _MaxCount: usize, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn _vscprintf(noalias _Format: [*c]const u8, _ArgList: va_list) c_int;
pub extern fn tmpfile() [*c]FILE;
pub extern fn tmpnam(_Buffer: [*c]u8) [*c]u8;
pub extern fn ungetc(_Ch: c_int, _File: [*c]FILE) c_int;
pub extern fn _vsnprintf(noalias _Dest: [*c]u8, _Count: usize, noalias _Format: [*c]const u8, _Args: va_list) c_int;
pub extern fn _snprintf(noalias _Dest: [*c]u8, _Count: usize, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn vsnprintf(noalias __stream: [*c]u8, __n: c_ulonglong, noalias __format: [*c]const u8, __local_argv: __builtin_va_list) c_int;
pub extern fn snprintf(noalias __stream: [*c]u8, __n: c_ulonglong, noalias __format: [*c]const u8, ...) c_int;
pub extern fn _set_printf_count_output(_Value: c_int) c_int;
pub extern fn _get_printf_count_output() c_int;
pub extern fn __mingw_swscanf(noalias _Src: [*c]const wchar_t, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_vswscanf(noalias _Str: [*c]const wchar_t, noalias Format: [*c]const wchar_t, argp: va_list) c_int;
pub extern fn __mingw_wscanf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_vwscanf(noalias Format: [*c]const wchar_t, argp: va_list) c_int;
pub extern fn __mingw_fwscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_vfwscanf(noalias fp: [*c]FILE, noalias Format: [*c]const wchar_t, argp: va_list) c_int;
pub extern fn __mingw_fwprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_wprintf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_vfwprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, _ArgList: va_list) c_int;
pub extern fn __mingw_vwprintf(noalias _Format: [*c]const wchar_t, _ArgList: va_list) c_int;
pub extern fn __mingw_snwprintf(noalias s: [*c]wchar_t, n: usize, noalias format: [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_vsnwprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, va_list) c_int;
pub extern fn __mingw_swprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_vswprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, va_list) c_int;
pub extern fn __ms_swscanf(noalias _Src: [*c]const wchar_t, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __ms_vswscanf(noalias _Src: [*c]const wchar_t, noalias _Format: [*c]const wchar_t, va_list) c_int;
pub extern fn __ms_wscanf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __ms_vwscanf(noalias _Format: [*c]const wchar_t, va_list) c_int;
pub extern fn __ms_fwscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __ms_vfwscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, va_list) c_int;
pub extern fn __ms_fwprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __ms_wprintf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __ms_vfwprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, _ArgList: va_list) c_int;
pub extern fn __ms_vwprintf(noalias _Format: [*c]const wchar_t, _ArgList: va_list) c_int;
pub extern fn __ms_swprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, ...) c_int;
pub extern fn __ms_vswprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, va_list) c_int;
pub extern fn __ms_snwprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, ...) c_int;
pub extern fn __ms_vsnwprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, va_list) c_int;
pub extern fn __stdio_common_vswprintf(options: c_ulonglong, str: [*c]wchar_t, len: usize, format: [*c]const wchar_t, locale: _locale_t, valist: va_list) c_int;
pub extern fn __stdio_common_vfwprintf(options: c_ulonglong, file: [*c]FILE, format: [*c]const wchar_t, locale: _locale_t, valist: va_list) c_int;
pub extern fn __stdio_common_vswscanf(options: c_ulonglong, input: [*c]const wchar_t, length: usize, format: [*c]const wchar_t, locale: _locale_t, valist: va_list) c_int;
pub extern fn __stdio_common_vfwscanf(options: c_ulonglong, file: [*c]FILE, format: [*c]const wchar_t, locale: _locale_t, valist: va_list) c_int;
pub extern fn fwscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn swscanf(noalias _Src: [*c]const wchar_t, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn wscanf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn vfwscanf(__stream: [*c]FILE, __format: [*c]const wchar_t, __local_argv: va_list) c_int;
pub extern fn vswscanf(noalias __source: [*c]const wchar_t, noalias __format: [*c]const wchar_t, __local_argv: va_list) c_int;
pub extern fn vwscanf(__format: [*c]const wchar_t, __local_argv: va_list) c_int;
pub extern fn fwprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn wprintf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn vfwprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, _ArgList: va_list) c_int;
pub extern fn vwprintf(noalias _Format: [*c]const wchar_t, _ArgList: va_list) c_int;
pub extern fn _wfsopen(_Filename: [*c]const wchar_t, _Mode: [*c]const wchar_t, _ShFlag: c_int) [*c]FILE;
pub extern fn fgetwc(_File: [*c]FILE) wint_t;
pub extern fn _fgetwchar() wint_t;
pub extern fn fputwc(_Ch: wchar_t, _File: [*c]FILE) wint_t;
pub extern fn _fputwchar(_Ch: wchar_t) wint_t;
pub extern fn getwc(_File: [*c]FILE) wint_t;
pub extern fn getwchar() wint_t;
pub extern fn putwc(_Ch: wchar_t, _File: [*c]FILE) wint_t;
pub extern fn putwchar(_Ch: wchar_t) wint_t;
pub extern fn ungetwc(_Ch: wint_t, _File: [*c]FILE) wint_t;
pub extern fn fgetws(noalias _Dst: [*c]wchar_t, _SizeInWords: c_int, noalias _File: [*c]FILE) [*c]wchar_t;
pub extern fn fputws(noalias _Str: [*c]const wchar_t, noalias _File: [*c]FILE) c_int;
pub extern fn _getws(_String: [*c]wchar_t) [*c]wchar_t;
pub extern fn _putws(_Str: [*c]const wchar_t) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/stdio.h:1169:15: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _scwprintf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn _snwprintf(noalias _Dest: [*c]wchar_t, _Count: usize, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn _vsnwprintf(noalias _Dest: [*c]wchar_t, _Count: usize, noalias _Format: [*c]const wchar_t, _Args: va_list) c_int;
pub extern fn swprintf(noalias _Dest: [*c]wchar_t, _Count: usize, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn vswprintf(noalias _Dest: [*c]wchar_t, _Count: usize, noalias _Format: [*c]const wchar_t, _Args: va_list) c_int;
pub extern fn snwprintf(noalias s: [*c]wchar_t, n: usize, noalias format: [*c]const wchar_t, ...) c_int;
pub extern fn vsnwprintf(noalias s: [*c]wchar_t, n: usize, noalias format: [*c]const wchar_t, arg: va_list) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/stdio.h:1190:15: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _swprintf(noalias _Dest: [*c]wchar_t, noalias _Format: [*c]const wchar_t, ...) c_int;
pub fn _vswprintf(noalias arg__Dest: [*c]wchar_t, noalias arg__Format: [*c]const wchar_t, arg__Args: va_list) callconv(.c) c_int {
    var _Dest = arg__Dest;
    _ = &_Dest;
    var _Format = arg__Format;
    _ = &_Format;
    var _Args = arg__Args;
    _ = &_Args;
    return __stdio_common_vswprintf(__local_stdio_printf_options().*, _Dest, @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1)))), _Format, null, _Args);
}
pub fn _vscwprintf(noalias arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    var _Result: c_int = __stdio_common_vswprintf(__local_stdio_printf_options().* | @as(c_ulonglong, 2), null, @as(usize, @bitCast(@as(c_longlong, @as(c_int, 0)))), _Format, null, _ArgList);
    _ = &_Result;
    return if (_Result < @as(c_int, 0)) -@as(c_int, 1) else _Result;
}
pub extern fn _wtempnam(_Directory: [*c]const wchar_t, _FilePrefix: [*c]const wchar_t) [*c]wchar_t;
pub extern fn _snwscanf(noalias _Src: [*c]const wchar_t, _MaxCount: usize, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn _wfdopen(_FileHandle: c_int, _Mode: [*c]const wchar_t) [*c]FILE;
pub extern fn _wfopen(noalias _Filename: [*c]const wchar_t, noalias _Mode: [*c]const wchar_t) [*c]FILE;
pub extern fn _wfreopen(noalias _Filename: [*c]const wchar_t, noalias _Mode: [*c]const wchar_t, noalias _OldFile: [*c]FILE) [*c]FILE;
pub extern fn _wpopen(_Command: [*c]const wchar_t, _Mode: [*c]const wchar_t) [*c]FILE;
pub extern fn _wremove(_Filename: [*c]const wchar_t) c_int;
pub extern fn _wtmpnam(_Buffer: [*c]wchar_t) [*c]wchar_t;
pub extern fn _fgetwc_nolock(_File: [*c]FILE) wint_t;
pub extern fn _fputwc_nolock(_Ch: wchar_t, _File: [*c]FILE) wint_t;
pub extern fn _ungetwc_nolock(_Ch: wint_t, _File: [*c]FILE) wint_t;
pub extern fn _fgetc_nolock(_File: [*c]FILE) c_int;
pub extern fn _fputc_nolock(_Char: c_int, _File: [*c]FILE) c_int;
pub extern fn _getc_nolock(_File: [*c]FILE) c_int;
pub extern fn _putc_nolock(_Char: c_int, _File: [*c]FILE) c_int;
pub extern fn _lock_file(_File: [*c]FILE) void;
pub extern fn _unlock_file(_File: [*c]FILE) void;
pub extern fn _fclose_nolock(_File: [*c]FILE) c_int;
pub extern fn _fflush_nolock(_File: [*c]FILE) c_int;
pub extern fn _fread_nolock(noalias _DstBuf: ?*anyopaque, _ElementSize: usize, _Count: usize, noalias _File: [*c]FILE) usize;
pub extern fn _fseek_nolock(_File: [*c]FILE, _Offset: c_long, _Origin: c_int) c_int;
pub extern fn _ftell_nolock(_File: [*c]FILE) c_long;
pub extern fn _fseeki64_nolock(_File: [*c]FILE, _Offset: c_longlong, _Origin: c_int) c_int;
pub extern fn _ftelli64_nolock(_File: [*c]FILE) c_longlong;
pub extern fn _fwrite_nolock(noalias _DstBuf: ?*const anyopaque, _Size: usize, _Count: usize, noalias _File: [*c]FILE) usize;
pub extern fn _ungetc_nolock(_Ch: c_int, _File: [*c]FILE) c_int;
pub extern fn tempnam(_Directory: [*c]const u8, _FilePrefix: [*c]const u8) [*c]u8;
pub extern fn fcloseall() c_int;
pub extern fn fdopen(_FileHandle: c_int, _Format: [*c]const u8) [*c]FILE;
pub extern fn fgetchar() c_int;
pub extern fn fileno(_File: [*c]FILE) c_int;
pub extern fn flushall() c_int;
pub extern fn fputchar(_Ch: c_int) c_int;
pub extern fn getw(_File: [*c]FILE) c_int;
pub extern fn putw(_Ch: c_int, _File: [*c]FILE) c_int;
pub extern fn rmtmp() c_int;
pub extern fn __mingw_str_wide_utf8(wptr: [*c]const wchar_t, mbptr: [*c][*c]u8, buflen: [*c]usize) c_int;
pub extern fn __mingw_str_utf8_wide(mbptr: [*c]const u8, wptr: [*c][*c]wchar_t, buflen: [*c]usize) c_int;
pub extern fn __mingw_str_free(ptr: ?*anyopaque) void;
pub extern fn _wspawnl(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const wchar_t, ...) isize;
pub extern fn _wspawnle(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const wchar_t, ...) isize;
pub extern fn _wspawnlp(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const wchar_t, ...) isize;
pub extern fn _wspawnlpe(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const wchar_t, ...) isize;
pub extern fn _wspawnv(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const [*c]const wchar_t) isize;
pub extern fn _wspawnve(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const [*c]const wchar_t, _Env: [*c]const [*c]const wchar_t) isize;
pub extern fn _wspawnvp(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const [*c]const wchar_t) isize;
pub extern fn _wspawnvpe(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const [*c]const wchar_t, _Env: [*c]const [*c]const wchar_t) isize;
pub extern fn _spawnv(_Mode: c_int, _Filename: [*c]const u8, _ArgList: [*c]const [*c]const u8) isize;
pub extern fn _spawnve(_Mode: c_int, _Filename: [*c]const u8, _ArgList: [*c]const [*c]const u8, _Env: [*c]const [*c]const u8) isize;
pub extern fn _spawnvp(_Mode: c_int, _Filename: [*c]const u8, _ArgList: [*c]const [*c]const u8) isize;
pub extern fn _spawnvpe(_Mode: c_int, _Filename: [*c]const u8, _ArgList: [*c]const [*c]const u8, _Env: [*c]const [*c]const u8) isize;
pub extern fn clearerr_s(_File: [*c]FILE) errno_t;
pub extern fn fread_s(_DstBuf: ?*anyopaque, _DstSize: usize, _ElementSize: usize, _Count: usize, _File: [*c]FILE) usize;
pub extern fn __stdio_common_vsprintf_s(_Options: c_ulonglong, _Str: [*c]u8, _Len: usize, _Format: [*c]const u8, _Locale: _locale_t, _ArgList: va_list) c_int;
pub extern fn __stdio_common_vsprintf_p(_Options: c_ulonglong, _Str: [*c]u8, _Len: usize, _Format: [*c]const u8, _Locale: _locale_t, _ArgList: va_list) c_int;
pub extern fn __stdio_common_vsnprintf_s(_Options: c_ulonglong, _Str: [*c]u8, _Len: usize, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, _ArgList: va_list) c_int;
pub extern fn __stdio_common_vfprintf_s(_Options: c_ulonglong, _File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, _ArgList: va_list) c_int;
pub extern fn __stdio_common_vfprintf_p(_Options: c_ulonglong, _File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, _ArgList: va_list) c_int;
pub fn _vfscanf_s_l(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfscanf(@as(c_ulonglong, 1), _File, _Format, _Locale, _ArgList);
}
pub fn vfscanf_s(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfscanf_s_l(_File, _Format, null, _ArgList);
}
pub fn _vscanf_s_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfscanf_s_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 0)))), _Format, _Locale, _ArgList);
}
pub fn vscanf_s(arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfscanf_s_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 0)))), _Format, null, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:60:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fscanf_s_l(_File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:70:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn fscanf_s(_File: [*c]FILE, _Format: [*c]const u8, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:80:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _scanf_s_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:90:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn scanf_s(_Format: [*c]const u8, ...) c_int;
pub fn _vfscanf_l(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfscanf(@as(c_ulonglong, @bitCast(@as(c_longlong, @as(c_int, 0)))), _File, _Format, _Locale, _ArgList);
}
pub fn _vscanf_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfscanf_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 0)))), _Format, _Locale, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:110:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fscanf_l(_File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:119:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _scanf_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
pub fn _vsscanf_s_l(arg__Src: [*c]const u8, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Src = arg__Src;
    _ = &_Src;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsscanf(@as(c_ulonglong, 1), _Src, @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1)))), _Format, _Locale, _ArgList);
}
pub fn vsscanf_s(arg__Src: [*c]const u8, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _Src = arg__Src;
    _ = &_Src;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsscanf_s_l(_Src, _Format, null, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:137:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _sscanf_s_l(_Src: [*c]const u8, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:146:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn sscanf_s(_Src: [*c]const u8, _Format: [*c]const u8, ...) c_int;
pub fn _vsscanf_l(arg__Src: [*c]const u8, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Src = arg__Src;
    _ = &_Src;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsscanf(@as(c_ulonglong, @bitCast(@as(c_longlong, @as(c_int, 0)))), _Src, @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1)))), _Format, _Locale, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:160:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _sscanf_l(_Src: [*c]const u8, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:171:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snscanf_s_l(_Src: [*c]const u8, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:180:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snscanf_s(_Src: [*c]const u8, _MaxCount: usize, _Format: [*c]const u8, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:191:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snscanf_l(_Src: [*c]const u8, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
pub fn _vfprintf_s_l(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfprintf_s(__local_stdio_printf_options().*, _File, _Format, _Locale, _ArgList);
}
pub fn vfprintf_s(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_s_l(_File, _Format, null, _ArgList);
}
pub fn _vprintf_s_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_s_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 1)))), _Format, _Locale, _ArgList);
}
pub fn vprintf_s(arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_s_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 1)))), _Format, null, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:218:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fprintf_s_l(_File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:227:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _printf_s_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:236:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn fprintf_s(_File: [*c]FILE, _Format: [*c]const u8, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:245:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn printf_s(_Format: [*c]const u8, ...) c_int;
pub fn _vsnprintf_c_l(arg__DstBuf: [*c]u8, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsprintf(__local_stdio_printf_options().*, _DstBuf, _MaxCount, _Format, _Locale, _ArgList);
}
pub fn _vsnprintf_c(arg__DstBuf: [*c]u8, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsnprintf_c_l(_DstBuf, _MaxCount, _Format, null, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:263:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snprintf_c_l(_DstBuf: [*c]u8, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:272:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snprintf_c(_DstBuf: [*c]u8, _MaxCount: usize, _Format: [*c]const u8, ...) c_int;
pub fn _vsnprintf_s_l(arg__DstBuf: [*c]u8, arg__DstSize: usize, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsnprintf_s(__local_stdio_printf_options().*, _DstBuf, _DstSize, _MaxCount, _Format, _Locale, _ArgList);
}
pub fn vsnprintf_s(arg__DstBuf: [*c]u8, arg__DstSize: usize, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsnprintf_s_l(_DstBuf, _DstSize, _MaxCount, _Format, null, _ArgList);
}
pub fn _vsnprintf_s(arg__DstBuf: [*c]u8, arg__DstSize: usize, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsnprintf_s_l(_DstBuf, _DstSize, _MaxCount, _Format, null, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:294:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snprintf_s_l(_DstBuf: [*c]u8, _DstSize: usize, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:303:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snprintf_s(_DstBuf: [*c]u8, _DstSize: usize, _MaxCount: usize, _Format: [*c]const u8, ...) c_int;
pub fn _vsprintf_s_l(arg__DstBuf: [*c]u8, arg__DstSize: usize, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsprintf_s(__local_stdio_printf_options().*, _DstBuf, _DstSize, _Format, _Locale, _ArgList);
}
pub fn vsprintf_s(arg__DstBuf: [*c]u8, arg__Size: usize, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _Size = arg__Size;
    _ = &_Size;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsprintf_s_l(_DstBuf, _Size, _Format, null, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:321:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _sprintf_s_l(_DstBuf: [*c]u8, _DstSize: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:330:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn sprintf_s(_DstBuf: [*c]u8, _DstSize: usize, _Format: [*c]const u8, ...) c_int;
pub fn _vfprintf_p_l(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfprintf_p(__local_stdio_printf_options().*, _File, _Format, _Locale, _ArgList);
}
pub fn _vfprintf_p(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_p_l(_File, _Format, null, _ArgList);
}
pub fn _vprintf_p_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_p_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 1)))), _Format, _Locale, _ArgList);
}
pub fn _vprintf_p(arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_p_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 1)))), _Format, null, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:356:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fprintf_p_l(_File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:365:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fprintf_p(_File: [*c]FILE, _Format: [*c]const u8, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:374:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _printf_p_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:383:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _printf_p(_Format: [*c]const u8, ...) c_int;
pub fn _vsprintf_p_l(arg__DstBuf: [*c]u8, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsprintf_p(__local_stdio_printf_options().*, _DstBuf, _MaxCount, _Format, _Locale, _ArgList);
}
pub fn _vsprintf_p(arg__Dst: [*c]u8, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _Dst = arg__Dst;
    _ = &_Dst;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsprintf_p_l(_Dst, _MaxCount, _Format, null, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:401:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _sprintf_p_l(_DstBuf: [*c]u8, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:410:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _sprintf_p(_Dst: [*c]u8, _MaxCount: usize, _Format: [*c]const u8, ...) c_int;
pub fn _vscprintf_p_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsprintf_p(@as(c_ulonglong, 2), null, @as(usize, @bitCast(@as(c_longlong, @as(c_int, 0)))), _Format, _Locale, _ArgList);
}
pub fn _vscprintf_p(arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vscprintf_p_l(_Format, null, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:428:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _scprintf_p_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:437:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _scprintf_p(_Format: [*c]const u8, ...) c_int;
pub fn _vfprintf_l(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfprintf(__local_stdio_printf_options().*, _File, _Format, _Locale, _ArgList);
}
pub fn _vprintf_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 1)))), _Format, _Locale, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:455:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fprintf_l(_File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:464:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _printf_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
pub fn _vsnprintf_l(arg__DstBuf: [*c]u8, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsprintf(@as(c_ulonglong, 1), _DstBuf, _MaxCount, _Format, _Locale, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:478:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snprintf_l(_DstBuf: [*c]u8, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
pub fn _vsprintf_l(arg__DstBuf: [*c]u8, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsnprintf_l(_DstBuf, @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1)))), _Format, _Locale, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:491:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _sprintf_l(_DstBuf: [*c]u8, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
pub fn _vscprintf_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsprintf(@as(c_ulonglong, 2), null, @as(usize, @bitCast(@as(c_longlong, @as(c_int, 0)))), _Format, _Locale, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:505:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _scprintf_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
pub extern fn fopen_s(_File: [*c][*c]FILE, _Filename: [*c]const u8, _Mode: [*c]const u8) errno_t;
pub extern fn freopen_s(_File: [*c][*c]FILE, _Filename: [*c]const u8, _Mode: [*c]const u8, _Stream: [*c]FILE) errno_t;
pub extern fn gets_s([*c]u8, rsize_t) [*c]u8;
pub extern fn tmpfile_s(_File: [*c][*c]FILE) errno_t;
pub extern fn tmpnam_s([*c]u8, rsize_t) errno_t;
pub extern fn _getws_s(_Str: [*c]wchar_t, _SizeInWords: usize) [*c]wchar_t;
pub extern fn __stdio_common_vswprintf_s(_Options: c_ulonglong, _Str: [*c]wchar_t, _Len: usize, _Format: [*c]const wchar_t, _Locale: _locale_t, _ArgList: va_list) c_int;
pub extern fn __stdio_common_vsnwprintf_s(_Options: c_ulonglong, _Str: [*c]wchar_t, _Len: usize, _MaxCount: usize, _Format: [*c]const wchar_t, _Locale: _locale_t, _ArgList: va_list) c_int;
pub extern fn __stdio_common_vfwprintf_s(_Options: c_ulonglong, _File: [*c]FILE, _Format: [*c]const wchar_t, _Locale: _locale_t, _ArgList: va_list) c_int;
pub fn _vfwscanf_s_l(arg__File: [*c]FILE, arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfwscanf(__local_stdio_scanf_options().* | @as(c_ulonglong, 1), _File, _Format, _Locale, _ArgList);
}
pub fn vfwscanf_s(arg__File: [*c]FILE, arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfwscanf_s_l(_File, _Format, null, _ArgList);
}
pub fn _vwscanf_s_l(arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfwscanf_s_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 0)))), _Format, _Locale, _ArgList);
}
pub fn vwscanf_s(arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfwscanf_s_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 0)))), _Format, null, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:631:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fwscanf_s_l(_File: [*c]FILE, _Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:641:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn fwscanf_s(_File: [*c]FILE, _Format: [*c]const wchar_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:651:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _wscanf_s_l(_Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:661:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn wscanf_s(_Format: [*c]const wchar_t, ...) c_int;
pub fn _vswscanf_s_l(arg__Src: [*c]const wchar_t, arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Src = arg__Src;
    _ = &_Src;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vswscanf(__local_stdio_scanf_options().* | @as(c_ulonglong, 1), _Src, @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1)))), _Format, _Locale, _ArgList);
}
pub fn vswscanf_s(arg__Src: [*c]const wchar_t, arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Src = arg__Src;
    _ = &_Src;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vswscanf_s_l(_Src, _Format, null, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:681:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _swscanf_s_l(_Src: [*c]const wchar_t, _Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:690:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn swscanf_s(_Src: [*c]const wchar_t, _Format: [*c]const wchar_t, ...) c_int;
pub fn _vsnwscanf_s_l(arg__Src: [*c]const wchar_t, arg__MaxCount: usize, arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Src = arg__Src;
    _ = &_Src;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vswscanf(__local_stdio_scanf_options().* | @as(c_ulonglong, 1), _Src, _MaxCount, _Format, _Locale, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:704:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snwscanf_s_l(_Src: [*c]const wchar_t, _MaxCount: usize, _Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:713:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snwscanf_s(_Src: [*c]const wchar_t, _MaxCount: usize, _Format: [*c]const wchar_t, ...) c_int;
pub fn _vfwprintf_s_l(arg__File: [*c]FILE, arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfwprintf_s(__local_stdio_printf_options().*, _File, _Format, _Locale, _ArgList);
}
pub fn _vwprintf_s_l(arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfwprintf_s_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 1)))), _Format, _Locale, _ArgList);
}
pub fn vfwprintf_s(arg__File: [*c]FILE, arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfwprintf_s_l(_File, _Format, null, _ArgList);
}
pub fn vwprintf_s(arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfwprintf_s_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 1)))), _Format, null, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:739:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fwprintf_s_l(_File: [*c]FILE, _Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:748:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _wprintf_s_l(_Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:757:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn fwprintf_s(_File: [*c]FILE, _Format: [*c]const wchar_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:766:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn wprintf_s(_Format: [*c]const wchar_t, ...) c_int;
pub fn _vswprintf_s_l(arg__DstBuf: [*c]wchar_t, arg__DstSize: usize, arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vswprintf_s(__local_stdio_printf_options().*, _DstBuf, _DstSize, _Format, _Locale, _ArgList);
}
pub fn vswprintf_s(arg__DstBuf: [*c]wchar_t, arg__DstSize: usize, arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vswprintf_s_l(_DstBuf, _DstSize, _Format, null, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:784:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _swprintf_s_l(_DstBuf: [*c]wchar_t, _DstSize: usize, _Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:793:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn swprintf_s(_DstBuf: [*c]wchar_t, _DstSize: usize, _Format: [*c]const wchar_t, ...) c_int;
pub fn _vsnwprintf_s_l(arg__DstBuf: [*c]wchar_t, arg__DstSize: usize, arg__MaxCount: usize, arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsnwprintf_s(__local_stdio_printf_options().*, _DstBuf, _DstSize, _MaxCount, _Format, _Locale, _ArgList);
}
pub fn _vsnwprintf_s(arg__DstBuf: [*c]wchar_t, arg__DstSize: usize, arg__MaxCount: usize, arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsnwprintf_s_l(_DstBuf, _DstSize, _MaxCount, _Format, null, _ArgList);
}
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:811:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snwprintf_s_l(_DstBuf: [*c]wchar_t, _DstSize: usize, _MaxCount: usize, _Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int;
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/sec_api/stdio_s.h:820:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snwprintf_s(_DstBuf: [*c]wchar_t, _DstSize: usize, _MaxCount: usize, _Format: [*c]const wchar_t, ...) c_int;
pub extern fn _wfopen_s(_File: [*c][*c]FILE, _Filename: [*c]const wchar_t, _Mode: [*c]const wchar_t) errno_t;
pub extern fn _wfreopen_s(_File: [*c][*c]FILE, _Filename: [*c]const wchar_t, _Mode: [*c]const wchar_t, _OldFile: [*c]FILE) errno_t;
pub extern fn _wtmpnam_s(_DstBuf: [*c]wchar_t, _SizeInWords: usize) errno_t;
pub extern fn _fread_nolock_s(_DstBuf: ?*anyopaque, _DstSize: usize, _ElementSize: usize, _Count: usize, _File: [*c]FILE) usize;
pub extern fn _memccpy(_Dst: ?*anyopaque, _Src: ?*const anyopaque, _Val: c_int, _MaxCount: usize) ?*anyopaque;
pub extern fn memchr(_Buf: ?*const anyopaque, _Val: c_int, _MaxCount: c_ulonglong) ?*anyopaque;
pub extern fn _memicmp(_Buf1: ?*const anyopaque, _Buf2: ?*const anyopaque, _Size: usize) c_int;
pub extern fn _memicmp_l(_Buf1: ?*const anyopaque, _Buf2: ?*const anyopaque, _Size: usize, _Locale: _locale_t) c_int;
pub extern fn memcmp(_Buf1: ?*const anyopaque, _Buf2: ?*const anyopaque, _Size: c_ulonglong) c_int;
pub extern fn memcpy(_Dst: ?*anyopaque, _Src: ?*const anyopaque, _Size: c_ulonglong) ?*anyopaque;
pub extern fn memcpy_s(_dest: ?*anyopaque, _numberOfElements: usize, _src: ?*const anyopaque, _count: usize) errno_t;
pub extern fn mempcpy(_Dst: ?*anyopaque, _Src: ?*const anyopaque, _Size: c_ulonglong) ?*anyopaque;
pub extern fn memset(_Dst: ?*anyopaque, _Val: c_int, _Size: c_ulonglong) ?*anyopaque;
pub extern fn memccpy(_Dst: ?*anyopaque, _Src: ?*const anyopaque, _Val: c_int, _Size: c_ulonglong) ?*anyopaque;
pub extern fn memicmp(_Buf1: ?*const anyopaque, _Buf2: ?*const anyopaque, _Size: usize) c_int;
pub extern fn _strset(_Str: [*c]u8, _Val: c_int) [*c]u8;
pub extern fn _strset_l(_Str: [*c]u8, _Val: c_int, _Locale: _locale_t) [*c]u8;
pub extern fn strcpy(_Dest: [*c]u8, _Source: [*c]const u8) [*c]u8;
pub extern fn strcat(_Dest: [*c]u8, _Source: [*c]const u8) [*c]u8;
pub extern fn strcmp(_Str1: [*c]const u8, _Str2: [*c]const u8) c_int;
pub extern fn strlen(_Str: [*c]const u8) c_ulonglong;
pub extern fn strnlen(_Str: [*c]const u8, _MaxCount: usize) usize;
pub extern fn memmove(_Dst: ?*anyopaque, _Src: ?*const anyopaque, _Size: c_ulonglong) ?*anyopaque;
pub extern fn _strdup(_Src: [*c]const u8) [*c]u8;
pub extern fn strchr(_Str: [*c]const u8, _Val: c_int) [*c]u8;
pub extern fn _stricmp(_Str1: [*c]const u8, _Str2: [*c]const u8) c_int;
pub extern fn _strcmpi(_Str1: [*c]const u8, _Str2: [*c]const u8) c_int;
pub extern fn _stricmp_l(_Str1: [*c]const u8, _Str2: [*c]const u8, _Locale: _locale_t) c_int;
pub extern fn strcoll(_Str1: [*c]const u8, _Str2: [*c]const u8) c_int;
pub extern fn _strcoll_l(_Str1: [*c]const u8, _Str2: [*c]const u8, _Locale: _locale_t) c_int;
pub extern fn _stricoll(_Str1: [*c]const u8, _Str2: [*c]const u8) c_int;
pub extern fn _stricoll_l(_Str1: [*c]const u8, _Str2: [*c]const u8, _Locale: _locale_t) c_int;
pub extern fn _strncoll(_Str1: [*c]const u8, _Str2: [*c]const u8, _MaxCount: usize) c_int;
pub extern fn _strncoll_l(_Str1: [*c]const u8, _Str2: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) c_int;
pub extern fn _strnicoll(_Str1: [*c]const u8, _Str2: [*c]const u8, _MaxCount: usize) c_int;
pub extern fn _strnicoll_l(_Str1: [*c]const u8, _Str2: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) c_int;
pub extern fn strcspn(_Str: [*c]const u8, _Control: [*c]const u8) c_ulonglong;
pub extern fn _strerror(_ErrMsg: [*c]const u8) [*c]u8;
pub extern fn strerror(c_int) [*c]u8;
pub extern fn _strlwr(_String: [*c]u8) [*c]u8;
pub extern fn strlwr_l(_String: [*c]u8, _Locale: _locale_t) [*c]u8;
pub extern fn strncat(_Dest: [*c]u8, _Source: [*c]const u8, _Count: c_ulonglong) [*c]u8;
pub extern fn strncmp(_Str1: [*c]const u8, _Str2: [*c]const u8, _MaxCount: c_ulonglong) c_int;
pub extern fn _strnicmp(_Str1: [*c]const u8, _Str2: [*c]const u8, _MaxCount: usize) c_int;
pub extern fn _strnicmp_l(_Str1: [*c]const u8, _Str2: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) c_int;
pub extern fn strncpy(_Dest: [*c]u8, _Source: [*c]const u8, _Count: c_ulonglong) [*c]u8;
pub extern fn _strnset(_Str: [*c]u8, _Val: c_int, _MaxCount: usize) [*c]u8;
pub extern fn _strnset_l(str: [*c]u8, c: c_int, count: usize, _Locale: _locale_t) [*c]u8;
pub extern fn strpbrk(_Str: [*c]const u8, _Control: [*c]const u8) [*c]u8;
pub extern fn strrchr(_Str: [*c]const u8, _Ch: c_int) [*c]u8;
pub extern fn _strrev(_Str: [*c]u8) [*c]u8;
pub extern fn strspn(_Str: [*c]const u8, _Control: [*c]const u8) c_ulonglong;
pub extern fn strstr(_Str: [*c]const u8, _SubStr: [*c]const u8) [*c]u8;
pub extern fn strtok(_Str: [*c]u8, _Delim: [*c]const u8) [*c]u8;
pub extern fn strtok_r(noalias _Str: [*c]u8, noalias _Delim: [*c]const u8, noalias __last: [*c][*c]u8) [*c]u8;
pub extern fn _strupr(_String: [*c]u8) [*c]u8;
pub extern fn _strupr_l(_String: [*c]u8, _Locale: _locale_t) [*c]u8;
pub extern fn strxfrm(_Dst: [*c]u8, _Src: [*c]const u8, _MaxCount: c_ulonglong) c_ulonglong;
pub extern fn _strxfrm_l(noalias _Dst: [*c]u8, noalias _Src: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) usize;
pub extern fn strdup(_Src: [*c]const u8) [*c]u8;
pub extern fn strcmpi(_Str1: [*c]const u8, _Str2: [*c]const u8) c_int;
pub extern fn stricmp(_Str1: [*c]const u8, _Str2: [*c]const u8) c_int;
pub extern fn strlwr(_Str: [*c]u8) [*c]u8;
pub extern fn strnicmp(_Str1: [*c]const u8, _Str: [*c]const u8, _MaxCount: usize) c_int;
pub extern fn strncasecmp([*c]const u8, [*c]const u8, c_ulonglong) c_int;
pub extern fn strcasecmp([*c]const u8, [*c]const u8) c_int;
pub extern fn strnset(_Str: [*c]u8, _Val: c_int, _MaxCount: usize) [*c]u8;
pub extern fn strrev(_Str: [*c]u8) [*c]u8;
pub extern fn strset(_Str: [*c]u8, _Val: c_int) [*c]u8;
pub extern fn strupr(_Str: [*c]u8) [*c]u8;
pub extern fn _wcsdup(_Str: [*c]const wchar_t) [*c]wchar_t;
pub extern fn wcscat(noalias _Dest: [*c]wchar_t, noalias _Source: [*c]const wchar_t) [*c]wchar_t;
pub extern fn wcschr(_Str: [*c]const c_ushort, _Ch: c_ushort) [*c]c_ushort;
pub extern fn wcscmp(_Str1: [*c]const c_ushort, _Str2: [*c]const c_ushort) c_int;
pub extern fn wcscpy(noalias _Dest: [*c]wchar_t, noalias _Source: [*c]const wchar_t) [*c]wchar_t;
pub extern fn wcscspn(_Str: [*c]const wchar_t, _Control: [*c]const wchar_t) usize;
pub extern fn wcslen(_Str: [*c]const c_ushort) c_ulonglong;
pub extern fn wcsnlen(_Src: [*c]const wchar_t, _MaxCount: usize) usize;
pub extern fn wcsncat(noalias _Dest: [*c]wchar_t, noalias _Source: [*c]const wchar_t, _Count: usize) [*c]wchar_t;
pub extern fn wcsncmp(_Str1: [*c]const c_ushort, _Str2: [*c]const c_ushort, _MaxCount: c_ulonglong) c_int;
pub extern fn wcsncpy(noalias _Dest: [*c]wchar_t, noalias _Source: [*c]const wchar_t, _Count: usize) [*c]wchar_t;
pub extern fn _wcsncpy_l(noalias _Dest: [*c]wchar_t, noalias _Source: [*c]const wchar_t, _Count: usize, _Locale: _locale_t) [*c]wchar_t;
pub extern fn wcspbrk(_Str: [*c]const wchar_t, _Control: [*c]const wchar_t) [*c]wchar_t;
pub extern fn wcsrchr(_Str: [*c]const wchar_t, _Ch: wchar_t) [*c]wchar_t;
pub extern fn wcsspn(_Str: [*c]const wchar_t, _Control: [*c]const wchar_t) usize;
pub extern fn wcsstr(_Str: [*c]const wchar_t, _SubStr: [*c]const wchar_t) [*c]wchar_t;
pub extern fn wcstok(noalias _Str: [*c]wchar_t, noalias _Delim: [*c]const wchar_t, noalias _Ptr: [*c][*c]wchar_t) [*c]wchar_t;
pub extern fn _wcstok(noalias _Str: [*c]wchar_t, noalias _Delim: [*c]const wchar_t) [*c]wchar_t;
pub extern fn _wcserror(_ErrNum: c_int) [*c]wchar_t;
pub extern fn __wcserror(_Str: [*c]const wchar_t) [*c]wchar_t;
pub extern fn _wcsicmp(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t) c_int;
pub extern fn _wcsicmp_l(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _Locale: _locale_t) c_int;
pub extern fn _wcsnicmp(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _MaxCount: usize) c_int;
pub extern fn _wcsnicmp_l(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _MaxCount: usize, _Locale: _locale_t) c_int;
pub extern fn _wcsnset(_Str: [*c]wchar_t, _Val: wchar_t, _MaxCount: usize) [*c]wchar_t;
pub extern fn _wcsrev(_Str: [*c]wchar_t) [*c]wchar_t;
pub extern fn _wcsset(_Str: [*c]wchar_t, _Val: wchar_t) [*c]wchar_t;
pub extern fn _wcslwr(_String: [*c]wchar_t) [*c]wchar_t;
pub extern fn _wcslwr_l(_String: [*c]wchar_t, _Locale: _locale_t) [*c]wchar_t;
pub extern fn _wcsupr(_String: [*c]wchar_t) [*c]wchar_t;
pub extern fn _wcsupr_l(_String: [*c]wchar_t, _Locale: _locale_t) [*c]wchar_t;
pub extern fn wcsxfrm(noalias _Dst: [*c]wchar_t, noalias _Src: [*c]const wchar_t, _MaxCount: usize) usize;
pub extern fn _wcsxfrm_l(noalias _Dst: [*c]wchar_t, noalias _Src: [*c]const wchar_t, _MaxCount: usize, _Locale: _locale_t) usize;
pub extern fn wcscoll(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t) c_int;
pub extern fn _wcscoll_l(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _Locale: _locale_t) c_int;
pub extern fn _wcsicoll(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t) c_int;
pub extern fn _wcsicoll_l(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _Locale: _locale_t) c_int;
pub extern fn _wcsncoll(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _MaxCount: usize) c_int;
pub extern fn _wcsncoll_l(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _MaxCount: usize, _Locale: _locale_t) c_int;
pub extern fn _wcsnicoll(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _MaxCount: usize) c_int;
pub extern fn _wcsnicoll_l(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _MaxCount: usize, _Locale: _locale_t) c_int;
pub extern fn wcsdup(_Str: [*c]const wchar_t) [*c]wchar_t;
pub extern fn wcsicmp(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t) c_int;
pub extern fn wcsnicmp(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _MaxCount: usize) c_int;
pub extern fn wcsnset(_Str: [*c]wchar_t, _Val: wchar_t, _MaxCount: usize) [*c]wchar_t;
pub extern fn wcsrev(_Str: [*c]wchar_t) [*c]wchar_t;
pub extern fn wcsset(_Str: [*c]wchar_t, _Val: wchar_t) [*c]wchar_t;
pub extern fn wcslwr(_Str: [*c]wchar_t) [*c]wchar_t;
pub extern fn wcsupr(_Str: [*c]wchar_t) [*c]wchar_t;
pub extern fn wcsicoll(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t) c_int;
pub extern fn _strset_s(_Dst: [*c]u8, _DstSize: usize, _Value: c_int) errno_t;
pub extern fn _strerror_s(_Buf: [*c]u8, _SizeInBytes: usize, _ErrMsg: [*c]const u8) errno_t;
pub extern fn strerror_s(_Buf: [*c]u8, _SizeInBytes: usize, _ErrNum: c_int) errno_t;
pub extern fn _strlwr_s(_Str: [*c]u8, _Size: usize) errno_t;
pub extern fn _strlwr_s_l(_Str: [*c]u8, _Size: usize, _Locale: _locale_t) errno_t;
pub extern fn _strnset_s(_Str: [*c]u8, _Size: usize, _Val: c_int, _MaxCount: usize) errno_t;
pub extern fn _strupr_s(_Str: [*c]u8, _Size: usize) errno_t;
pub extern fn _strupr_s_l(_Str: [*c]u8, _Size: usize, _Locale: _locale_t) errno_t;
pub extern fn strncat_s(_Dst: [*c]u8, _DstSizeInChars: usize, _Src: [*c]const u8, _MaxCount: usize) errno_t;
pub extern fn _strncat_s_l(_Dst: [*c]u8, _DstSizeInChars: usize, _Src: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) errno_t;
pub extern fn strcpy_s(_Dst: [*c]u8, _SizeInBytes: rsize_t, _Src: [*c]const u8) errno_t;
pub extern fn strncpy_s(_Dst: [*c]u8, _DstSizeInChars: usize, _Src: [*c]const u8, _MaxCount: usize) errno_t;
pub extern fn _strncpy_s_l(_Dst: [*c]u8, _DstSizeInChars: usize, _Src: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) errno_t;
pub extern fn strtok_s(_Str: [*c]u8, _Delim: [*c]const u8, _Context: [*c][*c]u8) [*c]u8;
pub extern fn _strtok_s_l(_Str: [*c]u8, _Delim: [*c]const u8, _Context: [*c][*c]u8, _Locale: _locale_t) [*c]u8;
pub extern fn strcat_s(_Dst: [*c]u8, _SizeInBytes: rsize_t, _Src: [*c]const u8) errno_t;
pub inline fn strnlen_s(arg__src: [*c]const u8, arg__count: usize) usize {
    var _src = arg__src;
    _ = &_src;
    var _count = arg__count;
    _ = &_count;
    return if (_src != null) strnlen(_src, _count) else @as(usize, @bitCast(@as(c_longlong, @as(c_int, 0))));
}
pub extern fn memmove_s(_dest: ?*anyopaque, _numberOfElements: usize, _src: ?*const anyopaque, _count: usize) errno_t;
pub extern fn wcstok_s(_Str: [*c]wchar_t, _Delim: [*c]const wchar_t, _Context: [*c][*c]wchar_t) [*c]wchar_t;
pub extern fn _wcserror_s(_Buf: [*c]wchar_t, _SizeInWords: usize, _ErrNum: c_int) errno_t;
pub extern fn __wcserror_s(_Buffer: [*c]wchar_t, _SizeInWords: usize, _ErrMsg: [*c]const wchar_t) errno_t;
pub extern fn _wcsnset_s(_Dst: [*c]wchar_t, _DstSizeInWords: usize, _Val: wchar_t, _MaxCount: usize) errno_t;
pub extern fn _wcsset_s(_Str: [*c]wchar_t, _SizeInWords: usize, _Val: wchar_t) errno_t;
pub extern fn _wcslwr_s(_Str: [*c]wchar_t, _SizeInWords: usize) errno_t;
pub extern fn _wcslwr_s_l(_Str: [*c]wchar_t, _SizeInWords: usize, _Locale: _locale_t) errno_t;
pub extern fn _wcsupr_s(_Str: [*c]wchar_t, _Size: usize) errno_t;
pub extern fn _wcsupr_s_l(_Str: [*c]wchar_t, _Size: usize, _Locale: _locale_t) errno_t;
pub extern fn wcscpy_s(_Dst: [*c]wchar_t, _SizeInWords: rsize_t, _Src: [*c]const wchar_t) errno_t;
pub extern fn wcscat_s(_Dst: [*c]wchar_t, _SizeInWords: rsize_t, _Src: [*c]const wchar_t) errno_t;
pub extern fn wcsncat_s(_Dst: [*c]wchar_t, _DstSizeInChars: usize, _Src: [*c]const wchar_t, _MaxCount: usize) errno_t;
pub extern fn _wcsncat_s_l(_Dst: [*c]wchar_t, _DstSizeInChars: usize, _Src: [*c]const wchar_t, _MaxCount: usize, _Locale: _locale_t) errno_t;
pub extern fn wcsncpy_s(_Dst: [*c]wchar_t, _DstSizeInChars: usize, _Src: [*c]const wchar_t, _MaxCount: usize) errno_t;
pub extern fn _wcsncpy_s_l(_Dst: [*c]wchar_t, _DstSizeInChars: usize, _Src: [*c]const wchar_t, _MaxCount: usize, _Locale: _locale_t) errno_t;
pub extern fn _wcstok_s_l(_Str: [*c]wchar_t, _Delim: [*c]const wchar_t, _Context: [*c][*c]wchar_t, _Locale: _locale_t) [*c]wchar_t;
pub extern fn _wcsset_s_l(_Str: [*c]wchar_t, _SizeInChars: usize, _Val: wchar_t, _Locale: _locale_t) errno_t;
pub extern fn _wcsnset_s_l(_Str: [*c]wchar_t, _SizeInChars: usize, _Val: wchar_t, _Count: usize, _Locale: _locale_t) errno_t;
pub inline fn wcsnlen_s(arg__src: [*c]const wchar_t, arg__count: usize) usize {
    var _src = arg__src;
    _ = &_src;
    var _count = arg__count;
    _ = &_count;
    return if (_src != null) wcsnlen(_src, _count) else @as(usize, @bitCast(@as(c_longlong, @as(c_int, 0))));
}
pub extern fn yaml_get_version_string() [*c]const u8;
pub extern fn yaml_get_version(major: [*c]c_int, minor: [*c]c_int, patch: [*c]c_int) void;
pub const yaml_char_t = u8;
pub const struct_yaml_version_directive_s = extern struct {
    major: c_int = @import("std").mem.zeroes(c_int),
    minor: c_int = @import("std").mem.zeroes(c_int),
};
pub const yaml_version_directive_t = struct_yaml_version_directive_s;
pub const struct_yaml_tag_directive_s = extern struct {
    handle: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    prefix: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
};
pub const yaml_tag_directive_t = struct_yaml_tag_directive_s;
pub const YAML_ANY_ENCODING: c_int = 0;
pub const YAML_UTF8_ENCODING: c_int = 1;
pub const YAML_UTF16LE_ENCODING: c_int = 2;
pub const YAML_UTF16BE_ENCODING: c_int = 3;
pub const enum_yaml_encoding_e = c_uint;
pub const yaml_encoding_t = enum_yaml_encoding_e;
pub const YAML_ANY_BREAK: c_int = 0;
pub const YAML_CR_BREAK: c_int = 1;
pub const YAML_LN_BREAK: c_int = 2;
pub const YAML_CRLN_BREAK: c_int = 3;
pub const enum_yaml_break_e = c_uint;
pub const yaml_break_t = enum_yaml_break_e;
pub const YAML_NO_ERROR: c_int = 0;
pub const YAML_MEMORY_ERROR: c_int = 1;
pub const YAML_READER_ERROR: c_int = 2;
pub const YAML_SCANNER_ERROR: c_int = 3;
pub const YAML_PARSER_ERROR: c_int = 4;
pub const YAML_COMPOSER_ERROR: c_int = 5;
pub const YAML_WRITER_ERROR: c_int = 6;
pub const YAML_EMITTER_ERROR: c_int = 7;
pub const enum_yaml_error_type_e = c_uint;
pub const yaml_error_type_t = enum_yaml_error_type_e;
pub const struct_yaml_mark_s = extern struct {
    index: usize = @import("std").mem.zeroes(usize),
    line: usize = @import("std").mem.zeroes(usize),
    column: usize = @import("std").mem.zeroes(usize),
};
pub const yaml_mark_t = struct_yaml_mark_s;
pub const YAML_ANY_SCALAR_STYLE: c_int = 0;
pub const YAML_PLAIN_SCALAR_STYLE: c_int = 1;
pub const YAML_SINGLE_QUOTED_SCALAR_STYLE: c_int = 2;
pub const YAML_DOUBLE_QUOTED_SCALAR_STYLE: c_int = 3;
pub const YAML_LITERAL_SCALAR_STYLE: c_int = 4;
pub const YAML_FOLDED_SCALAR_STYLE: c_int = 5;
pub const enum_yaml_scalar_style_e = c_uint;
pub const yaml_scalar_style_t = enum_yaml_scalar_style_e;
pub const YAML_ANY_SEQUENCE_STYLE: c_int = 0;
pub const YAML_BLOCK_SEQUENCE_STYLE: c_int = 1;
pub const YAML_FLOW_SEQUENCE_STYLE: c_int = 2;
pub const enum_yaml_sequence_style_e = c_uint;
pub const yaml_sequence_style_t = enum_yaml_sequence_style_e;
pub const YAML_ANY_MAPPING_STYLE: c_int = 0;
pub const YAML_BLOCK_MAPPING_STYLE: c_int = 1;
pub const YAML_FLOW_MAPPING_STYLE: c_int = 2;
pub const enum_yaml_mapping_style_e = c_uint;
pub const yaml_mapping_style_t = enum_yaml_mapping_style_e;
pub const YAML_NO_TOKEN: c_int = 0;
pub const YAML_STREAM_START_TOKEN: c_int = 1;
pub const YAML_STREAM_END_TOKEN: c_int = 2;
pub const YAML_VERSION_DIRECTIVE_TOKEN: c_int = 3;
pub const YAML_TAG_DIRECTIVE_TOKEN: c_int = 4;
pub const YAML_DOCUMENT_START_TOKEN: c_int = 5;
pub const YAML_DOCUMENT_END_TOKEN: c_int = 6;
pub const YAML_BLOCK_SEQUENCE_START_TOKEN: c_int = 7;
pub const YAML_BLOCK_MAPPING_START_TOKEN: c_int = 8;
pub const YAML_BLOCK_END_TOKEN: c_int = 9;
pub const YAML_FLOW_SEQUENCE_START_TOKEN: c_int = 10;
pub const YAML_FLOW_SEQUENCE_END_TOKEN: c_int = 11;
pub const YAML_FLOW_MAPPING_START_TOKEN: c_int = 12;
pub const YAML_FLOW_MAPPING_END_TOKEN: c_int = 13;
pub const YAML_BLOCK_ENTRY_TOKEN: c_int = 14;
pub const YAML_FLOW_ENTRY_TOKEN: c_int = 15;
pub const YAML_KEY_TOKEN: c_int = 16;
pub const YAML_VALUE_TOKEN: c_int = 17;
pub const YAML_ALIAS_TOKEN: c_int = 18;
pub const YAML_ANCHOR_TOKEN: c_int = 19;
pub const YAML_TAG_TOKEN: c_int = 20;
pub const YAML_SCALAR_TOKEN: c_int = 21;
pub const enum_yaml_token_type_e = c_uint;
pub const yaml_token_type_t = enum_yaml_token_type_e;
const struct_unnamed_2 = extern struct {
    encoding: yaml_encoding_t = @import("std").mem.zeroes(yaml_encoding_t),
};
const struct_unnamed_3 = extern struct {
    value: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
};
const struct_unnamed_4 = extern struct {
    value: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
};
const struct_unnamed_5 = extern struct {
    handle: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    suffix: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
};
const struct_unnamed_6 = extern struct {
    value: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    length: usize = @import("std").mem.zeroes(usize),
    style: yaml_scalar_style_t = @import("std").mem.zeroes(yaml_scalar_style_t),
};
const struct_unnamed_7 = extern struct {
    major: c_int = @import("std").mem.zeroes(c_int),
    minor: c_int = @import("std").mem.zeroes(c_int),
};
const struct_unnamed_8 = extern struct {
    handle: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    prefix: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
};
const union_unnamed_1 = extern union {
    stream_start: struct_unnamed_2,
    alias: struct_unnamed_3,
    anchor: struct_unnamed_4,
    tag: struct_unnamed_5,
    scalar: struct_unnamed_6,
    version_directive: struct_unnamed_7,
    tag_directive: struct_unnamed_8,
};
pub const struct_yaml_token_s = extern struct {
    type: yaml_token_type_t = @import("std").mem.zeroes(yaml_token_type_t),
    data: union_unnamed_1 = @import("std").mem.zeroes(union_unnamed_1),
    start_mark: yaml_mark_t = @import("std").mem.zeroes(yaml_mark_t),
    end_mark: yaml_mark_t = @import("std").mem.zeroes(yaml_mark_t),
};
pub const yaml_token_t = struct_yaml_token_s;
pub extern fn yaml_token_delete(token: [*c]yaml_token_t) void;
pub const YAML_NO_EVENT: c_int = 0;
pub const YAML_STREAM_START_EVENT: c_int = 1;
pub const YAML_STREAM_END_EVENT: c_int = 2;
pub const YAML_DOCUMENT_START_EVENT: c_int = 3;
pub const YAML_DOCUMENT_END_EVENT: c_int = 4;
pub const YAML_ALIAS_EVENT: c_int = 5;
pub const YAML_SCALAR_EVENT: c_int = 6;
pub const YAML_SEQUENCE_START_EVENT: c_int = 7;
pub const YAML_SEQUENCE_END_EVENT: c_int = 8;
pub const YAML_MAPPING_START_EVENT: c_int = 9;
pub const YAML_MAPPING_END_EVENT: c_int = 10;
pub const enum_yaml_event_type_e = c_uint;
pub const yaml_event_type_t = enum_yaml_event_type_e;
const struct_unnamed_10 = extern struct {
    encoding: yaml_encoding_t = @import("std").mem.zeroes(yaml_encoding_t),
};
const struct_unnamed_12 = extern struct {
    start: [*c]yaml_tag_directive_t = @import("std").mem.zeroes([*c]yaml_tag_directive_t),
    end: [*c]yaml_tag_directive_t = @import("std").mem.zeroes([*c]yaml_tag_directive_t),
};
const struct_unnamed_11 = extern struct {
    version_directive: [*c]yaml_version_directive_t = @import("std").mem.zeroes([*c]yaml_version_directive_t),
    tag_directives: struct_unnamed_12 = @import("std").mem.zeroes(struct_unnamed_12),
    implicit: c_int = @import("std").mem.zeroes(c_int),
};
const struct_unnamed_13 = extern struct {
    implicit: c_int = @import("std").mem.zeroes(c_int),
};
const struct_unnamed_14 = extern struct {
    anchor: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
};
const struct_unnamed_15 = extern struct {
    anchor: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    tag: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    value: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    length: usize = @import("std").mem.zeroes(usize),
    plain_implicit: c_int = @import("std").mem.zeroes(c_int),
    quoted_implicit: c_int = @import("std").mem.zeroes(c_int),
    style: yaml_scalar_style_t = @import("std").mem.zeroes(yaml_scalar_style_t),
};
const struct_unnamed_16 = extern struct {
    anchor: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    tag: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    implicit: c_int = @import("std").mem.zeroes(c_int),
    style: yaml_sequence_style_t = @import("std").mem.zeroes(yaml_sequence_style_t),
};
const struct_unnamed_17 = extern struct {
    anchor: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    tag: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    implicit: c_int = @import("std").mem.zeroes(c_int),
    style: yaml_mapping_style_t = @import("std").mem.zeroes(yaml_mapping_style_t),
};
const union_unnamed_9 = extern union {
    stream_start: struct_unnamed_10,
    document_start: struct_unnamed_11,
    document_end: struct_unnamed_13,
    alias: struct_unnamed_14,
    scalar: struct_unnamed_15,
    sequence_start: struct_unnamed_16,
    mapping_start: struct_unnamed_17,
};
pub const struct_yaml_event_s = extern struct {
    type: yaml_event_type_t = @import("std").mem.zeroes(yaml_event_type_t),
    data: union_unnamed_9 = @import("std").mem.zeroes(union_unnamed_9),
    start_mark: yaml_mark_t = @import("std").mem.zeroes(yaml_mark_t),
    end_mark: yaml_mark_t = @import("std").mem.zeroes(yaml_mark_t),
};
pub const yaml_event_t = struct_yaml_event_s;
pub extern fn yaml_stream_start_event_initialize(event: [*c]yaml_event_t, encoding: yaml_encoding_t) c_int;
pub extern fn yaml_stream_end_event_initialize(event: [*c]yaml_event_t) c_int;
pub extern fn yaml_document_start_event_initialize(event: [*c]yaml_event_t, version_directive: [*c]yaml_version_directive_t, tag_directives_start: [*c]yaml_tag_directive_t, tag_directives_end: [*c]yaml_tag_directive_t, implicit: c_int) c_int;
pub extern fn yaml_document_end_event_initialize(event: [*c]yaml_event_t, implicit: c_int) c_int;
pub extern fn yaml_alias_event_initialize(event: [*c]yaml_event_t, anchor: [*c]const yaml_char_t) c_int;
pub extern fn yaml_scalar_event_initialize(event: [*c]yaml_event_t, anchor: [*c]const yaml_char_t, tag: [*c]const yaml_char_t, value: [*c]const yaml_char_t, length: c_int, plain_implicit: c_int, quoted_implicit: c_int, style: yaml_scalar_style_t) c_int;
pub extern fn yaml_sequence_start_event_initialize(event: [*c]yaml_event_t, anchor: [*c]const yaml_char_t, tag: [*c]const yaml_char_t, implicit: c_int, style: yaml_sequence_style_t) c_int;
pub extern fn yaml_sequence_end_event_initialize(event: [*c]yaml_event_t) c_int;
pub extern fn yaml_mapping_start_event_initialize(event: [*c]yaml_event_t, anchor: [*c]const yaml_char_t, tag: [*c]const yaml_char_t, implicit: c_int, style: yaml_mapping_style_t) c_int;
pub extern fn yaml_mapping_end_event_initialize(event: [*c]yaml_event_t) c_int;
pub extern fn yaml_event_delete(event: [*c]yaml_event_t) void;
pub const YAML_NO_NODE: c_int = 0;
pub const YAML_SCALAR_NODE: c_int = 1;
pub const YAML_SEQUENCE_NODE: c_int = 2;
pub const YAML_MAPPING_NODE: c_int = 3;
pub const enum_yaml_node_type_e = c_uint;
pub const yaml_node_type_t = enum_yaml_node_type_e;
const struct_unnamed_19 = extern struct {
    value: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    length: usize = @import("std").mem.zeroes(usize),
    style: yaml_scalar_style_t = @import("std").mem.zeroes(yaml_scalar_style_t),
};
pub const yaml_node_item_t = c_int;
const struct_unnamed_21 = extern struct {
    start: [*c]yaml_node_item_t = @import("std").mem.zeroes([*c]yaml_node_item_t),
    end: [*c]yaml_node_item_t = @import("std").mem.zeroes([*c]yaml_node_item_t),
    top: [*c]yaml_node_item_t = @import("std").mem.zeroes([*c]yaml_node_item_t),
};
const struct_unnamed_20 = extern struct {
    items: struct_unnamed_21 = @import("std").mem.zeroes(struct_unnamed_21),
    style: yaml_sequence_style_t = @import("std").mem.zeroes(yaml_sequence_style_t),
};
pub const struct_yaml_node_pair_s = extern struct {
    key: c_int = @import("std").mem.zeroes(c_int),
    value: c_int = @import("std").mem.zeroes(c_int),
};
pub const yaml_node_pair_t = struct_yaml_node_pair_s;
const struct_unnamed_23 = extern struct {
    start: [*c]yaml_node_pair_t = @import("std").mem.zeroes([*c]yaml_node_pair_t),
    end: [*c]yaml_node_pair_t = @import("std").mem.zeroes([*c]yaml_node_pair_t),
    top: [*c]yaml_node_pair_t = @import("std").mem.zeroes([*c]yaml_node_pair_t),
};
const struct_unnamed_22 = extern struct {
    pairs: struct_unnamed_23 = @import("std").mem.zeroes(struct_unnamed_23),
    style: yaml_mapping_style_t = @import("std").mem.zeroes(yaml_mapping_style_t),
};
const union_unnamed_18 = extern union {
    scalar: struct_unnamed_19,
    sequence: struct_unnamed_20,
    mapping: struct_unnamed_22,
};
pub const struct_yaml_node_s = extern struct {
    type: yaml_node_type_t = @import("std").mem.zeroes(yaml_node_type_t),
    tag: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    data: union_unnamed_18 = @import("std").mem.zeroes(union_unnamed_18),
    start_mark: yaml_mark_t = @import("std").mem.zeroes(yaml_mark_t),
    end_mark: yaml_mark_t = @import("std").mem.zeroes(yaml_mark_t),
};
pub const yaml_node_t = struct_yaml_node_s;
const struct_unnamed_24 = extern struct {
    start: [*c]yaml_node_t = @import("std").mem.zeroes([*c]yaml_node_t),
    end: [*c]yaml_node_t = @import("std").mem.zeroes([*c]yaml_node_t),
    top: [*c]yaml_node_t = @import("std").mem.zeroes([*c]yaml_node_t),
};
const struct_unnamed_25 = extern struct {
    start: [*c]yaml_tag_directive_t = @import("std").mem.zeroes([*c]yaml_tag_directive_t),
    end: [*c]yaml_tag_directive_t = @import("std").mem.zeroes([*c]yaml_tag_directive_t),
};
pub const struct_yaml_document_s = extern struct {
    nodes: struct_unnamed_24 = @import("std").mem.zeroes(struct_unnamed_24),
    version_directive: [*c]yaml_version_directive_t = @import("std").mem.zeroes([*c]yaml_version_directive_t),
    tag_directives: struct_unnamed_25 = @import("std").mem.zeroes(struct_unnamed_25),
    start_implicit: c_int = @import("std").mem.zeroes(c_int),
    end_implicit: c_int = @import("std").mem.zeroes(c_int),
    start_mark: yaml_mark_t = @import("std").mem.zeroes(yaml_mark_t),
    end_mark: yaml_mark_t = @import("std").mem.zeroes(yaml_mark_t),
};
pub const yaml_document_t = struct_yaml_document_s;
pub extern fn yaml_document_initialize(document: [*c]yaml_document_t, version_directive: [*c]yaml_version_directive_t, tag_directives_start: [*c]yaml_tag_directive_t, tag_directives_end: [*c]yaml_tag_directive_t, start_implicit: c_int, end_implicit: c_int) c_int;
pub extern fn yaml_document_delete(document: [*c]yaml_document_t) void;
pub extern fn yaml_document_get_node(document: [*c]yaml_document_t, index: c_int) [*c]yaml_node_t;
pub extern fn yaml_document_get_root_node(document: [*c]yaml_document_t) [*c]yaml_node_t;
pub extern fn yaml_document_add_scalar(document: [*c]yaml_document_t, tag: [*c]const yaml_char_t, value: [*c]const yaml_char_t, length: c_int, style: yaml_scalar_style_t) c_int;
pub extern fn yaml_document_add_sequence(document: [*c]yaml_document_t, tag: [*c]const yaml_char_t, style: yaml_sequence_style_t) c_int;
pub extern fn yaml_document_add_mapping(document: [*c]yaml_document_t, tag: [*c]const yaml_char_t, style: yaml_mapping_style_t) c_int;
pub extern fn yaml_document_append_sequence_item(document: [*c]yaml_document_t, sequence: c_int, item: c_int) c_int;
pub extern fn yaml_document_append_mapping_pair(document: [*c]yaml_document_t, mapping: c_int, key: c_int, value: c_int) c_int;
pub const yaml_read_handler_t = fn (?*anyopaque, [*c]u8, usize, [*c]usize) callconv(.c) c_int;
pub const struct_yaml_simple_key_s = extern struct {
    possible: c_int = @import("std").mem.zeroes(c_int),
    required: c_int = @import("std").mem.zeroes(c_int),
    token_number: usize = @import("std").mem.zeroes(usize),
    mark: yaml_mark_t = @import("std").mem.zeroes(yaml_mark_t),
};
pub const yaml_simple_key_t = struct_yaml_simple_key_s;
pub const YAML_PARSE_STREAM_START_STATE: c_int = 0;
pub const YAML_PARSE_IMPLICIT_DOCUMENT_START_STATE: c_int = 1;
pub const YAML_PARSE_DOCUMENT_START_STATE: c_int = 2;
pub const YAML_PARSE_DOCUMENT_CONTENT_STATE: c_int = 3;
pub const YAML_PARSE_DOCUMENT_END_STATE: c_int = 4;
pub const YAML_PARSE_BLOCK_NODE_STATE: c_int = 5;
pub const YAML_PARSE_BLOCK_NODE_OR_INDENTLESS_SEQUENCE_STATE: c_int = 6;
pub const YAML_PARSE_FLOW_NODE_STATE: c_int = 7;
pub const YAML_PARSE_BLOCK_SEQUENCE_FIRST_ENTRY_STATE: c_int = 8;
pub const YAML_PARSE_BLOCK_SEQUENCE_ENTRY_STATE: c_int = 9;
pub const YAML_PARSE_INDENTLESS_SEQUENCE_ENTRY_STATE: c_int = 10;
pub const YAML_PARSE_BLOCK_MAPPING_FIRST_KEY_STATE: c_int = 11;
pub const YAML_PARSE_BLOCK_MAPPING_KEY_STATE: c_int = 12;
pub const YAML_PARSE_BLOCK_MAPPING_VALUE_STATE: c_int = 13;
pub const YAML_PARSE_FLOW_SEQUENCE_FIRST_ENTRY_STATE: c_int = 14;
pub const YAML_PARSE_FLOW_SEQUENCE_ENTRY_STATE: c_int = 15;
pub const YAML_PARSE_FLOW_SEQUENCE_ENTRY_MAPPING_KEY_STATE: c_int = 16;
pub const YAML_PARSE_FLOW_SEQUENCE_ENTRY_MAPPING_VALUE_STATE: c_int = 17;
pub const YAML_PARSE_FLOW_SEQUENCE_ENTRY_MAPPING_END_STATE: c_int = 18;
pub const YAML_PARSE_FLOW_MAPPING_FIRST_KEY_STATE: c_int = 19;
pub const YAML_PARSE_FLOW_MAPPING_KEY_STATE: c_int = 20;
pub const YAML_PARSE_FLOW_MAPPING_VALUE_STATE: c_int = 21;
pub const YAML_PARSE_FLOW_MAPPING_EMPTY_VALUE_STATE: c_int = 22;
pub const YAML_PARSE_END_STATE: c_int = 23;
pub const enum_yaml_parser_state_e = c_uint;
pub const yaml_parser_state_t = enum_yaml_parser_state_e;
pub const struct_yaml_alias_data_s = extern struct {
    anchor: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    index: c_int = @import("std").mem.zeroes(c_int),
    mark: yaml_mark_t = @import("std").mem.zeroes(yaml_mark_t),
};
pub const yaml_alias_data_t = struct_yaml_alias_data_s;
const struct_unnamed_27 = extern struct {
    start: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    end: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    current: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
};
const union_unnamed_26 = extern union {
    string: struct_unnamed_27,
    file: [*c]FILE,
};
const struct_unnamed_28 = extern struct {
    start: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    end: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    pointer: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    last: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
};
const struct_unnamed_29 = extern struct {
    start: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    end: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    pointer: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    last: [*c]u8 = @import("std").mem.zeroes([*c]u8),
};
const struct_unnamed_30 = extern struct {
    start: [*c]yaml_token_t = @import("std").mem.zeroes([*c]yaml_token_t),
    end: [*c]yaml_token_t = @import("std").mem.zeroes([*c]yaml_token_t),
    head: [*c]yaml_token_t = @import("std").mem.zeroes([*c]yaml_token_t),
    tail: [*c]yaml_token_t = @import("std").mem.zeroes([*c]yaml_token_t),
};
const struct_unnamed_31 = extern struct {
    start: [*c]c_int = @import("std").mem.zeroes([*c]c_int),
    end: [*c]c_int = @import("std").mem.zeroes([*c]c_int),
    top: [*c]c_int = @import("std").mem.zeroes([*c]c_int),
};
const struct_unnamed_32 = extern struct {
    start: [*c]yaml_simple_key_t = @import("std").mem.zeroes([*c]yaml_simple_key_t),
    end: [*c]yaml_simple_key_t = @import("std").mem.zeroes([*c]yaml_simple_key_t),
    top: [*c]yaml_simple_key_t = @import("std").mem.zeroes([*c]yaml_simple_key_t),
};
const struct_unnamed_33 = extern struct {
    start: [*c]yaml_parser_state_t = @import("std").mem.zeroes([*c]yaml_parser_state_t),
    end: [*c]yaml_parser_state_t = @import("std").mem.zeroes([*c]yaml_parser_state_t),
    top: [*c]yaml_parser_state_t = @import("std").mem.zeroes([*c]yaml_parser_state_t),
};
const struct_unnamed_34 = extern struct {
    start: [*c]yaml_mark_t = @import("std").mem.zeroes([*c]yaml_mark_t),
    end: [*c]yaml_mark_t = @import("std").mem.zeroes([*c]yaml_mark_t),
    top: [*c]yaml_mark_t = @import("std").mem.zeroes([*c]yaml_mark_t),
};
const struct_unnamed_35 = extern struct {
    start: [*c]yaml_tag_directive_t = @import("std").mem.zeroes([*c]yaml_tag_directive_t),
    end: [*c]yaml_tag_directive_t = @import("std").mem.zeroes([*c]yaml_tag_directive_t),
    top: [*c]yaml_tag_directive_t = @import("std").mem.zeroes([*c]yaml_tag_directive_t),
};
const struct_unnamed_36 = extern struct {
    start: [*c]yaml_alias_data_t = @import("std").mem.zeroes([*c]yaml_alias_data_t),
    end: [*c]yaml_alias_data_t = @import("std").mem.zeroes([*c]yaml_alias_data_t),
    top: [*c]yaml_alias_data_t = @import("std").mem.zeroes([*c]yaml_alias_data_t),
};
pub const struct_yaml_parser_s = extern struct {
    @"error": yaml_error_type_t = @import("std").mem.zeroes(yaml_error_type_t),
    problem: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    problem_offset: usize = @import("std").mem.zeroes(usize),
    problem_value: c_int = @import("std").mem.zeroes(c_int),
    problem_mark: yaml_mark_t = @import("std").mem.zeroes(yaml_mark_t),
    context: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    context_mark: yaml_mark_t = @import("std").mem.zeroes(yaml_mark_t),
    read_handler: ?*const yaml_read_handler_t = @import("std").mem.zeroes(?*const yaml_read_handler_t),
    read_handler_data: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    input: union_unnamed_26 = @import("std").mem.zeroes(union_unnamed_26),
    eof: c_int = @import("std").mem.zeroes(c_int),
    buffer: struct_unnamed_28 = @import("std").mem.zeroes(struct_unnamed_28),
    unread: usize = @import("std").mem.zeroes(usize),
    raw_buffer: struct_unnamed_29 = @import("std").mem.zeroes(struct_unnamed_29),
    encoding: yaml_encoding_t = @import("std").mem.zeroes(yaml_encoding_t),
    offset: usize = @import("std").mem.zeroes(usize),
    mark: yaml_mark_t = @import("std").mem.zeroes(yaml_mark_t),
    stream_start_produced: c_int = @import("std").mem.zeroes(c_int),
    stream_end_produced: c_int = @import("std").mem.zeroes(c_int),
    flow_level: c_int = @import("std").mem.zeroes(c_int),
    tokens: struct_unnamed_30 = @import("std").mem.zeroes(struct_unnamed_30),
    tokens_parsed: usize = @import("std").mem.zeroes(usize),
    token_available: c_int = @import("std").mem.zeroes(c_int),
    indents: struct_unnamed_31 = @import("std").mem.zeroes(struct_unnamed_31),
    indent: c_int = @import("std").mem.zeroes(c_int),
    simple_key_allowed: c_int = @import("std").mem.zeroes(c_int),
    simple_keys: struct_unnamed_32 = @import("std").mem.zeroes(struct_unnamed_32),
    states: struct_unnamed_33 = @import("std").mem.zeroes(struct_unnamed_33),
    state: yaml_parser_state_t = @import("std").mem.zeroes(yaml_parser_state_t),
    marks: struct_unnamed_34 = @import("std").mem.zeroes(struct_unnamed_34),
    tag_directives: struct_unnamed_35 = @import("std").mem.zeroes(struct_unnamed_35),
    aliases: struct_unnamed_36 = @import("std").mem.zeroes(struct_unnamed_36),
    document: [*c]yaml_document_t = @import("std").mem.zeroes([*c]yaml_document_t),
};
pub const yaml_parser_t = struct_yaml_parser_s;
pub extern fn yaml_parser_initialize(parser: [*c]yaml_parser_t) c_int;
pub extern fn yaml_parser_delete(parser: [*c]yaml_parser_t) void;
pub extern fn yaml_parser_set_input_string(parser: [*c]yaml_parser_t, input: [*c]const u8, size: usize) void;
pub extern fn yaml_parser_set_input_file(parser: [*c]yaml_parser_t, file: [*c]FILE) void;
pub extern fn yaml_parser_set_input(parser: [*c]yaml_parser_t, handler: ?*const yaml_read_handler_t, data: ?*anyopaque) void;
pub extern fn yaml_parser_set_encoding(parser: [*c]yaml_parser_t, encoding: yaml_encoding_t) void;
pub extern fn yaml_parser_scan(parser: [*c]yaml_parser_t, token: [*c]yaml_token_t) c_int;
pub extern fn yaml_parser_parse(parser: [*c]yaml_parser_t, event: [*c]yaml_event_t) c_int;
pub extern fn yaml_parser_load(parser: [*c]yaml_parser_t, document: [*c]yaml_document_t) c_int;
pub extern fn yaml_set_max_nest_level(max: c_int) void;
pub const yaml_write_handler_t = fn (?*anyopaque, [*c]u8, usize) callconv(.c) c_int;
pub const YAML_EMIT_STREAM_START_STATE: c_int = 0;
pub const YAML_EMIT_FIRST_DOCUMENT_START_STATE: c_int = 1;
pub const YAML_EMIT_DOCUMENT_START_STATE: c_int = 2;
pub const YAML_EMIT_DOCUMENT_CONTENT_STATE: c_int = 3;
pub const YAML_EMIT_DOCUMENT_END_STATE: c_int = 4;
pub const YAML_EMIT_FLOW_SEQUENCE_FIRST_ITEM_STATE: c_int = 5;
pub const YAML_EMIT_FLOW_SEQUENCE_ITEM_STATE: c_int = 6;
pub const YAML_EMIT_FLOW_MAPPING_FIRST_KEY_STATE: c_int = 7;
pub const YAML_EMIT_FLOW_MAPPING_KEY_STATE: c_int = 8;
pub const YAML_EMIT_FLOW_MAPPING_SIMPLE_VALUE_STATE: c_int = 9;
pub const YAML_EMIT_FLOW_MAPPING_VALUE_STATE: c_int = 10;
pub const YAML_EMIT_BLOCK_SEQUENCE_FIRST_ITEM_STATE: c_int = 11;
pub const YAML_EMIT_BLOCK_SEQUENCE_ITEM_STATE: c_int = 12;
pub const YAML_EMIT_BLOCK_MAPPING_FIRST_KEY_STATE: c_int = 13;
pub const YAML_EMIT_BLOCK_MAPPING_KEY_STATE: c_int = 14;
pub const YAML_EMIT_BLOCK_MAPPING_SIMPLE_VALUE_STATE: c_int = 15;
pub const YAML_EMIT_BLOCK_MAPPING_VALUE_STATE: c_int = 16;
pub const YAML_EMIT_END_STATE: c_int = 17;
pub const enum_yaml_emitter_state_e = c_uint;
pub const yaml_emitter_state_t = enum_yaml_emitter_state_e;
pub const struct_yaml_anchors_s = extern struct {
    references: c_int = @import("std").mem.zeroes(c_int),
    anchor: c_int = @import("std").mem.zeroes(c_int),
    serialized: c_int = @import("std").mem.zeroes(c_int),
};
pub const yaml_anchors_t = struct_yaml_anchors_s;
const struct_unnamed_38 = extern struct {
    buffer: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    size: usize = @import("std").mem.zeroes(usize),
    size_written: [*c]usize = @import("std").mem.zeroes([*c]usize),
};
const union_unnamed_37 = extern union {
    string: struct_unnamed_38,
    file: [*c]FILE,
};
const struct_unnamed_39 = extern struct {
    start: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    end: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    pointer: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    last: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
};
const struct_unnamed_40 = extern struct {
    start: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    end: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    pointer: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    last: [*c]u8 = @import("std").mem.zeroes([*c]u8),
};
const struct_unnamed_41 = extern struct {
    start: [*c]yaml_emitter_state_t = @import("std").mem.zeroes([*c]yaml_emitter_state_t),
    end: [*c]yaml_emitter_state_t = @import("std").mem.zeroes([*c]yaml_emitter_state_t),
    top: [*c]yaml_emitter_state_t = @import("std").mem.zeroes([*c]yaml_emitter_state_t),
};
const struct_unnamed_42 = extern struct {
    start: [*c]yaml_event_t = @import("std").mem.zeroes([*c]yaml_event_t),
    end: [*c]yaml_event_t = @import("std").mem.zeroes([*c]yaml_event_t),
    head: [*c]yaml_event_t = @import("std").mem.zeroes([*c]yaml_event_t),
    tail: [*c]yaml_event_t = @import("std").mem.zeroes([*c]yaml_event_t),
};
const struct_unnamed_43 = extern struct {
    start: [*c]c_int = @import("std").mem.zeroes([*c]c_int),
    end: [*c]c_int = @import("std").mem.zeroes([*c]c_int),
    top: [*c]c_int = @import("std").mem.zeroes([*c]c_int),
};
const struct_unnamed_44 = extern struct {
    start: [*c]yaml_tag_directive_t = @import("std").mem.zeroes([*c]yaml_tag_directive_t),
    end: [*c]yaml_tag_directive_t = @import("std").mem.zeroes([*c]yaml_tag_directive_t),
    top: [*c]yaml_tag_directive_t = @import("std").mem.zeroes([*c]yaml_tag_directive_t),
};
const struct_unnamed_45 = extern struct {
    anchor: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    anchor_length: usize = @import("std").mem.zeroes(usize),
    alias: c_int = @import("std").mem.zeroes(c_int),
};
const struct_unnamed_46 = extern struct {
    handle: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    handle_length: usize = @import("std").mem.zeroes(usize),
    suffix: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    suffix_length: usize = @import("std").mem.zeroes(usize),
};
const struct_unnamed_47 = extern struct {
    value: [*c]yaml_char_t = @import("std").mem.zeroes([*c]yaml_char_t),
    length: usize = @import("std").mem.zeroes(usize),
    multiline: c_int = @import("std").mem.zeroes(c_int),
    flow_plain_allowed: c_int = @import("std").mem.zeroes(c_int),
    block_plain_allowed: c_int = @import("std").mem.zeroes(c_int),
    single_quoted_allowed: c_int = @import("std").mem.zeroes(c_int),
    block_allowed: c_int = @import("std").mem.zeroes(c_int),
    style: yaml_scalar_style_t = @import("std").mem.zeroes(yaml_scalar_style_t),
};
pub const struct_yaml_emitter_s = extern struct {
    @"error": yaml_error_type_t = @import("std").mem.zeroes(yaml_error_type_t),
    problem: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    write_handler: ?*const yaml_write_handler_t = @import("std").mem.zeroes(?*const yaml_write_handler_t),
    write_handler_data: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    output: union_unnamed_37 = @import("std").mem.zeroes(union_unnamed_37),
    buffer: struct_unnamed_39 = @import("std").mem.zeroes(struct_unnamed_39),
    raw_buffer: struct_unnamed_40 = @import("std").mem.zeroes(struct_unnamed_40),
    encoding: yaml_encoding_t = @import("std").mem.zeroes(yaml_encoding_t),
    canonical: c_int = @import("std").mem.zeroes(c_int),
    best_indent: c_int = @import("std").mem.zeroes(c_int),
    best_width: c_int = @import("std").mem.zeroes(c_int),
    unicode: c_int = @import("std").mem.zeroes(c_int),
    line_break: yaml_break_t = @import("std").mem.zeroes(yaml_break_t),
    states: struct_unnamed_41 = @import("std").mem.zeroes(struct_unnamed_41),
    state: yaml_emitter_state_t = @import("std").mem.zeroes(yaml_emitter_state_t),
    events: struct_unnamed_42 = @import("std").mem.zeroes(struct_unnamed_42),
    indents: struct_unnamed_43 = @import("std").mem.zeroes(struct_unnamed_43),
    tag_directives: struct_unnamed_44 = @import("std").mem.zeroes(struct_unnamed_44),
    indent: c_int = @import("std").mem.zeroes(c_int),
    flow_level: c_int = @import("std").mem.zeroes(c_int),
    root_context: c_int = @import("std").mem.zeroes(c_int),
    sequence_context: c_int = @import("std").mem.zeroes(c_int),
    mapping_context: c_int = @import("std").mem.zeroes(c_int),
    simple_key_context: c_int = @import("std").mem.zeroes(c_int),
    line: c_int = @import("std").mem.zeroes(c_int),
    column: c_int = @import("std").mem.zeroes(c_int),
    whitespace: c_int = @import("std").mem.zeroes(c_int),
    indention: c_int = @import("std").mem.zeroes(c_int),
    open_ended: c_int = @import("std").mem.zeroes(c_int),
    anchor_data: struct_unnamed_45 = @import("std").mem.zeroes(struct_unnamed_45),
    tag_data: struct_unnamed_46 = @import("std").mem.zeroes(struct_unnamed_46),
    scalar_data: struct_unnamed_47 = @import("std").mem.zeroes(struct_unnamed_47),
    opened: c_int = @import("std").mem.zeroes(c_int),
    closed: c_int = @import("std").mem.zeroes(c_int),
    anchors: [*c]yaml_anchors_t = @import("std").mem.zeroes([*c]yaml_anchors_t),
    last_anchor_id: c_int = @import("std").mem.zeroes(c_int),
    document: [*c]yaml_document_t = @import("std").mem.zeroes([*c]yaml_document_t),
};
pub const yaml_emitter_t = struct_yaml_emitter_s;
pub extern fn yaml_emitter_initialize(emitter: [*c]yaml_emitter_t) c_int;
pub extern fn yaml_emitter_delete(emitter: [*c]yaml_emitter_t) void;
pub extern fn yaml_emitter_set_output_string(emitter: [*c]yaml_emitter_t, output: [*c]u8, size: usize, size_written: [*c]usize) void;
pub extern fn yaml_emitter_set_output_file(emitter: [*c]yaml_emitter_t, file: [*c]FILE) void;
pub extern fn yaml_emitter_set_output(emitter: [*c]yaml_emitter_t, handler: ?*const yaml_write_handler_t, data: ?*anyopaque) void;
pub extern fn yaml_emitter_set_encoding(emitter: [*c]yaml_emitter_t, encoding: yaml_encoding_t) void;
pub extern fn yaml_emitter_set_canonical(emitter: [*c]yaml_emitter_t, canonical: c_int) void;
pub extern fn yaml_emitter_set_indent(emitter: [*c]yaml_emitter_t, indent: c_int) void;
pub extern fn yaml_emitter_set_width(emitter: [*c]yaml_emitter_t, width: c_int) void;
pub extern fn yaml_emitter_set_unicode(emitter: [*c]yaml_emitter_t, unicode: c_int) void;
pub extern fn yaml_emitter_set_break(emitter: [*c]yaml_emitter_t, line_break: yaml_break_t) void;
pub extern fn yaml_emitter_emit(emitter: [*c]yaml_emitter_t, event: [*c]yaml_event_t) c_int;
pub extern fn yaml_emitter_open(emitter: [*c]yaml_emitter_t) c_int;
pub extern fn yaml_emitter_close(emitter: [*c]yaml_emitter_t) c_int;
pub extern fn yaml_emitter_dump(emitter: [*c]yaml_emitter_t, document: [*c]yaml_document_t) c_int;
pub extern fn yaml_emitter_flush(emitter: [*c]yaml_emitter_t) c_int;
pub const __llvm__ = @as(c_int, 1);
pub const __clang__ = @as(c_int, 1);
pub const __clang_major__ = @as(c_int, 20);
pub const __clang_minor__ = @as(c_int, 1);
pub const __clang_patchlevel__ = @as(c_int, 2);
pub const __clang_version__ = "20.1.2 (https://github.com/ziglang/zig-bootstrap c6bc9398c72c7a63fe9420a9055dcfd1845bc266)";
pub const __GNUC__ = @as(c_int, 4);
pub const __GNUC_MINOR__ = @as(c_int, 2);
pub const __GNUC_PATCHLEVEL__ = @as(c_int, 1);
pub const __GXX_ABI_VERSION = @as(c_int, 1002);
pub const __ATOMIC_RELAXED = @as(c_int, 0);
pub const __ATOMIC_CONSUME = @as(c_int, 1);
pub const __ATOMIC_ACQUIRE = @as(c_int, 2);
pub const __ATOMIC_RELEASE = @as(c_int, 3);
pub const __ATOMIC_ACQ_REL = @as(c_int, 4);
pub const __ATOMIC_SEQ_CST = @as(c_int, 5);
pub const __MEMORY_SCOPE_SYSTEM = @as(c_int, 0);
pub const __MEMORY_SCOPE_DEVICE = @as(c_int, 1);
pub const __MEMORY_SCOPE_WRKGRP = @as(c_int, 2);
pub const __MEMORY_SCOPE_WVFRNT = @as(c_int, 3);
pub const __MEMORY_SCOPE_SINGLE = @as(c_int, 4);
pub const __OPENCL_MEMORY_SCOPE_WORK_ITEM = @as(c_int, 0);
pub const __OPENCL_MEMORY_SCOPE_WORK_GROUP = @as(c_int, 1);
pub const __OPENCL_MEMORY_SCOPE_DEVICE = @as(c_int, 2);
pub const __OPENCL_MEMORY_SCOPE_ALL_SVM_DEVICES = @as(c_int, 3);
pub const __OPENCL_MEMORY_SCOPE_SUB_GROUP = @as(c_int, 4);
pub const __FPCLASS_SNAN = @as(c_int, 0x0001);
pub const __FPCLASS_QNAN = @as(c_int, 0x0002);
pub const __FPCLASS_NEGINF = @as(c_int, 0x0004);
pub const __FPCLASS_NEGNORMAL = @as(c_int, 0x0008);
pub const __FPCLASS_NEGSUBNORMAL = @as(c_int, 0x0010);
pub const __FPCLASS_NEGZERO = @as(c_int, 0x0020);
pub const __FPCLASS_POSZERO = @as(c_int, 0x0040);
pub const __FPCLASS_POSSUBNORMAL = @as(c_int, 0x0080);
pub const __FPCLASS_POSNORMAL = @as(c_int, 0x0100);
pub const __FPCLASS_POSINF = @as(c_int, 0x0200);
pub const __PRAGMA_REDEFINE_EXTNAME = @as(c_int, 1);
pub const __VERSION__ = "Clang 20.1.2 (https://github.com/ziglang/zig-bootstrap c6bc9398c72c7a63fe9420a9055dcfd1845bc266)";
pub const __GXX_TYPEINFO_EQUALITY_INLINE = @as(c_int, 0);
pub const __OBJC_BOOL_IS_BOOL = @as(c_int, 0);
pub const __CONSTANT_CFSTRINGS__ = @as(c_int, 1);
pub const __SEH__ = @as(c_int, 1);
pub const __clang_literal_encoding__ = "UTF-8";
pub const __clang_wide_literal_encoding__ = "UTF-16";
pub const __ORDER_LITTLE_ENDIAN__ = @as(c_int, 1234);
pub const __ORDER_BIG_ENDIAN__ = @as(c_int, 4321);
pub const __ORDER_PDP_ENDIAN__ = @as(c_int, 3412);
pub const __BYTE_ORDER__ = __ORDER_LITTLE_ENDIAN__;
pub const __LITTLE_ENDIAN__ = @as(c_int, 1);
pub const __CHAR_BIT__ = @as(c_int, 8);
pub const __BOOL_WIDTH__ = @as(c_int, 1);
pub const __SHRT_WIDTH__ = @as(c_int, 16);
pub const __INT_WIDTH__ = @as(c_int, 32);
pub const __LONG_WIDTH__ = @as(c_int, 32);
pub const __LLONG_WIDTH__ = @as(c_int, 64);
pub const __BITINT_MAXWIDTH__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 8388608, .decimal);
pub const __SCHAR_MAX__ = @as(c_int, 127);
pub const __SHRT_MAX__ = @as(c_int, 32767);
pub const __INT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __LONG_MAX__ = @as(c_long, 2147483647);
pub const __LONG_LONG_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __WCHAR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __WCHAR_WIDTH__ = @as(c_int, 16);
pub const __WINT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __WINT_WIDTH__ = @as(c_int, 16);
pub const __INTMAX_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INTMAX_WIDTH__ = @as(c_int, 64);
pub const __SIZE_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __SIZE_WIDTH__ = @as(c_int, 64);
pub const __UINTMAX_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINTMAX_WIDTH__ = @as(c_int, 64);
pub const __PTRDIFF_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __PTRDIFF_WIDTH__ = @as(c_int, 64);
pub const __INTPTR_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INTPTR_WIDTH__ = @as(c_int, 64);
pub const __UINTPTR_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINTPTR_WIDTH__ = @as(c_int, 64);
pub const __SIZEOF_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_FLOAT__ = @as(c_int, 4);
pub const __SIZEOF_INT__ = @as(c_int, 4);
pub const __SIZEOF_LONG__ = @as(c_int, 4);
pub const __SIZEOF_LONG_DOUBLE__ = @as(c_int, 16);
pub const __SIZEOF_LONG_LONG__ = @as(c_int, 8);
pub const __SIZEOF_POINTER__ = @as(c_int, 8);
pub const __SIZEOF_SHORT__ = @as(c_int, 2);
pub const __SIZEOF_PTRDIFF_T__ = @as(c_int, 8);
pub const __SIZEOF_SIZE_T__ = @as(c_int, 8);
pub const __SIZEOF_WCHAR_T__ = @as(c_int, 2);
pub const __SIZEOF_WINT_T__ = @as(c_int, 2);
pub const __SIZEOF_INT128__ = @as(c_int, 16);
pub const __INTMAX_TYPE__ = c_longlong;
pub const __INTMAX_FMTd__ = "lld";
pub const __INTMAX_FMTi__ = "lli";
pub const __INTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `LL`");
// (no file):95:9
pub const __INTMAX_C = @import("std").zig.c_translation.Macros.LL_SUFFIX;
pub const __UINTMAX_TYPE__ = c_ulonglong;
pub const __UINTMAX_FMTo__ = "llo";
pub const __UINTMAX_FMTu__ = "llu";
pub const __UINTMAX_FMTx__ = "llx";
pub const __UINTMAX_FMTX__ = "llX";
pub const __UINTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `ULL`");
// (no file):102:9
pub const __UINTMAX_C = @import("std").zig.c_translation.Macros.ULL_SUFFIX;
pub const __PTRDIFF_TYPE__ = c_longlong;
pub const __PTRDIFF_FMTd__ = "lld";
pub const __PTRDIFF_FMTi__ = "lli";
pub const __INTPTR_TYPE__ = c_longlong;
pub const __INTPTR_FMTd__ = "lld";
pub const __INTPTR_FMTi__ = "lli";
pub const __SIZE_TYPE__ = c_ulonglong;
pub const __SIZE_FMTo__ = "llo";
pub const __SIZE_FMTu__ = "llu";
pub const __SIZE_FMTx__ = "llx";
pub const __SIZE_FMTX__ = "llX";
pub const __WCHAR_TYPE__ = c_ushort;
pub const __WINT_TYPE__ = c_ushort;
pub const __SIG_ATOMIC_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __SIG_ATOMIC_WIDTH__ = @as(c_int, 32);
pub const __CHAR16_TYPE__ = c_ushort;
pub const __CHAR32_TYPE__ = c_uint;
pub const __UINTPTR_TYPE__ = c_ulonglong;
pub const __UINTPTR_FMTo__ = "llo";
pub const __UINTPTR_FMTu__ = "llu";
pub const __UINTPTR_FMTx__ = "llx";
pub const __UINTPTR_FMTX__ = "llX";
pub const __FLT16_DENORM_MIN__ = @as(f16, 5.9604644775390625e-8);
pub const __FLT16_NORM_MAX__ = @as(f16, 6.5504e+4);
pub const __FLT16_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT16_DIG__ = @as(c_int, 3);
pub const __FLT16_DECIMAL_DIG__ = @as(c_int, 5);
pub const __FLT16_EPSILON__ = @as(f16, 9.765625e-4);
pub const __FLT16_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT16_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT16_MANT_DIG__ = @as(c_int, 11);
pub const __FLT16_MAX_10_EXP__ = @as(c_int, 4);
pub const __FLT16_MAX_EXP__ = @as(c_int, 16);
pub const __FLT16_MAX__ = @as(f16, 6.5504e+4);
pub const __FLT16_MIN_10_EXP__ = -@as(c_int, 4);
pub const __FLT16_MIN_EXP__ = -@as(c_int, 13);
pub const __FLT16_MIN__ = @as(f16, 6.103515625e-5);
pub const __FLT_DENORM_MIN__ = @as(f32, 1.40129846e-45);
pub const __FLT_NORM_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT_DIG__ = @as(c_int, 6);
pub const __FLT_DECIMAL_DIG__ = @as(c_int, 9);
pub const __FLT_EPSILON__ = @as(f32, 1.19209290e-7);
pub const __FLT_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT_MANT_DIG__ = @as(c_int, 24);
pub const __FLT_MAX_10_EXP__ = @as(c_int, 38);
pub const __FLT_MAX_EXP__ = @as(c_int, 128);
pub const __FLT_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_MIN_10_EXP__ = -@as(c_int, 37);
pub const __FLT_MIN_EXP__ = -@as(c_int, 125);
pub const __FLT_MIN__ = @as(f32, 1.17549435e-38);
pub const __DBL_DENORM_MIN__ = @as(f64, 4.9406564584124654e-324);
pub const __DBL_NORM_MAX__ = @as(f64, 1.7976931348623157e+308);
pub const __DBL_HAS_DENORM__ = @as(c_int, 1);
pub const __DBL_DIG__ = @as(c_int, 15);
pub const __DBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __DBL_EPSILON__ = @as(f64, 2.2204460492503131e-16);
pub const __DBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __DBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __DBL_MANT_DIG__ = @as(c_int, 53);
pub const __DBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __DBL_MAX_EXP__ = @as(c_int, 1024);
pub const __DBL_MAX__ = @as(f64, 1.7976931348623157e+308);
pub const __DBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __DBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __DBL_MIN__ = @as(f64, 2.2250738585072014e-308);
pub const __LDBL_DENORM_MIN__ = @as(c_longdouble, 3.64519953188247460253e-4951);
pub const __LDBL_NORM_MAX__ = @as(c_longdouble, 1.18973149535723176502e+4932);
pub const __LDBL_HAS_DENORM__ = @as(c_int, 1);
pub const __LDBL_DIG__ = @as(c_int, 18);
pub const __LDBL_DECIMAL_DIG__ = @as(c_int, 21);
pub const __LDBL_EPSILON__ = @as(c_longdouble, 1.08420217248550443401e-19);
pub const __LDBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __LDBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __LDBL_MANT_DIG__ = @as(c_int, 64);
pub const __LDBL_MAX_10_EXP__ = @as(c_int, 4932);
pub const __LDBL_MAX_EXP__ = @as(c_int, 16384);
pub const __LDBL_MAX__ = @as(c_longdouble, 1.18973149535723176502e+4932);
pub const __LDBL_MIN_10_EXP__ = -@as(c_int, 4931);
pub const __LDBL_MIN_EXP__ = -@as(c_int, 16381);
pub const __LDBL_MIN__ = @as(c_longdouble, 3.36210314311209350626e-4932);
pub const __POINTER_WIDTH__ = @as(c_int, 64);
pub const __BIGGEST_ALIGNMENT__ = @as(c_int, 16);
pub const __WCHAR_UNSIGNED__ = @as(c_int, 1);
pub const __WINT_UNSIGNED__ = @as(c_int, 1);
pub const __INT8_TYPE__ = i8;
pub const __INT8_FMTd__ = "hhd";
pub const __INT8_FMTi__ = "hhi";
pub const __INT8_C_SUFFIX__ = "";
pub inline fn __INT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT16_TYPE__ = c_short;
pub const __INT16_FMTd__ = "hd";
pub const __INT16_FMTi__ = "hi";
pub const __INT16_C_SUFFIX__ = "";
pub inline fn __INT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT32_TYPE__ = c_int;
pub const __INT32_FMTd__ = "d";
pub const __INT32_FMTi__ = "i";
pub const __INT32_C_SUFFIX__ = "";
pub inline fn __INT32_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT64_TYPE__ = c_longlong;
pub const __INT64_FMTd__ = "lld";
pub const __INT64_FMTi__ = "lli";
pub const __INT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `LL`");
// (no file):208:9
pub const __INT64_C = @import("std").zig.c_translation.Macros.LL_SUFFIX;
pub const __UINT8_TYPE__ = u8;
pub const __UINT8_FMTo__ = "hho";
pub const __UINT8_FMTu__ = "hhu";
pub const __UINT8_FMTx__ = "hhx";
pub const __UINT8_FMTX__ = "hhX";
pub const __UINT8_C_SUFFIX__ = "";
pub inline fn __UINT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __UINT8_MAX__ = @as(c_int, 255);
pub const __INT8_MAX__ = @as(c_int, 127);
pub const __UINT16_TYPE__ = c_ushort;
pub const __UINT16_FMTo__ = "ho";
pub const __UINT16_FMTu__ = "hu";
pub const __UINT16_FMTx__ = "hx";
pub const __UINT16_FMTX__ = "hX";
pub const __UINT16_C_SUFFIX__ = "";
pub inline fn __UINT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __UINT16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __INT16_MAX__ = @as(c_int, 32767);
pub const __UINT32_TYPE__ = c_uint;
pub const __UINT32_FMTo__ = "o";
pub const __UINT32_FMTu__ = "u";
pub const __UINT32_FMTx__ = "x";
pub const __UINT32_FMTX__ = "X";
pub const __UINT32_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `U`");
// (no file):233:9
pub const __UINT32_C = @import("std").zig.c_translation.Macros.U_SUFFIX;
pub const __UINT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __INT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __UINT64_TYPE__ = c_ulonglong;
pub const __UINT64_FMTo__ = "llo";
pub const __UINT64_FMTu__ = "llu";
pub const __UINT64_FMTx__ = "llx";
pub const __UINT64_FMTX__ = "llX";
pub const __UINT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `ULL`");
// (no file):242:9
pub const __UINT64_C = @import("std").zig.c_translation.Macros.ULL_SUFFIX;
pub const __UINT64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __INT64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_LEAST8_TYPE__ = i8;
pub const __INT_LEAST8_MAX__ = @as(c_int, 127);
pub const __INT_LEAST8_WIDTH__ = @as(c_int, 8);
pub const __INT_LEAST8_FMTd__ = "hhd";
pub const __INT_LEAST8_FMTi__ = "hhi";
pub const __UINT_LEAST8_TYPE__ = u8;
pub const __UINT_LEAST8_MAX__ = @as(c_int, 255);
pub const __UINT_LEAST8_FMTo__ = "hho";
pub const __UINT_LEAST8_FMTu__ = "hhu";
pub const __UINT_LEAST8_FMTx__ = "hhx";
pub const __UINT_LEAST8_FMTX__ = "hhX";
pub const __INT_LEAST16_TYPE__ = c_short;
pub const __INT_LEAST16_MAX__ = @as(c_int, 32767);
pub const __INT_LEAST16_WIDTH__ = @as(c_int, 16);
pub const __INT_LEAST16_FMTd__ = "hd";
pub const __INT_LEAST16_FMTi__ = "hi";
pub const __UINT_LEAST16_TYPE__ = c_ushort;
pub const __UINT_LEAST16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_LEAST16_FMTo__ = "ho";
pub const __UINT_LEAST16_FMTu__ = "hu";
pub const __UINT_LEAST16_FMTx__ = "hx";
pub const __UINT_LEAST16_FMTX__ = "hX";
pub const __INT_LEAST32_TYPE__ = c_int;
pub const __INT_LEAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_LEAST32_WIDTH__ = @as(c_int, 32);
pub const __INT_LEAST32_FMTd__ = "d";
pub const __INT_LEAST32_FMTi__ = "i";
pub const __UINT_LEAST32_TYPE__ = c_uint;
pub const __UINT_LEAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_LEAST32_FMTo__ = "o";
pub const __UINT_LEAST32_FMTu__ = "u";
pub const __UINT_LEAST32_FMTx__ = "x";
pub const __UINT_LEAST32_FMTX__ = "X";
pub const __INT_LEAST64_TYPE__ = c_longlong;
pub const __INT_LEAST64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_LEAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_LEAST64_FMTd__ = "lld";
pub const __INT_LEAST64_FMTi__ = "lli";
pub const __UINT_LEAST64_TYPE__ = c_ulonglong;
pub const __UINT_LEAST64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINT_LEAST64_FMTo__ = "llo";
pub const __UINT_LEAST64_FMTu__ = "llu";
pub const __UINT_LEAST64_FMTx__ = "llx";
pub const __UINT_LEAST64_FMTX__ = "llX";
pub const __INT_FAST8_TYPE__ = i8;
pub const __INT_FAST8_MAX__ = @as(c_int, 127);
pub const __INT_FAST8_WIDTH__ = @as(c_int, 8);
pub const __INT_FAST8_FMTd__ = "hhd";
pub const __INT_FAST8_FMTi__ = "hhi";
pub const __UINT_FAST8_TYPE__ = u8;
pub const __UINT_FAST8_MAX__ = @as(c_int, 255);
pub const __UINT_FAST8_FMTo__ = "hho";
pub const __UINT_FAST8_FMTu__ = "hhu";
pub const __UINT_FAST8_FMTx__ = "hhx";
pub const __UINT_FAST8_FMTX__ = "hhX";
pub const __INT_FAST16_TYPE__ = c_short;
pub const __INT_FAST16_MAX__ = @as(c_int, 32767);
pub const __INT_FAST16_WIDTH__ = @as(c_int, 16);
pub const __INT_FAST16_FMTd__ = "hd";
pub const __INT_FAST16_FMTi__ = "hi";
pub const __UINT_FAST16_TYPE__ = c_ushort;
pub const __UINT_FAST16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_FAST16_FMTo__ = "ho";
pub const __UINT_FAST16_FMTu__ = "hu";
pub const __UINT_FAST16_FMTx__ = "hx";
pub const __UINT_FAST16_FMTX__ = "hX";
pub const __INT_FAST32_TYPE__ = c_int;
pub const __INT_FAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_FAST32_WIDTH__ = @as(c_int, 32);
pub const __INT_FAST32_FMTd__ = "d";
pub const __INT_FAST32_FMTi__ = "i";
pub const __UINT_FAST32_TYPE__ = c_uint;
pub const __UINT_FAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_FAST32_FMTo__ = "o";
pub const __UINT_FAST32_FMTu__ = "u";
pub const __UINT_FAST32_FMTx__ = "x";
pub const __UINT_FAST32_FMTX__ = "X";
pub const __INT_FAST64_TYPE__ = c_longlong;
pub const __INT_FAST64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_FAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_FAST64_FMTd__ = "lld";
pub const __INT_FAST64_FMTi__ = "lli";
pub const __UINT_FAST64_TYPE__ = c_ulonglong;
pub const __UINT_FAST64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINT_FAST64_FMTo__ = "llo";
pub const __UINT_FAST64_FMTu__ = "llu";
pub const __UINT_FAST64_FMTx__ = "llx";
pub const __UINT_FAST64_FMTX__ = "llX";
pub const __USER_LABEL_PREFIX__ = "";
pub const __FINITE_MATH_ONLY__ = @as(c_int, 0);
pub const __GNUC_STDC_INLINE__ = @as(c_int, 1);
pub const __GCC_ATOMIC_TEST_AND_SET_TRUEVAL = @as(c_int, 1);
pub const __GCC_DESTRUCTIVE_SIZE = @as(c_int, 64);
pub const __GCC_CONSTRUCTIVE_SIZE = @as(c_int, 64);
pub const __CLANG_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __NO_INLINE__ = @as(c_int, 1);
pub const __PIC__ = @as(c_int, 2);
pub const __pic__ = @as(c_int, 2);
pub const __FLT_RADIX__ = @as(c_int, 2);
pub const __DECIMAL_DIG__ = __LDBL_DECIMAL_DIG__;
pub const __SSP_STRONG__ = @as(c_int, 2);
pub const __GCC_ASM_FLAG_OUTPUTS__ = @as(c_int, 1);
pub const __code_model_small__ = @as(c_int, 1);
pub const __amd64__ = @as(c_int, 1);
pub const __amd64 = @as(c_int, 1);
pub const __x86_64 = @as(c_int, 1);
pub const __x86_64__ = @as(c_int, 1);
pub const __SEG_GS = @as(c_int, 1);
pub const __SEG_FS = @as(c_int, 1);
pub const __seg_gs = @compileError("unable to translate macro: undefined identifier `address_space`");
// (no file):376:9
pub const __seg_fs = @compileError("unable to translate macro: undefined identifier `address_space`");
// (no file):377:9
pub const __znver3 = @as(c_int, 1);
pub const __znver3__ = @as(c_int, 1);
pub const __tune_znver3__ = @as(c_int, 1);
pub const __REGISTER_PREFIX__ = "";
pub const __NO_MATH_INLINES = @as(c_int, 1);
pub const __AES__ = @as(c_int, 1);
pub const __VAES__ = @as(c_int, 1);
pub const __PCLMUL__ = @as(c_int, 1);
pub const __VPCLMULQDQ__ = @as(c_int, 1);
pub const __LAHF_SAHF__ = @as(c_int, 1);
pub const __LZCNT__ = @as(c_int, 1);
pub const __RDRND__ = @as(c_int, 1);
pub const __FSGSBASE__ = @as(c_int, 1);
pub const __BMI__ = @as(c_int, 1);
pub const __BMI2__ = @as(c_int, 1);
pub const __POPCNT__ = @as(c_int, 1);
pub const __PRFCHW__ = @as(c_int, 1);
pub const __RDSEED__ = @as(c_int, 1);
pub const __ADX__ = @as(c_int, 1);
pub const __MOVBE__ = @as(c_int, 1);
pub const __SSE4A__ = @as(c_int, 1);
pub const __FMA__ = @as(c_int, 1);
pub const __F16C__ = @as(c_int, 1);
pub const __SHA__ = @as(c_int, 1);
pub const __FXSR__ = @as(c_int, 1);
pub const __XSAVE__ = @as(c_int, 1);
pub const __XSAVEOPT__ = @as(c_int, 1);
pub const __XSAVEC__ = @as(c_int, 1);
pub const __XSAVES__ = @as(c_int, 1);
pub const __CLFLUSHOPT__ = @as(c_int, 1);
pub const __CLWB__ = @as(c_int, 1);
pub const __SHSTK__ = @as(c_int, 1);
pub const __CLZERO__ = @as(c_int, 1);
pub const __RDPID__ = @as(c_int, 1);
pub const __CRC32__ = @as(c_int, 1);
pub const __AVX2__ = @as(c_int, 1);
pub const __AVX__ = @as(c_int, 1);
pub const __SSE4_2__ = @as(c_int, 1);
pub const __SSE4_1__ = @as(c_int, 1);
pub const __SSSE3__ = @as(c_int, 1);
pub const __SSE3__ = @as(c_int, 1);
pub const __SSE2__ = @as(c_int, 1);
pub const __SSE2_MATH__ = @as(c_int, 1);
pub const __SSE__ = @as(c_int, 1);
pub const __SSE_MATH__ = @as(c_int, 1);
pub const __MMX__ = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_1 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_2 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_16 = @as(c_int, 1);
pub const __SIZEOF_FLOAT128__ = @as(c_int, 16);
pub const _WIN32 = @as(c_int, 1);
pub const _WIN64 = @as(c_int, 1);
pub const WIN32 = @as(c_int, 1);
pub const __WIN32 = @as(c_int, 1);
pub const __WIN32__ = @as(c_int, 1);
pub const WINNT = @as(c_int, 1);
pub const __WINNT = @as(c_int, 1);
pub const __WINNT__ = @as(c_int, 1);
pub const WIN64 = @as(c_int, 1);
pub const __WIN64 = @as(c_int, 1);
pub const __WIN64__ = @as(c_int, 1);
pub const __MINGW64__ = @as(c_int, 1);
pub const __MSVCRT__ = @as(c_int, 1);
pub const __MINGW32__ = @as(c_int, 1);
pub const __declspec = @compileError("unable to translate C expr: unexpected token '__attribute__'");
// (no file):444:9
pub const _cdecl = @compileError("unable to translate macro: undefined identifier `__cdecl__`");
// (no file):445:9
pub const __cdecl = @compileError("unable to translate macro: undefined identifier `__cdecl__`");
// (no file):446:9
pub const _stdcall = @compileError("unable to translate macro: undefined identifier `__stdcall__`");
// (no file):447:9
pub const __stdcall = @compileError("unable to translate macro: undefined identifier `__stdcall__`");
// (no file):448:9
pub const _fastcall = @compileError("unable to translate macro: undefined identifier `__fastcall__`");
// (no file):449:9
pub const __fastcall = @compileError("unable to translate macro: undefined identifier `__fastcall__`");
// (no file):450:9
pub const _thiscall = @compileError("unable to translate macro: undefined identifier `__thiscall__`");
// (no file):451:9
pub const __thiscall = @compileError("unable to translate macro: undefined identifier `__thiscall__`");
// (no file):452:9
pub const _pascal = @compileError("unable to translate macro: undefined identifier `__pascal__`");
// (no file):453:9
pub const __pascal = @compileError("unable to translate macro: undefined identifier `__pascal__`");
// (no file):454:9
pub const __STDC__ = @as(c_int, 1);
pub const __STDC_HOSTED__ = @as(c_int, 1);
pub const __STDC_VERSION__ = @as(c_long, 201710);
pub const __STDC_UTF_16__ = @as(c_int, 1);
pub const __STDC_UTF_32__ = @as(c_int, 1);
pub const __STDC_EMBED_NOT_FOUND__ = @as(c_int, 0);
pub const __STDC_EMBED_FOUND__ = @as(c_int, 1);
pub const __STDC_EMBED_EMPTY__ = @as(c_int, 2);
pub const __MSVCRT_VERSION__ = @as(c_int, 0xE00);
pub const _WIN32_WINNT = @as(c_int, 0x0a00);
pub const YAML_H = "";
pub const _INC_STDLIB = "";
pub const _INC_CORECRT = "";
pub const _INC__MINGW_H = "";
pub const _INC_CRTDEFS_MACRO = "";
pub const __MINGW64_PASTE2 = @compileError("unable to translate C expr: unexpected token '##'");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw_mac.h:10:9
pub inline fn __MINGW64_PASTE(x: anytype, y: anytype) @TypeOf(__MINGW64_PASTE2(x, y)) {
    _ = &x;
    _ = &y;
    return __MINGW64_PASTE2(x, y);
}
pub const __STRINGIFY = @compileError("unable to translate C expr: unexpected token '#'");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw_mac.h:13:9
pub inline fn __MINGW64_STRINGIFY(x: anytype) @TypeOf(__STRINGIFY(x)) {
    _ = &x;
    return __STRINGIFY(x);
}
pub const __MINGW64_VERSION_MAJOR = @as(c_int, 13);
pub const __MINGW64_VERSION_MINOR = @as(c_int, 0);
pub const __MINGW64_VERSION_BUGFIX = @as(c_int, 0);
pub const __MINGW64_VERSION_RC = @as(c_int, 0);
pub const __MINGW64_VERSION_STR = __MINGW64_STRINGIFY(__MINGW64_VERSION_MAJOR) ++ "." ++ __MINGW64_STRINGIFY(__MINGW64_VERSION_MINOR) ++ "." ++ __MINGW64_STRINGIFY(__MINGW64_VERSION_BUGFIX);
pub const __MINGW64_VERSION_STATE = "alpha";
pub const __MINGW32_MAJOR_VERSION = @as(c_int, 3);
pub const __MINGW32_MINOR_VERSION = @as(c_int, 11);
pub const _M_AMD64 = @as(c_int, 100);
pub const _M_X64 = @as(c_int, 100);
pub const @"_" = @as(c_int, 1);
pub const __MINGW_USE_UNDERSCORE_PREFIX = @as(c_int, 0);
pub const __MINGW_IMP_SYMBOL = @compileError("unable to translate macro: undefined identifier `__imp_`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw_mac.h:129:11
pub const __MINGW_IMP_LSYMBOL = @compileError("unable to translate macro: undefined identifier `__imp_`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw_mac.h:130:11
pub inline fn __MINGW_USYMBOL(sym: anytype) @TypeOf(sym) {
    _ = &sym;
    return sym;
}
pub inline fn __MINGW_LSYMBOL(sym: anytype) @TypeOf(__MINGW64_PASTE(@"_", sym)) {
    _ = &sym;
    return __MINGW64_PASTE(@"_", sym);
}
pub const __MINGW_ASM_CALL = @compileError("unable to translate C expr: unexpected token '__asm__'");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw_mac.h:140:9
pub const __MINGW_ASM_CRT_CALL = @compileError("unable to translate C expr: unexpected token '__asm__'");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw_mac.h:141:9
pub const __MINGW_EXTENSION = @compileError("unable to translate C expr: unexpected token '__extension__'");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw_mac.h:173:13
pub const __C89_NAMELESS = __MINGW_EXTENSION;
pub const __C89_NAMELESSSTRUCTNAME = "";
pub const __C89_NAMELESSSTRUCTNAME1 = "";
pub const __C89_NAMELESSSTRUCTNAME2 = "";
pub const __C89_NAMELESSSTRUCTNAME3 = "";
pub const __C89_NAMELESSSTRUCTNAME4 = "";
pub const __C89_NAMELESSSTRUCTNAME5 = "";
pub const __C89_NAMELESSUNIONNAME = "";
pub const __C89_NAMELESSUNIONNAME1 = "";
pub const __C89_NAMELESSUNIONNAME2 = "";
pub const __C89_NAMELESSUNIONNAME3 = "";
pub const __C89_NAMELESSUNIONNAME4 = "";
pub const __C89_NAMELESSUNIONNAME5 = "";
pub const __C89_NAMELESSUNIONNAME6 = "";
pub const __C89_NAMELESSUNIONNAME7 = "";
pub const __C89_NAMELESSUNIONNAME8 = "";
pub const __GNU_EXTENSION = __MINGW_EXTENSION;
pub const __MINGW_HAVE_ANSI_C99_PRINTF = @as(c_int, 1);
pub const __MINGW_HAVE_WIDE_C99_PRINTF = @as(c_int, 1);
pub const __MINGW_HAVE_ANSI_C99_SCANF = @as(c_int, 1);
pub const __MINGW_HAVE_WIDE_C99_SCANF = @as(c_int, 1);
pub const __MINGW_POISON_NAME = @compileError("unable to translate macro: undefined identifier `_layout_has_not_been_verified_and_its_declaration_is_most_likely_incorrect`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw_mac.h:213:11
pub const __MSABI_LONG = @import("std").zig.c_translation.Macros.L_SUFFIX;
pub const __MINGW_GCC_VERSION = ((__GNUC__ * @as(c_int, 10000)) + (__GNUC_MINOR__ * @as(c_int, 100))) + __GNUC_PATCHLEVEL__;
pub inline fn __MINGW_GNUC_PREREQ(major: anytype, minor: anytype) @TypeOf((__GNUC__ > major) or ((__GNUC__ == major) and (__GNUC_MINOR__ >= minor))) {
    _ = &major;
    _ = &minor;
    return (__GNUC__ > major) or ((__GNUC__ == major) and (__GNUC_MINOR__ >= minor));
}
pub inline fn __MINGW_MSC_PREREQ(major: anytype, minor: anytype) @TypeOf(@as(c_int, 0)) {
    _ = &major;
    _ = &minor;
    return @as(c_int, 0);
}
pub const __MINGW_ATTRIB_DEPRECATED_STR = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw_mac.h:257:11
pub const __MINGW_SEC_WARN_STR = "This function or variable may be unsafe, use _CRT_SECURE_NO_WARNINGS to disable deprecation";
pub const __MINGW_MSVC2005_DEPREC_STR = "This POSIX function is deprecated beginning in Visual C++ 2005, use _CRT_NONSTDC_NO_DEPRECATE to disable deprecation";
pub const __MINGW_ATTRIB_DEPRECATED_MSVC2005 = __MINGW_ATTRIB_DEPRECATED_STR(__MINGW_MSVC2005_DEPREC_STR);
pub const __MINGW_ATTRIB_DEPRECATED_SEC_WARN = __MINGW_ATTRIB_DEPRECATED_STR(__MINGW_SEC_WARN_STR);
pub const __MINGW_MS_PRINTF = @compileError("unable to translate macro: undefined identifier `__format__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw_mac.h:281:9
pub const __MINGW_MS_SCANF = @compileError("unable to translate macro: undefined identifier `__format__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw_mac.h:284:9
pub const __MINGW_GNU_PRINTF = @compileError("unable to translate macro: undefined identifier `__format__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw_mac.h:287:9
pub const __MINGW_GNU_SCANF = @compileError("unable to translate macro: undefined identifier `__format__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw_mac.h:290:9
pub const __mingw_ovr = @compileError("unable to translate macro: undefined identifier `__unused__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw_mac.h:311:11
pub const __mingw_attribute_artificial = @compileError("unable to translate macro: undefined identifier `__artificial__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw_mac.h:318:11
pub const __MINGW_SELECTANY = @compileError("unable to translate macro: undefined identifier `__selectany__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw_mac.h:324:9
pub const __MINGW_FORTIFY_LEVEL = @as(c_int, 0);
pub const __mingw_bos_ovr = __mingw_ovr;
pub const __MINGW_FORTIFY_VA_ARG = @as(c_int, 0);
pub const _INC_MINGW_SECAPI = "";
pub const _CRT_SECURE_CPP_OVERLOAD_SECURE_NAMES = @as(c_int, 0);
pub const _CRT_SECURE_CPP_OVERLOAD_SECURE_NAMES_MEMORY = @as(c_int, 0);
pub const _CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES = @as(c_int, 0);
pub const _CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES_COUNT = @as(c_int, 0);
pub const _CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES_MEMORY = @as(c_int, 0);
pub const __MINGW_CRT_NAME_CONCAT2 = @compileError("unable to translate macro: undefined identifier `_s`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw_secapi.h:41:9
pub const __CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES_MEMORY_0_3_ = @compileError("unable to translate C expr: unexpected token ';'");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw_secapi.h:69:9
pub const __LONG32 = c_long;
pub const __MINGW_IMPORT = @compileError("unable to translate macro: undefined identifier `__dllimport__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:44:12
pub const __USE_CRTIMP = @as(c_int, 1);
pub const _CRTIMP = @compileError("unable to translate macro: undefined identifier `__dllimport__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:52:15
pub const __DECLSPEC_SUPPORTED = "";
pub const USE___UUIDOF = @as(c_int, 0);
pub const _inline = @compileError("unable to translate C expr: unexpected token '__inline'");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:74:9
pub const __CRT_INLINE = @compileError("unable to translate macro: undefined identifier `__gnu_inline__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:83:11
pub const __MINGW_INTRIN_INLINE = @compileError("unable to translate macro: undefined identifier `__always_inline__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:90:9
pub const __CRT__NO_INLINE = @as(c_int, 1);
pub const __MINGW_CXX11_CONSTEXPR = "";
pub const __MINGW_CXX14_CONSTEXPR = "";
pub const __UNUSED_PARAM = @compileError("unable to translate macro: undefined identifier `__unused__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:118:11
pub const __restrict_arr = @compileError("unable to translate C expr: unexpected token '__restrict'");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:133:10
pub const __MINGW_ATTRIB_NORETURN = @compileError("unable to translate macro: undefined identifier `__noreturn__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:149:9
pub const __MINGW_ATTRIB_CONST = @compileError("unable to translate C expr: unexpected token '__attribute__'");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:150:9
pub const __MINGW_ATTRIB_MALLOC = @compileError("unable to translate macro: undefined identifier `__malloc__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:160:9
pub const __MINGW_ATTRIB_PURE = @compileError("unable to translate macro: undefined identifier `__pure__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:161:9
pub const __MINGW_ATTRIB_NONNULL = @compileError("unable to translate macro: undefined identifier `__nonnull__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:174:9
pub const __MINGW_ATTRIB_UNUSED = @compileError("unable to translate macro: undefined identifier `__unused__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:180:9
pub const __MINGW_ATTRIB_USED = @compileError("unable to translate macro: undefined identifier `__used__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:186:9
pub const __MINGW_ATTRIB_DEPRECATED = @compileError("unable to translate macro: undefined identifier `__deprecated__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:187:9
pub const __MINGW_ATTRIB_DEPRECATED_MSG = @compileError("unable to translate macro: undefined identifier `__deprecated__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:189:9
pub const __MINGW_NOTHROW = @compileError("unable to translate macro: undefined identifier `__nothrow__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:204:9
pub const __MINGW_ATTRIB_NO_OPTIMIZE = "";
pub const __MINGW_PRAGMA_PARAM = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:222:9
pub const __MINGW_BROKEN_INTERFACE = @compileError("unable to translate macro: undefined identifier `message`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:225:9
pub const _UCRT = "";
pub inline fn __MINGW_UCRT_ASM_CALL(func: anytype) @TypeOf(__MINGW_ASM_CALL(func)) {
    _ = &func;
    return __MINGW_ASM_CALL(func);
}
pub const _INT128_DEFINED = "";
pub const __int8 = u8;
pub const __int16 = c_short;
pub const __int32 = c_int;
pub const __int64 = c_longlong;
pub const __ptr32 = "";
pub const __ptr64 = "";
pub const __unaligned = "";
pub const __w64 = "";
pub const __forceinline = @compileError("unable to translate macro: undefined identifier `__always_inline__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:290:9
pub const __nothrow = "";
pub const _INC_VADEFS = "";
pub const MINGW_SDK_INIT = "";
pub const MINGW_HAS_SECURE_API = @as(c_int, 1);
pub const __STDC_SECURE_LIB__ = @as(c_long, 200411);
pub const __GOT_SECURE_LIB__ = __STDC_SECURE_LIB__;
pub const MINGW_DDK_H = "";
pub const MINGW_HAS_DDK_H = @as(c_int, 1);
pub const _CRT_PACKING = @as(c_int, 8);
pub const __GNUC_VA_LIST = "";
pub const _VA_LIST_DEFINED = "";
pub inline fn _ADDRESSOF(v: anytype) @TypeOf(&v) {
    _ = &v;
    return &v;
}
pub const _crt_va_start = @compileError("unable to translate macro: undefined identifier `__builtin_va_start`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/vadefs.h:48:9
pub const _crt_va_arg = @compileError("unable to translate C expr: unexpected token 'an identifier'");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/vadefs.h:49:9
pub const _crt_va_end = @compileError("unable to translate macro: undefined identifier `__builtin_va_end`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/vadefs.h:50:9
pub const _crt_va_copy = @compileError("unable to translate macro: undefined identifier `__builtin_va_copy`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/vadefs.h:51:9
pub const __CRT_STRINGIZE = @compileError("unable to translate C expr: unexpected token '#'");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:309:9
pub inline fn _CRT_STRINGIZE(_Value: anytype) @TypeOf(__CRT_STRINGIZE(_Value)) {
    _ = &_Value;
    return __CRT_STRINGIZE(_Value);
}
pub const __CRT_WIDE = @compileError("unable to translate macro: undefined identifier `L`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:314:9
pub inline fn _CRT_WIDE(_String: anytype) @TypeOf(__CRT_WIDE(_String)) {
    _ = &_String;
    return __CRT_WIDE(_String);
}
pub const _W64 = "";
pub const _CRTIMP_NOIA64 = _CRTIMP;
pub const _CRTIMP2 = _CRTIMP;
pub const _CRTIMP_ALTERNATIVE = _CRTIMP;
pub const _CRT_ALTERNATIVE_IMPORTED = "";
pub const _MRTIMP2 = _CRTIMP;
pub const _DLL = "";
pub const _MT = "";
pub const _MCRTIMP = _CRTIMP;
pub const _CRTIMP_PURE = _CRTIMP;
pub const _PGLOBAL = "";
pub const _AGLOBAL = "";
pub const _SECURECRT_FILL_BUFFER_PATTERN = @as(c_int, 0xFD);
pub const _CRT_DEPRECATE_TEXT = @compileError("unable to translate macro: undefined identifier `deprecated`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:373:9
pub const _CRT_INSECURE_DEPRECATE_MEMORY = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:376:9
pub const _CRT_INSECURE_DEPRECATE_GLOBALS = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:380:9
pub const _CRT_MANAGED_HEAP_DEPRECATE = "";
pub const _CRT_OBSOLETE = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:388:9
pub const _CONST_RETURN = "";
pub const UNALIGNED = "";
pub const _CRT_ALIGN = @compileError("unable to translate macro: undefined identifier `__aligned__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:415:9
pub const __CRTDECL = __cdecl;
pub const _ARGMAX = @as(c_int, 100);
pub const _TRUNCATE = @import("std").zig.c_translation.cast(usize, -@as(c_int, 1));
pub inline fn _CRT_UNUSED(x: anytype) anyopaque {
    _ = &x;
    return @import("std").zig.c_translation.cast(anyopaque, x);
}
pub const __USE_MINGW_ANSI_STDIO = @as(c_int, 0);
pub const _CRT_glob = @compileError("unable to translate macro: undefined identifier `_dowildcard`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:479:9
pub const __ANONYMOUS_DEFINED = "";
pub const _ANONYMOUS_UNION = __MINGW_EXTENSION;
pub const _ANONYMOUS_STRUCT = __MINGW_EXTENSION;
pub const _UNION_NAME = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:499:9
pub const _STRUCT_NAME = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:500:9
pub const DUMMYUNIONNAME = "";
pub const DUMMYUNIONNAME1 = "";
pub const DUMMYUNIONNAME2 = "";
pub const DUMMYUNIONNAME3 = "";
pub const DUMMYUNIONNAME4 = "";
pub const DUMMYUNIONNAME5 = "";
pub const DUMMYUNIONNAME6 = "";
pub const DUMMYUNIONNAME7 = "";
pub const DUMMYUNIONNAME8 = "";
pub const DUMMYUNIONNAME9 = "";
pub const DUMMYSTRUCTNAME = "";
pub const DUMMYSTRUCTNAME1 = "";
pub const DUMMYSTRUCTNAME2 = "";
pub const DUMMYSTRUCTNAME3 = "";
pub const DUMMYSTRUCTNAME4 = "";
pub const DUMMYSTRUCTNAME5 = "";
pub const __CRT_UUID_DECL = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:587:9
pub const __MINGW_DEBUGBREAK_IMPL = !(__has_builtin(__debugbreak) != 0);
pub const __MINGW_FASTFAIL_IMPL = !(__has_builtin(__fastfail) != 0);
pub const __MINGW_PREFETCH_IMPL = @compileError("unable to translate macro: undefined identifier `__prefetch`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/_mingw.h:644:9
pub const _CRTNOALIAS = "";
pub const _CRTRESTRICT = "";
pub const _SIZE_T_DEFINED = "";
pub const _SSIZE_T_DEFINED = "";
pub const _RSIZE_T_DEFINED = "";
pub const _INTPTR_T_DEFINED = "";
pub const __intptr_t_defined = "";
pub const _UINTPTR_T_DEFINED = "";
pub const __uintptr_t_defined = "";
pub const _PTRDIFF_T_DEFINED = "";
pub const _PTRDIFF_T_ = "";
pub const _WCHAR_T_DEFINED = "";
pub const _WCTYPE_T_DEFINED = "";
pub const _WINT_T = "";
pub const _ERRCODE_DEFINED = "";
pub const _TIME32_T_DEFINED = "";
pub const _TIME64_T_DEFINED = "";
pub const _TIME_T_DEFINED = "";
pub const _CRT_SECURE_CPP_NOTHROW = @compileError("unable to translate macro: undefined identifier `throw`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:143:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_0 = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:262:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_1 = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:263:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_2 = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:264:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_3 = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:265:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_4 = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:266:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_1_1 = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:267:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_1_2 = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:268:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_1_3 = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:269:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_2_0 = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:270:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_1_ARGLIST = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:271:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_2_ARGLIST = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:272:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_SPLITPATH = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:273:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_0 = @compileError("unable to translate macro: undefined identifier `__func_name`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:277:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_1 = @compileError("unable to translate macro: undefined identifier `__func_name`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:279:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_2 = @compileError("unable to translate macro: undefined identifier `__func_name`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:281:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_3 = @compileError("unable to translate macro: undefined identifier `__func_name`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:283:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_4 = @compileError("unable to translate macro: undefined identifier `__func_name`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:285:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_0_EX = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:422:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_1_EX = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:423:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_2_EX = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:424:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_3_EX = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:425:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_4_EX = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:426:9
pub const _TAGLC_ID_DEFINED = "";
pub const _THREADLOCALEINFO = "";
pub const __crt_typefix = @compileError("unable to translate C expr: unexpected token ''");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/corecrt.h:486:9
pub const _CRT_USE_WINAPI_FAMILY_DESKTOP_APP = "";
pub const _INC_CORECRT_WSTDLIB = "";
pub const __CLANG_LIMITS_H = "";
pub const _GCC_LIMITS_H_ = "";
pub const _INC_CRTDEFS = "";
pub const _INC_LIMITS = "";
pub const PATH_MAX = @as(c_int, 260);
pub const CHAR_BIT = @as(c_int, 8);
pub const SCHAR_MIN = -@as(c_int, 128);
pub const SCHAR_MAX = @as(c_int, 127);
pub const UCHAR_MAX = @as(c_int, 0xff);
pub const CHAR_MIN = SCHAR_MIN;
pub const CHAR_MAX = SCHAR_MAX;
pub const MB_LEN_MAX = @as(c_int, 5);
pub const SHRT_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 32768, .decimal);
pub const SHRT_MAX = @as(c_int, 32767);
pub const USHRT_MAX = @as(c_uint, 0xffff);
pub const INT_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const INT_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const UINT_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 0xffffffff, .hex);
pub const LONG_MIN = -@as(c_long, 2147483647) - @as(c_int, 1);
pub const LONG_MAX = @as(c_long, 2147483647);
pub const ULONG_MAX = @as(c_ulong, 0xffffffff);
pub const LLONG_MAX = @as(c_longlong, 9223372036854775807);
pub const LLONG_MIN = -@as(c_longlong, 9223372036854775807) - @as(c_int, 1);
pub const ULLONG_MAX = @as(c_ulonglong, 0xffffffffffffffff);
pub const _I8_MIN = -@as(c_int, 127) - @as(c_int, 1);
pub const _I8_MAX = @as(c_int, 127);
pub const _UI8_MAX = @as(c_uint, 0xff);
pub const _I16_MIN = -@as(c_int, 32767) - @as(c_int, 1);
pub const _I16_MAX = @as(c_int, 32767);
pub const _UI16_MAX = @as(c_uint, 0xffff);
pub const _I32_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const _I32_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const _UI32_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 0xffffffff, .hex);
pub const LONG_LONG_MAX = @as(c_longlong, 9223372036854775807);
pub const LONG_LONG_MIN = -LONG_LONG_MAX - @as(c_int, 1);
pub const ULONG_LONG_MAX = (@as(c_ulonglong, 2) * LONG_LONG_MAX) + @as(c_ulonglong, 1);
pub const _I64_MIN = -@as(c_longlong, 9223372036854775807) - @as(c_int, 1);
pub const _I64_MAX = @as(c_longlong, 9223372036854775807);
pub const _UI64_MAX = @as(c_ulonglong, 0xffffffffffffffff);
pub const SIZE_MAX = _UI64_MAX;
pub const SSIZE_MAX = _I64_MAX;
pub const _SECIMP = @compileError("unable to translate macro: undefined identifier `dllimport`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/stdlib.h:22:9
pub const NULL = @import("std").zig.c_translation.cast(?*anyopaque, @as(c_int, 0));
pub const EXIT_SUCCESS = @as(c_int, 0);
pub const EXIT_FAILURE = @as(c_int, 1);
pub const _ONEXIT_T_DEFINED = "";
pub const onexit_t = _onexit_t;
pub const _DIV_T_DEFINED = "";
pub const _CRT_DOUBLE_DEC = "";
pub inline fn _PTR_LD(x: anytype) [*c]u8 {
    _ = &x;
    return @import("std").zig.c_translation.cast([*c]u8, &x.*.ld);
}
pub const RAND_MAX = @as(c_int, 0x7fff);
pub const MB_CUR_MAX = ___mb_cur_max_func();
pub const __mb_cur_max = ___mb_cur_max_func();
pub inline fn __max(a: anytype, b: anytype) @TypeOf(if (a > b) a else b) {
    _ = &a;
    _ = &b;
    return if (a > b) a else b;
}
pub inline fn __min(a: anytype, b: anytype) @TypeOf(if (a < b) a else b) {
    _ = &a;
    _ = &b;
    return if (a < b) a else b;
}
pub const _MAX_PATH = @as(c_int, 260);
pub const _MAX_DRIVE = @as(c_int, 3);
pub const _MAX_DIR = @as(c_int, 256);
pub const _MAX_FNAME = @as(c_int, 256);
pub const _MAX_EXT = @as(c_int, 256);
pub const _OUT_TO_DEFAULT = @as(c_int, 0);
pub const _OUT_TO_STDERR = @as(c_int, 1);
pub const _OUT_TO_MSGBOX = @as(c_int, 2);
pub const _REPORT_ERRMODE = @as(c_int, 3);
pub const _WRITE_ABORT_MSG = @as(c_int, 0x1);
pub const _CALL_REPORTFAULT = @as(c_int, 0x2);
pub const _MAX_ENV = @as(c_int, 32767);
pub const _CRT_ERRNO_DEFINED = "";
pub const errno = _errno().*;
pub const _doserrno = __doserrno().*;
pub const _sys_nerr = __sys_nerr().*;
pub const _sys_errlist = __sys_errlist();
pub const _fmode = __p__fmode().*;
pub const __argc = __p___argc().*;
pub const __argv = __p___argv().*;
pub const __wargv = __p___wargv().*;
pub const _pgmptr = __p__pgmptr().*;
pub const _wpgmptr = __p__wpgmptr().*;
pub const _environ = __p__environ().*;
pub const _wenviron = __p__wenviron().*;
pub const _osplatform = __p__osplatform().*;
pub const _osver = __p__osver().*;
pub const _winver = __p__winver().*;
pub const _winmajor = __p__winmajor().*;
pub const _winminor = __p__winminor().*;
pub const _countof = @compileError("unable to translate C expr: expected ')' instead got '['");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/stdlib.h:263:9
pub const _CRT_TERMINATE_DEFINED = "";
pub const _CRT_ABS_DEFINED = "";
pub const _CRT_ATOF_DEFINED = "";
pub const _CRT_ALGO_DEFINED = "";
pub const _CRT_SYSTEM_DEFINED = "";
pub const _CRT_ALLOCATION_DEFINED = "";
pub const _WSTDLIB_DEFINED = "";
pub const _CRT_WSYSTEM_DEFINED = "";
pub const _CVTBUFSIZE = @as(c_int, 309) + @as(c_int, 40);
pub const _CRT_PERROR_DEFINED = "";
pub const _WSTDLIBP_DEFINED = "";
pub const _CRT_WPERROR_DEFINED = "";
pub const sys_errlist = _sys_errlist;
pub const sys_nerr = _sys_nerr;
pub const environ = _environ;
pub const _CRT_SWAB_DEFINED = "";
pub const _INC_STDLIB_S = "";
pub const _QSORT_S_DEFINED = "";
pub const _MALLOC_H_ = "";
pub const _HEAP_MAXREQ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xFFFFFFFFFFFFFFE0, .hex);
pub const _STATIC_ASSERT = @compileError("unable to translate C expr: unexpected token '_Static_assert'");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/malloc.h:29:9
pub const _HEAPEMPTY = -@as(c_int, 1);
pub const _HEAPOK = -@as(c_int, 2);
pub const _HEAPBADBEGIN = -@as(c_int, 3);
pub const _HEAPBADNODE = -@as(c_int, 4);
pub const _HEAPEND = -@as(c_int, 5);
pub const _HEAPBADPTR = -@as(c_int, 6);
pub const _FREEENTRY = @as(c_int, 0);
pub const _USEDENTRY = @as(c_int, 1);
pub const _HEAPINFO_DEFINED = "";
pub const _amblksiz = __p__amblksiz().*;
pub const __MM_MALLOC_H = "";
pub const _MAX_WAIT_MALLOC_CRT = @import("std").zig.c_translation.promoteIntLiteral(c_int, 60000, .decimal);
pub const _alloca = @compileError("unable to translate macro: undefined identifier `__builtin_alloca`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/malloc.h:163:9
pub const _ALLOCA_S_THRESHOLD = @as(c_int, 1024);
pub const _ALLOCA_S_STACK_MARKER = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xCCCC, .hex);
pub const _ALLOCA_S_HEAP_MARKER = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xDDDD, .hex);
pub const _ALLOCA_S_MARKER_SIZE = @as(c_int, 16);
pub inline fn _malloca(size: anytype) @TypeOf(if ((size + _ALLOCA_S_MARKER_SIZE) <= _ALLOCA_S_THRESHOLD) _MarkAllocaS(_alloca(size + _ALLOCA_S_MARKER_SIZE), _ALLOCA_S_STACK_MARKER) else _MarkAllocaS(malloc(size + _ALLOCA_S_MARKER_SIZE), _ALLOCA_S_HEAP_MARKER)) {
    _ = &size;
    return if ((size + _ALLOCA_S_MARKER_SIZE) <= _ALLOCA_S_THRESHOLD) _MarkAllocaS(_alloca(size + _ALLOCA_S_MARKER_SIZE), _ALLOCA_S_STACK_MARKER) else _MarkAllocaS(malloc(size + _ALLOCA_S_MARKER_SIZE), _ALLOCA_S_HEAP_MARKER);
}
pub const _FREEA_INLINE = "";
pub const alloca = @compileError("unable to translate macro: undefined identifier `__builtin_alloca`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/malloc.h:238:9
pub const _INC_STDIO = "";
pub const _STDIO_CONFIG_DEFINED = "";
pub const _CRT_INTERNAL_PRINTF_LEGACY_VSPRINTF_NULL_TERMINATION = @as(c_ulonglong, 0x0001);
pub const _CRT_INTERNAL_PRINTF_STANDARD_SNPRINTF_BEHAVIOR = @as(c_ulonglong, 0x0002);
pub const _CRT_INTERNAL_PRINTF_LEGACY_WIDE_SPECIFIERS = @as(c_ulonglong, 0x0004);
pub const _CRT_INTERNAL_PRINTF_LEGACY_MSVCRT_COMPATIBILITY = @as(c_ulonglong, 0x0008);
pub const _CRT_INTERNAL_PRINTF_LEGACY_THREE_DIGIT_EXPONENTS = @as(c_ulonglong, 0x0010);
pub const _CRT_INTERNAL_PRINTF_STANDARD_ROUNDING = @as(c_ulonglong, 0x0020);
pub const _CRT_INTERNAL_SCANF_SECURECRT = @as(c_ulonglong, 0x0001);
pub const _CRT_INTERNAL_SCANF_LEGACY_WIDE_SPECIFIERS = @as(c_ulonglong, 0x0002);
pub const _CRT_INTERNAL_SCANF_LEGACY_MSVCRT_COMPATIBILITY = @as(c_ulonglong, 0x0004);
pub const _CRT_INTERNAL_LOCAL_PRINTF_OPTIONS = __local_stdio_printf_options().*;
pub const _CRT_INTERNAL_LOCAL_SCANF_OPTIONS = __local_stdio_scanf_options().*;
pub const BUFSIZ = @as(c_int, 512);
pub const _NFILE = _NSTREAM_;
pub const _NSTREAM_ = @as(c_int, 512);
pub const _IOB_ENTRIES = @as(c_int, 20);
pub const EOF = -@as(c_int, 1);
pub const _FILE_DEFINED = "";
pub const _P_tmpdir = "\\";
pub const _wP_tmpdir = "\\";
pub const L_tmpnam = @as(c_int, 260);
pub const SEEK_CUR = @as(c_int, 1);
pub const SEEK_END = @as(c_int, 2);
pub const SEEK_SET = @as(c_int, 0);
pub const STDIN_FILENO = @as(c_int, 0);
pub const STDOUT_FILENO = @as(c_int, 1);
pub const STDERR_FILENO = @as(c_int, 2);
pub const FILENAME_MAX = @as(c_int, 260);
pub const FOPEN_MAX = @as(c_int, 20);
pub const _SYS_OPEN = @as(c_int, 20);
pub const TMP_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const _OFF_T_DEFINED = "";
pub const _OFF_T_ = "";
pub const _OFF64_T_DEFINED = "";
pub const _FILE_OFFSET_BITS_SET_OFFT = "";
pub const _iob = __iob_func();
pub const _FPOS_T_DEFINED = "";
pub inline fn _FPOSOFF(fp: anytype) c_long {
    _ = &fp;
    return @import("std").zig.c_translation.cast(c_long, fp);
}
pub const _STDSTREAM_DEFINED = "";
pub const stdin = __acrt_iob_func(@as(c_int, 0));
pub const stdout = __acrt_iob_func(@as(c_int, 1));
pub const stderr = __acrt_iob_func(@as(c_int, 2));
pub const _IOFBF = @as(c_int, 0x0000);
pub const _IOLBF = @as(c_int, 0x0040);
pub const _IONBF = @as(c_int, 0x0004);
pub const __MINGW_PRINTF_FORMAT = @compileError("unable to translate macro: undefined identifier `__printf__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/stdio.h:277:9
pub const __MINGW_SCANF_FORMAT = @compileError("unable to translate macro: undefined identifier `__scanf__`");
// C:\Tools\zig\zig15\lib\libc\include\any-windows-any/stdio.h:278:9
pub const _FILE_OFFSET_BITS_SET_FSEEKO = "";
pub const _FILE_OFFSET_BITS_SET_FTELLO = "";
pub const popen = _popen;
pub const pclose = _pclose;
pub const _CRT_DIRECTORY_DEFINED = "";
pub const _WSTDIO_DEFINED = "";
pub const WEOF = @import("std").zig.c_translation.cast(wint_t, @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xFFFF, .hex));
pub const _INC_SWPRINTF_INL = "";
pub const wpopen = _wpopen;
pub inline fn _putwc_nolock(_c: anytype, _stm: anytype) @TypeOf(_fputwc_nolock(_c, _stm)) {
    _ = &_c;
    _ = &_stm;
    return _fputwc_nolock(_c, _stm);
}
pub inline fn _getwc_nolock(_c: anytype) @TypeOf(_fgetwc_nolock(_c)) {
    _ = &_c;
    return _fgetwc_nolock(_c);
}
pub const _STDIO_DEFINED = "";
pub inline fn _getchar_nolock() @TypeOf(_getc_nolock(stdin)) {
    return _getc_nolock(stdin);
}
pub inline fn _putchar_nolock(_c: anytype) @TypeOf(_putc_nolock(_c, stdout)) {
    _ = &_c;
    return _putc_nolock(_c, stdout);
}
pub inline fn _getwchar_nolock() @TypeOf(_getwc_nolock(stdin)) {
    return _getwc_nolock(stdin);
}
pub inline fn _putwchar_nolock(_c: anytype) @TypeOf(_putwc_nolock(_c, stdout)) {
    _ = &_c;
    return _putwc_nolock(_c, stdout);
}
pub const P_tmpdir = _P_tmpdir;
pub const SYS_OPEN = _SYS_OPEN;
pub const __MINGW_MBWC_CONVERT_DEFINED = "";
pub const _WSPAWN_DEFINED = "";
pub const _P_WAIT = @as(c_int, 0);
pub const _P_NOWAIT = @as(c_int, 1);
pub const _OLD_P_OVERLAY = @as(c_int, 2);
pub const _P_NOWAITO = @as(c_int, 3);
pub const _P_DETACH = @as(c_int, 4);
pub const _P_OVERLAY = @as(c_int, 2);
pub const _WAIT_CHILD = @as(c_int, 0);
pub const _WAIT_GRANDCHILD = @as(c_int, 1);
pub const _SPAWNV_DEFINED = "";
pub const _INC_STDIO_S = "";
pub const _STDIO_S_DEFINED = "";
pub const L_tmpnam_s = L_tmpnam;
pub const TMP_MAX_S = TMP_MAX;
pub const _WSTDIO_S_DEFINED = "";
pub const _INC_STRING = "";
pub const _NLSCMP_DEFINED = "";
pub const _NLSCMPERROR = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const _WConst_return = "";
pub const _CRT_MEMORY_DEFINED = "";
pub const _WSTRING_DEFINED = "";
pub const wcswcs = wcsstr;
pub const _INC_STRING_S = "";
pub const _WSTRING_S_DEFINED = "";
pub inline fn YAML_DECLARE(@"type": anytype) @TypeOf(@"type") {
    _ = &@"type";
    return @"type";
}
pub const YAML_NULL_TAG = "tag:yaml.org,2002:null";
pub const YAML_BOOL_TAG = "tag:yaml.org,2002:bool";
pub const YAML_STR_TAG = "tag:yaml.org,2002:str";
pub const YAML_INT_TAG = "tag:yaml.org,2002:int";
pub const YAML_FLOAT_TAG = "tag:yaml.org,2002:float";
pub const YAML_TIMESTAMP_TAG = "tag:yaml.org,2002:timestamp";
pub const YAML_SEQ_TAG = "tag:yaml.org,2002:seq";
pub const YAML_MAP_TAG = "tag:yaml.org,2002:map";
pub const YAML_DEFAULT_SCALAR_TAG = YAML_STR_TAG;
pub const YAML_DEFAULT_SEQUENCE_TAG = YAML_SEQ_TAG;
pub const YAML_DEFAULT_MAPPING_TAG = YAML_MAP_TAG;
pub const threadlocaleinfostruct = struct_threadlocaleinfostruct;
pub const threadmbcinfostruct = struct_threadmbcinfostruct;
pub const __lc_time_data = struct___lc_time_data;
pub const localeinfo_struct = struct_localeinfo_struct;
pub const tagLC_ID = struct_tagLC_ID;
pub const _div_t = struct__div_t;
pub const _ldiv_t = struct__ldiv_t;
pub const _heapinfo = struct__heapinfo;
pub const _iobuf = struct__iobuf;
pub const yaml_version_directive_s = struct_yaml_version_directive_s;
pub const yaml_tag_directive_s = struct_yaml_tag_directive_s;
pub const yaml_encoding_e = enum_yaml_encoding_e;
pub const yaml_break_e = enum_yaml_break_e;
pub const yaml_error_type_e = enum_yaml_error_type_e;
pub const yaml_mark_s = struct_yaml_mark_s;
pub const yaml_scalar_style_e = enum_yaml_scalar_style_e;
pub const yaml_sequence_style_e = enum_yaml_sequence_style_e;
pub const yaml_mapping_style_e = enum_yaml_mapping_style_e;
pub const yaml_token_type_e = enum_yaml_token_type_e;
pub const yaml_token_s = struct_yaml_token_s;
pub const yaml_event_type_e = enum_yaml_event_type_e;
pub const yaml_event_s = struct_yaml_event_s;
pub const yaml_node_type_e = enum_yaml_node_type_e;
pub const yaml_node_pair_s = struct_yaml_node_pair_s;
pub const yaml_node_s = struct_yaml_node_s;
pub const yaml_document_s = struct_yaml_document_s;
pub const yaml_simple_key_s = struct_yaml_simple_key_s;
pub const yaml_parser_state_e = enum_yaml_parser_state_e;
pub const yaml_alias_data_s = struct_yaml_alias_data_s;
pub const yaml_parser_s = struct_yaml_parser_s;
pub const yaml_emitter_state_e = enum_yaml_emitter_state_e;
pub const yaml_anchors_s = struct_yaml_anchors_s;
pub const yaml_emitter_s = struct_yaml_emitter_s;
