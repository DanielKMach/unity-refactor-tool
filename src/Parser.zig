const std = @import("std");
const Tokenizer = @import("Tokenizer.zig");

pub const USRL = std.mem.TokenIterator(u8, .scalar);
const This = @This();

allocator: std.mem.Allocator,

pub fn parse(self: *This, tokens: Tokenizer.TokenIterator) !void {
    _ = self.allocator;
    for (tokens) |tkn| {
        std.debug.print("{s} => '{s}'\r\n", .{ @tagName(tkn.type), tkn.value });
    }
}
