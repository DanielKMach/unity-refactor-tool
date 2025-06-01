const std = @import("std");
pub usingnamespace std.ascii;

pub const Tokenizer = @import("language/Tokenizer.zig");
pub const Parser = @import("language/Parser.zig");

pub const keywords: []const []const u8 = &.{
    "SHOW",
    "RENAME",
    "FOR",
    "EVALUATE",

    "OF",
    "IN",
    "WHERE",

    "GUID",
};

pub const operators: []const u8 = &.{
    ',',
    '.',
};

pub fn isKeyword(str: []const u8) bool {
    for (keywords) |kw| {
        if (std.mem.eql(u8, str, kw)) {
            return true;
        }
    }
    return false;
}

pub fn isOperator(char: u8) bool {
    for (operators) |tag| {
        if (char == tag) {
            return true;
        }
    }
    return false;
}
