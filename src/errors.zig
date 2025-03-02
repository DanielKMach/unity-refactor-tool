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
            expected: Tokenizer.Token,
            found: Tokenizer.Token,
        },
        unexpected_token_type: struct {
            expected: Tokenizer.TokenType,
            found: Tokenizer.Token,
        },
    });
}

pub const CompilerErrorType = enum {
    unknown_command,
    never_closed_string,
    unexpected_token,
    unexpected_token_type,
};

pub fn RuntimeError(T: type) type {
    return RichError(T, union(RuntimeErrorType) {
        invalid_asset: struct {
            path: []const u8,
        },
    });
}

pub const RuntimeErrorType = enum {
    invalid_asset,
};
