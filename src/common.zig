const std = @import("std");

pub const keywords: []const []const u8 = &.{
    "SHOW",
    "OF",
    "GUID",
    "WHERE",
    "IN",
};

pub const tags: []const []const u8 = &.{
    "refs",
    "uses",
};

pub fn isKeyword(str: []const u8) bool {
    for (keywords) |kw| {
        if (std.mem.eql(u8, str, kw)) {
            return true;
        }
    }
    return false;
}

pub fn isTag(str: []const u8) bool {
    for (tags) |tag| {
        if (std.mem.eql(u8, str, tag)) {
            return true;
        }
    }
    return false;
}

pub fn isWhitespace(char: u8) bool {
    return char == ' ' or char == '\n' or char == '\t';
}
