const Tokenizer = @import("Tokenizer.zig");

pub fn RichError(T: type, E: type) type {
    return union(RichErrorType) {
        const This = @This();

        ok: T,
        err: E,

        pub fn ok(okv: T) This {
            return .{ .ok = okv };
        }

        pub fn err(errv: E) This {
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

pub const RichErrorType = enum {
    ok,
    err,
};

pub fn CompilerError(T: type) type {
    return RichError(T, union(CompilerErrorType) {
        unknown_command: void,
        never_closed_string: struct {
            index: usize,
        },
        unexpected_token: struct {
            expected_type: Tokenizer.TokenType,
            expected_value: ?[]const u8 = null,
            found: Tokenizer.Token,
        },
        unexpected_eof: struct {
            expected_type: Tokenizer.TokenType,
            expected_value: ?[]const u8 = null,
        },
    });
}

pub const CompilerErrorType = enum {
    unknown_command,
    never_closed_string,
    unexpected_token,
    unexpected_eof,
};

pub fn RuntimeError(T: type) type {
    return RichError(T, union(RuntimeErrorType) {
        invalid_asset: struct {
            path: []const u8,
        },
        invalid_path: struct {
            path: []const u8,
        },
    });
}

pub const RuntimeErrorType = enum {
    invalid_asset,
    invalid_path,
};
