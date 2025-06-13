const std = @import("std");
const core = @import("root");

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

pub const ParseErrorType = enum {
    unknown,
    never_closed_string,
    unexpected_token,
    unexpected_eof,
    unexpected_character,
    invalid_guid,
    invalid_csharp_identifier,
    invalid_number,
    multiple,
};

pub const ParseError = union(ParseErrorType) {
    unknown: void,
    never_closed_string: struct {
        index: usize,
    },
    unexpected_token: struct {
        expected: []const Token.Type,
        found: Token,
    },
    unexpected_eof: struct {
        expected: []const Token.Type,
    },
    unexpected_character: struct {
        character: *const u8,
    },
    invalid_guid: struct {
        token: Token,
        guid: []const u8,
    },
    invalid_csharp_identifier: struct {
        token: Token,
        identifier: []const u8,
    },
    invalid_number: struct {
        slice: []const u8,
    },
    multiple: []const ParseError,
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
        .unknown => {
            try out.print("Unknown statement\r\n", .{});
        },
        .never_closed_string => |err| {
            try out.print("Never closed string at index {d}\r\n", .{err.index});
            try printLineHighlightRange(out, command, err.index, err.index);
        },
        .unexpected_token => |err| {
            try out.print("Unexpected token: Found {s}", .{@tagName(err.found.value)});
            if (err.expected.len > 0) try out.print(", but expected ", .{});
            for (err.expected, 0..) |expected_type, i| {
                if (i > 0 and i != err.expected.len - 1) try out.print(", ", .{});
                if (i != 0 and i == err.expected.len - 1) try out.print(" or ", .{});
                try out.print("{s}", .{@tagName(expected_type)});
            }
            try out.print("\r\n", .{});
            try printLineHighlight(out, command, err.found.lexeme);
        },
        .unexpected_eof => |err| {
            try out.print("Unexpected end of file.", .{});
            if (err.expected.len > 0) try out.print(" Expected ", .{});
            for (err.expected, 0..) |expected_type, i| {
                if (i > 0 and i != err.expected.len - 1) try out.print(", ", .{});
                if (i != 0 and i == err.expected.len - 1) try out.print(" or ", .{});
                try out.print("{s}", .{@tagName(expected_type)});
            }
            try out.print("\r\n", .{});
        },
        .unexpected_character => |err| {
            try out.print("Unexpected character: '{s}'\r\n", .{err.character});
            try printLineHighlight(out, command, err.character[0..1]);
        },
        .invalid_csharp_identifier => |err| {
            try out.print("Invalid C# identifier: '{s}'\r\n", .{err.identifier});
            try printLineHighlight(out, command, err.token.lexeme);
        },
        .invalid_guid => |err| {
            try out.print("Invalid GUID: '{s}'\r\n", .{err.guid});
            try printLineHighlight(out, command, err.token.lexeme);
        },
        .invalid_number => |err| {
            try out.print("Invalid number: '{s}'\r\n", .{err.slice});
            try printLineHighlight(out, command, err.slice);
        },
        .multiple => |errs| {
            for (errs) |err| {
                try printParseError(out, err, command);
            }
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
    const offset = @intFromPtr(highlight.ptr) - zero;
    const len = if (highlight.len == 0) 1 else highlight.len;

    try printLineHighlightRange(out, line, offset, len);
}

pub fn printLineHighlightRange(out: std.io.AnyWriter, line: []const u8, offset: usize, size: usize) !void {
    try out.print("{s}\r\n", .{line});

    for (0..offset) |_| {
        try out.print(" ", .{});
    }

    for (0..size) |_| {
        try out.print("~", .{});
    }

    try out.print("\r\n", .{});
}
