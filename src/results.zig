const std = @import("std");
const core = @import("core");

const Token = core.language.Token;

pub const ResultType = enum {
    ok,
    err,
};

pub fn Result(T: type, E: type) type {
    return union(ResultType) {
        const This = @This();

        ok: T,
        err: E,

        pub fn OK(okv: T) This {
            return .{ .ok = okv };
        }

        pub fn ERR(errv: E) This {
            return .{ .err = errv };
        }

        pub fn isOk(self: This) ?T {
            return if (self == .ok) self.ok else null;
        }

        pub fn isErr(self: This) ?E {
            return if (self == .err) self.err else null;
        }
    };
}

pub const ParseErrorType = @typeInfo(ParseError).@"union".tag_type orelse unreachable;

pub const ParseError = union(enum) {
    // Syntax related errors
    never_closed_string: struct {
        index: usize,
    },
    unexpected_character: struct {
        character: *const u8,
    },
    invalid_number: struct {
        slice: []const u8,
    },

    // Token related errors
    unexpected_token: struct {
        expected: []const Token.Type,
        found: Token,
    },
    invalid_guid: struct {
        token: Token,
        guid: []const u8,
    },
    invalid_csharp_identifier: struct {
        token: Token,
        identifier: []const u8,
    },

    // Clause related errors
    duplicate_clause: struct {
        clause: []const u8,
        first: Token,
        second: Token,
    },
    missing_clause: struct {
        clause: []const u8,
        placement: Token,
    },

    // Generic errors
    multiple: []const ParseError,
    unknown: void,
};

pub fn ParseResult(T: type) type {
    return Result(T, ParseError);
}

pub const RuntimeErrorType = @typeInfo(RuntimeError).@"union".tag_type orelse unreachable;

pub const RuntimeError = union(enum) {
    invalid_asset: struct {
        path: []const u8,
    },
    invalid_path: struct {
        path: []const u8,
    },
};

pub fn RuntimeResult(T: type) type {
    return Result(T, RuntimeError);
}

pub fn USRLError(T: type) type {
    return Result(T, union(enum) {
        runtime: RuntimeError,
        parsing: ParseError,
    });
}
