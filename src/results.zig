const std = @import("std");
const core = @import("root");

const Tokenizer = core.language.Tokenizer;

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

pub const ParseErrorType = enum {
    unknown,
    never_closed_string,
    unexpected_token,
    unexpected_eof,
};

pub const ParseError = union(ParseErrorType) {
    unknown: void,
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
};

pub fn ParseResult(T: type) type {
    return Result(T, ParseError);
}

pub const RuntimeErrorType = enum {
    invalid_asset,
    invalid_path,
};

pub const RuntimeError = union(RuntimeErrorType) {
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

pub fn printParseError(out: std.io.AnyWriter, errUnion: ParseError, command: []const u8) !void {
    try out.print("Compiler error: ", .{});
    switch (errUnion) {
        .never_closed_string => |err| {
            try out.print("Never closed string at index {d}\r\n", .{err.index});
            try printLineHighlightRange(out, command, err.index, err.index);
        },
        .unexpected_token => |err| {
            if (err.expected_value) |expected_value| {
                try out.print("Unexpected token: Expected {s} '{s}', found {s} '{s}'\r\n", .{
                    @tagName(err.expected_type),
                    expected_value,
                    @tagName(err.found.type),
                    err.found.value,
                });
            } else {
                try out.print("Unexpected token type: Expected a {s}, found {s} '{s}'\r\n", .{
                    @tagName(err.expected_type),
                    @tagName(err.found.type),
                    err.found.value,
                });
            }
            try printLineHighlight(out, command, err.found.value);
        },
        .unexpected_eof => |err| {
            if (err.expected_value) |expected_value| {
                try out.print("Unexpected end of file: Expected {s} '{s}'\r\n", .{
                    @tagName(err.expected_type),
                    expected_value,
                });
            } else {
                try out.print("Unexpected end of file: Expected a {s}\r\n", .{
                    @tagName(err.expected_type),
                });
            }
        },
        .unknown => {
            try out.print("Unknown statement\r\n", .{});
        },
    }
}

pub fn printRuntimeError(out: std.io.AnyWriter, errUnion: RuntimeError) !void {
    std.debug.print("Runtime error: ", .{});
    switch (errUnion) {
        .invalid_asset => |err| {
            try out.print("Invalid asset path '{s}'\r\n", .{err.path});
        },
        .invalid_path => |err| {
            try out.print("Invalid path '{s}'\r\n", .{err.path});
        },
    }
}

/// Shows a line with a highlight.
/// Asserts that `highlight` is a slice of `line`.
pub fn printLineHighlight(out: std.io.AnyWriter, line: []const u8, highlight: []const u8) !void {
    const zero = @intFromPtr(line.ptr);
    const start = @intFromPtr(highlight.ptr) - zero;
    const end = start + highlight.len - 1;

    std.debug.assert(end >= start);
    std.debug.assert(start < line.len);
    std.debug.assert(end < line.len);

    try printLineHighlightRange(out, line, start, end);
}

pub fn printLineHighlightRange(out: std.io.AnyWriter, line: []const u8, start: usize, end: usize) !void {
    std.debug.assert(start <= end);
    std.debug.assert(start < line.len);
    std.debug.assert(end < line.len);

    try out.print("{s}\r\n", .{line});

    for (0..start) |_| {
        try out.print(" ", .{});
    }

    for (start..end + 1) |_| {
        try out.print("~", .{});
    }

    try out.print("\r\n", .{});
}
